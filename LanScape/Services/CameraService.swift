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

    // MARK: - Published State
    @Published var isCameraRunning: Bool = false
    @Published var permissionGranted: Bool = false

    // MARK: - Capture Session
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    private let videoBufferQueue = DispatchQueue(label: "cameraVideoBufferQueue", qos: .userInteractive)

    private var isConfigured = false
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    // Efficient persistent CIContext (reused, never reallocated per frame)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var latestPixelBuffer: CVPixelBuffer?
    private let bufferLock = NSLock()
    
    var onPixelBufferAvailable: ((CVPixelBuffer) -> Void)?

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

            // Add Front Camera
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: frontCamera),
                  self.captureSession.canAddInput(videoInput) else {
                print("⚠️ FRONT camera not available (simulator or restricted)")
                self.captureSession.commitConfiguration()
                self.isConfigured = true
                return
            }

            self.captureSession.addInput(videoInput)

            // Add Video Output for frame capture
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoBufferQueue)

                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .landscapeLeft
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
                if let photoConnection = self.photoOutput.connection(with: .video) {
                    if photoConnection.isVideoOrientationSupported {
                        photoConnection.videoOrientation = .landscapeLeft
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

            // Fallback immediately if session is not running (e.g. Simulator)
            guard self.captureSession.isRunning else {
                let frame = self.renderLatestFrame()
                DispatchQueue.main.async { completion(frame) }
                return
            }

            // If photoOutput connection is available and active, capture high-res photo
            if let connection = self.photoOutput.connection(with: .video), connection.isActive {
                self.photoCaptureCompletion = completion
                let settings = AVCapturePhotoSettings()
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            } else {
                // Instant fallback from latest video buffer frame
                let frame = self.renderLatestFrame()
                DispatchQueue.main.async {
                    completion(frame)
                }
            }
        }
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var resultImage: UIImage? = nil

        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            resultImage = image
        } else {
            resultImage = renderLatestFrame()
        }

        let completion = photoCaptureCompletion
        photoCaptureCompletion = nil

        DispatchQueue.main.async {
            completion?(resultImage)
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
