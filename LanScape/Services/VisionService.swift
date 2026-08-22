import Foundation
import AVFoundation
import Vision
import Combine
import ImageIO

final class VisionService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var poseModel = PoseModel()
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    nonisolated private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                self.captureSession.sessionPreset = .hd1920x1080
            } else {
                self.captureSession.sessionPreset = .high
            }
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(videoInput)
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoBufferQueue", qos: .userInteractive))
            }
            
            self.captureSession.commitConfiguration()
            self.startSession()
        }
    }
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Front camera in portrait requires .leftMirrored so Vision processes the user upright and mirrored
        let orientation: CGImagePropertyOrientation = .leftMirrored
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            
            guard let observations = bodyPoseRequest.results else {
                DispatchQueue.main.async { [weak self] in
                    self?.poseModel = PoseModel(detectedPeople: [], videoSize: CGSize(width: 1080, height: 1920))
                }
                return
            }
            
            var people: [DetectedPerson] = []
            
            for (index, observation) in observations.enumerated() {
                if index >= 2 { break }
                
                let recognizedPoints = try observation.recognizedPoints(.all)
                var jointDict: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
                var jointList: [JointPoint] = []
                
                for (jointName, point) in recognizedPoints where point.confidence > 0.1 {
                    // Convert Vision bottom-left origin to SwiftUI top-left origin
                    let mappedPoint = CGPoint(x: point.location.x, y: 1.0 - point.location.y)
                    jointDict[jointName] = mappedPoint
                    jointList.append(JointPoint(name: jointName, location: mappedPoint, confidence: point.confidence))
                }
                
                if jointDict[.root] == nil, let leftHip = jointDict[.leftHip], let rightHip = jointDict[.rightHip] {
                    jointDict[.root] = CGPoint(x: (leftHip.x + rightHip.x) / 2.0, y: (leftHip.y + rightHip.y) / 2.0)
                }
                if jointDict[.neck] == nil, let leftShoulder = jointDict[.leftShoulder], let rightShoulder = jointDict[.rightShoulder] {
                    jointDict[.neck] = CGPoint(x: (leftShoulder.x + rightShoulder.x) / 2.0, y: (leftShoulder.y + rightShoulder.y) / 2.0)
                }
                
                people.append(DetectedPerson(personIndex: index, joints: jointDict, jointList: jointList))
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.poseModel = PoseModel(detectedPeople: people, videoSize: CGSize(width: 1080, height: 1920))
            }
        } catch {
            print("Vision request error: \(error.localizedDescription)")
        }
    }
}
