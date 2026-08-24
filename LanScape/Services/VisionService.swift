import Foundation
import AVFoundation
import Vision
import Combine
import ImageIO
import UIKit
import CoreML

final class VisionService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var poseModel = PoseModel()
    
    // Model Predictions & Match State
    @Published var targetPose: String = "1"
    @Published var prediction: String = "?"
    @Published var confidence: Double = 0.0
    @Published var isMatching: Bool = false
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    nonisolated private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private var model: MLModel?
    private let confidenceThreshold: Double = 0.35
    
    override init() {
        super.init()
        loadModel(name: "1")
        checkCameraPermission()
    }
    
    func loadModel(name: String = "1") {
        if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            do {
                model = try MLModel(contentsOf: url)
                print("Successfully loaded model: \(name).mlmodelc")
            } catch {
                print("Failed to load model \(name).mlmodelc:", error)
            }
        } else if let url = Bundle.main.url(forResource: name, withExtension: "mlmodel") {
            do {
                let compiledUrl = try MLModel.compileModel(at: url)
                model = try MLModel(contentsOf: compiledUrl)
                print("Successfully compiled and loaded model: \(name).mlmodel")
            } catch {
                print("Failed to compile and load model \(name).mlmodel:", error)
            }
        } else {
            print("Model '\(name)' not found in Bundle.")
        }
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
    
    private func currentOrientationAndSize() -> (CGImagePropertyOrientation, CGSize) {
        let interfaceOrientation: UIInterfaceOrientation
        if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            interfaceOrientation = windowScene.interfaceOrientation
        } else {
            interfaceOrientation = .portrait
        }
        
        switch interfaceOrientation {
        case .landscapeLeft:
            return (.downMirrored, CGSize(width: 1920, height: 1080))
        case .landscapeRight:
            return (.upMirrored, CGSize(width: 1920, height: 1080))
        case .portraitUpsideDown:
            return (.rightMirrored, CGSize(width: 1080, height: 1920))
        case .portrait:
            return (.leftMirrored, CGSize(width: 1080, height: 1920))
        default:
            return (.leftMirrored, CGSize(width: 1080, height: 1920))
        }
    }
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let (orientation, videoSize) = currentOrientationAndSize()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            
            guard let observations = bodyPoseRequest.results, !observations.isEmpty else {
                DispatchQueue.main.async { [weak self] in
                    self?.poseModel = PoseModel(detectedPeople: [], videoSize: videoSize)
                    self?.prediction = "?"
                    self?.confidence = 0.0
                    self?.isMatching = false
                }
                return
            }
            
            var rawPeople: [(joints: [VNHumanBodyPoseObservation.JointName: CGPoint], jointList: [JointPoint], avgX: CGFloat)] = []
            
            for observation in observations.prefix(2) {
                let recognizedPoints = try observation.recognizedPoints(.all)
                var jointDict: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
                var jointList: [JointPoint] = []
                var sumX: CGFloat = 0
                var countX: CGFloat = 0
                
                for (jointName, point) in recognizedPoints where point.confidence > 0.1 {
                    let mappedPoint = CGPoint(x: point.location.x, y: 1.0 - point.location.y)
                    jointDict[jointName] = mappedPoint
                    jointList.append(JointPoint(name: jointName, location: mappedPoint, confidence: point.confidence))
                    sumX += mappedPoint.x
                    countX += 1
                }
                
                if jointDict[.root] == nil, let leftHip = jointDict[.leftHip], let rightHip = jointDict[.rightHip] {
                    jointDict[.root] = CGPoint(x: (leftHip.x + rightHip.x) / 2.0, y: (leftHip.y + rightHip.y) / 2.0)
                }
                if jointDict[.neck] == nil, let leftShoulder = jointDict[.leftShoulder], let rightShoulder = jointDict[.rightShoulder] {
                    jointDict[.neck] = CGPoint(x: (leftShoulder.x + rightShoulder.x) / 2.0, y: (leftShoulder.y + rightShoulder.y) / 2.0)
                }
                
                let avgX = countX > 0 ? (sumX / countX) : 0.5
                rawPeople.append((joints: jointDict, jointList: jointList, avgX: avgX))
            }
            
            // Run prediction if model is loaded
            if let firstObs = observations.first, model != nil {
                predict(observation: firstObs)
            }
            
            // Sort left-to-right on screen so Player 1 is Left and Player 2 is Right
            rawPeople.sort { $0.avgX < $1.avgX }
            
            var people: [DetectedPerson] = []
            for (index, personData) in rawPeople.enumerated() {
                people.append(DetectedPerson(personIndex: index, joints: personData.joints, jointList: personData.jointList))
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.poseModel = PoseModel(detectedPeople: people, videoSize: videoSize)
            }
        } catch {
            print("Vision request error: \(error.localizedDescription)")
        }
    }
    
    private let pointKeys: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .neck,
        .leftEye, .rightEye,
        .leftEar, .rightEar,
        .leftShoulder, .rightShoulder,
        .leftElbow, .rightElbow,
        .leftWrist, .rightWrist,
        .leftHip, .rightHip,
        .leftKnee, .rightKnee,
        .leftAnkle, .rightAnkle
    ]
    
    private func makeFeatures(from observation: VNHumanBodyPoseObservation) -> [String: MLFeatureValue] {
        var dict: [String: MLFeatureValue] = [:]
        
        for key in pointKeys {
            let baseName = featureBaseName(for: key)
            if let point = try? observation.recognizedPoint(key), point.confidence > 0.1 {
                dict["\(baseName)_x"] = MLFeatureValue(double: Double(point.location.x))
                dict["\(baseName)_y"] = MLFeatureValue(double: Double(point.location.y))
                dict["\(baseName)_confidence"] = MLFeatureValue(double: Double(point.confidence))
            } else {
                dict["\(baseName)_x"] = MLFeatureValue(double: 0)
                dict["\(baseName)_y"] = MLFeatureValue(double: 0)
                dict["\(baseName)_confidence"] = MLFeatureValue(double: 0)
            }
        }
        return dict
    }
    
    private func featureBaseName(for key: VNHumanBodyPoseObservation.JointName) -> String {
        key.rawValue.rawValue.replacingOccurrences(of: ".", with: "_")
    }
    
    private func predict(observation: VNHumanBodyPoseObservation) {
        guard let model = model else { return }
        
        let features = makeFeatures(from: observation)
        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: features)
            let output = try model.prediction(from: provider)
            
            let predictionText = readPredictedLabel(from: output) ?? "?"
            let conf = readConfidence(for: predictionText, from: output) ?? 0.0
            
            // Check if prediction matches target pose
            let matches = (predictionText.lowercased() == targetPose.lowercased() && conf >= confidenceThreshold)
            
            DispatchQueue.main.async { [weak self] in
                self?.prediction = predictionText
                self?.confidence = conf
                self?.isMatching = matches
            }
        } catch {
            // Model might require multi-array input or different dictionary format
        }
    }
    
    private func readPredictedLabel(from output: MLFeatureProvider) -> String? {
        let possibleNames = ["label", "classLabel", "target", "Label"]
        for name in possibleNames {
            if let value = output.featureValue(for: name)?.stringValue {
                return value
            }
        }
        for name in output.featureNames {
            if let value = output.featureValue(for: name)?.stringValue {
                return value
            }
        }
        return nil
    }
    
    private func readConfidence(for label: String?, from output: MLFeatureProvider) -> Double? {
        guard let label = label else { return nil }
        for name in output.featureNames {
            if let dict = output.featureValue(for: name)?.dictionaryValue {
                for (key, value) in dict {
                    if String(describing: key) == label {
                        return value.doubleValue
                    }
                }
            }
        }
        return nil
    }
}
