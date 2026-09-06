//
//  CameraService.swift
//  LanScape
//

import Foundation
import AVFoundation
import UIKit
import Combine
import CoreImage

final class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    static let shared = CameraService()

    // MARK: - Published State
    @Published var isCameraRunning: Bool = false
    @Published var permissionGranted: Bool = false

    // MARK: - Capture Session
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    private let videoBufferQueue = DispatchQueue(label: "cameraVideoBufferQueue", qos: .userInteractive)
    private let renderQueue = DispatchQueue(label: "cameraRenderQueue", qos: .userInteractive)

    private var isConfigured = false
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    // Efficient persistent CIContext (initialized lazily to avoid blocking UI during launch)
    private lazy var ciContext: CIContext = CIContext(options: [.useSoftwareRenderer: false])
    private var latestPixelBuffer: CVPixelBuffer?
    private let bufferLock = NSLock()
    
    var onPixelBufferAvailable: ((CVPixelBuffer) -> Void)?

    func warmUp() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured {
                self.setupSession()
            } else if !self.captureSession.isRunning {
                self.startSession()
            }
        }
        renderQueue.async { [weak self] in
            _ = self?.ciContext
        }
    }

    // MARK: - Init
    override init() {
        super.init()
        checkCameraPermission()
    }

    // MARK: - Permissions
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
                if granted {
                    self?.setupSession()
                }
            }
        default:
            permissionGranted = false
        }
    }

    // MARK: - Session Setup
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isConfigured else { return }

            self.captureSession.beginConfiguration()

            if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                self.captureSession.sessionPreset = .hd1920x1080
            } else {
                self.captureSession.sessionPreset = .high
            }

            // Remove existing inputs
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }

            // Configure Front Camera hardware for maximum clarity and auto-adjustments
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: frontCamera),
                  self.captureSession.canAddInput(videoInput) else {
                print("⚠️ FRONT camera not available (simulator or restricted)")
                self.captureSession.commitConfiguration()
                self.isConfigured = true
                return
            }

            do {
                try frontCamera.lockForConfiguration()
                if frontCamera.isFocusModeSupported(.continuousAutoFocus) {
                    frontCamera.focusMode = .continuousAutoFocus
                }
                if frontCamera.isExposureModeSupported(.continuousAutoExposure) {
                    frontCamera.exposureMode = .continuousAutoExposure
                }
                if frontCamera.isLowLightBoostSupported {
                    frontCamera.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                frontCamera.unlockForConfiguration()
            } catch {
                print("⚠️ Front camera hardware configuration note: \(error)")
            }

            self.captureSession.addInput(videoInput)

            let initialOrientation = self.resolveActiveOrientation()

            // Add Video Output for frame capture
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoBufferQueue)

                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = initialOrientation
                    }
                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = true
                    }
                }
            }

            // Add Photo Output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.photoOutput.maxPhotoQualityPrioritization = .balanced
                
                if let photoConnection = self.photoOutput.connection(with: .video) {
                    if photoConnection.isVideoOrientationSupported {
                        photoConnection.videoOrientation = initialOrientation
                    }
                    if photoConnection.isVideoMirroringSupported {
                        photoConnection.automaticallyAdjustsVideoMirroring = false
                        photoConnection.isVideoMirrored = true
                    }
                }
            }

            self.captureSession.commitConfiguration()
            self.isConfigured = true
            self.startSession()
        }
    }

    // MARK: - Active Orientation Resolver
    func resolveActiveOrientation() -> AVCaptureVideoOrientation {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                switch windowScene.interfaceOrientation {
                case .landscapeRight:
                    return .landscapeRight
                case .landscapeLeft:
                    return .landscapeLeft
                case .portrait:
                    return .portrait
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                default:
                    break
                }
            }
        }

        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .landscapeLeft
        }
    }

    // MARK: - Session Controls
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isCameraRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isCameraRunning = false
            }
        }
    }

    // MARK: - Orientation Sync
    func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if let connection = self.videoOutput.connection(with: .video),
               connection.isVideoOrientationSupported,
               connection.videoOrientation != orientation {
                connection.videoOrientation = orientation
            }

            if let photoConnection = self.photoOutput.connection(with: .video),
               photoConnection.isVideoOrientationSupported,
               photoConnection.videoOrientation != orientation {
                photoConnection.videoOrientation = orientation
            }
        }
    }

    // MARK: - Capture Photo (Async)
    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            capturePhoto { image in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Capture Photo (Completion)
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // If session is running and photo output is active, capture high-quality photo
            if self.captureSession.isRunning,
               let connection = self.photoOutput.connection(with: .video),
               connection.isActive {
                self.photoCaptureCompletion = completion
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .balanced
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            } else {
                // Fallback from video buffer rendered on background queue
                self.renderQueue.async { [weak self] in
                    let frame = self?.renderLatestFrame()
                    DispatchQueue.main.async {
                        completion(frame)
                    }
                }
            }
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Decode and render image on background renderQueue
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            var resultImage: UIImage? = nil

            if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                // Normalize orientation so all subsequent processing and rendering is 100% upright
                resultImage = image.normalizedUp()
            } else {
                resultImage = self.renderLatestFrame()
            }

            let completion = self.photoCaptureCompletion
            self.photoCaptureCompletion = nil

            DispatchQueue.main.async {
                completion?(resultImage)
            }
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        bufferLock.lock()
        self.latestPixelBuffer = pixelBuffer
        bufferLock.unlock()
        
        onPixelBufferAvailable?(pixelBuffer)
    }

    // Only render to UIImage on demand (not on every 60fps frame)
    private func renderLatestFrame() -> UIImage? {
        bufferLock.lock()
        guard let pixelBuffer = latestPixelBuffer else {
            bufferLock.unlock()
            return nil
        }
        bufferLock.unlock()

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        }
        return nil
    }
}
