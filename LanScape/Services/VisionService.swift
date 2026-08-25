import Foundation
import AVFoundation
import Vision
import Combine
import ImageIO
import UIKit
import CoreML

final class VisionService:
    NSObject,
    ObservableObject,
    AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: - Published State

    @Published var poseModel = PoseModel()

    @Published var targetPose: String = "1"

    @Published var prediction: String = "?"

    @Published var confidence: Double = 0.0

    @Published var isMatching: Bool = false

    // MARK: - Debug State

    @Published var debugRawLabel: String = ""

    @Published var debugProbabilities: String = ""

    @Published var debugBestProbability: String = ""

    @Published var debugInputCount: String = ""

    @Published var debugStatus: String = "Waiting"

    // MARK: - Camera

    let captureSession = AVCaptureSession()

    private let videoOutput =
        AVCaptureVideoDataOutput()

    private let sessionQueue =
        DispatchQueue(
            label: "cameraSessionQueue"
        )

    // MARK: - Vision

    nonisolated private let bodyPoseRequest =
        VNDetectHumanBodyPoseRequest()

    // MARK: - Core ML

    private var model: MLModel?

    private let confidenceThreshold:
        Double = 0.35

    // MARK: - Init

    override init() {

        super.init()

        loadModel(
            name: "DancePose1"
        )

        checkCameraPermission()
    }

    // MARK: - Load Model

    func loadModel(
        name: String = "DancePose1"
    ) {

        if let url =
            Bundle.main.url(
                forResource: name,
                withExtension: "mlmodelc"
            ) {

            do {

                model =
                    try MLModel(
                        contentsOf: url
                    )

                print("")
                print("==============================")
                print("CORE ML MODEL LOADED")
                print("==============================")

                printModelInformation()

                DispatchQueue.main.async {
                    self.debugStatus =
                        "Model loaded"
                }

            } catch {

                print(
                    "❌ Failed to load model:",
                    error
                )

                DispatchQueue.main.async {
                    self.debugStatus =
                        "Model load error"
                }
            }

        } else if let url =
            Bundle.main.url(
                forResource: name,
                withExtension: "mlmodel"
            ) {

            do {

                let compiledURL =
                    try MLModel.compileModel(
                        at: url
                    )

                model =
                    try MLModel(
                        contentsOf: compiledURL
                    )

                print("")
                print("==============================")
                print("CORE ML MODEL COMPILED")
                print("==============================")

                printModelInformation()

                DispatchQueue.main.async {
                    self.debugStatus =
                        "Model compiled"
                }

            } catch {

                print(
                    "❌ Failed to compile model:",
                    error
                )

                DispatchQueue.main.async {
                    self.debugStatus =
                        "Model compile error"
                }
            }

        } else {

            print(
                "❌ Model '\(name)' not found in Bundle."
            )

            DispatchQueue.main.async {
                self.debugStatus =
                    "Model not found"
            }
        }
    }

    // MARK: - Model Information

    private func printModelInformation() {

        guard let model else {
            return
        }

        print("")
        print("MODEL INPUTS:")

        for (
            name,
            description
        ) in model
            .modelDescription
            .inputDescriptionsByName
            .sorted(
                by: {
                    $0.key < $1.key
                }
            ) {

            print(
                "INPUT:",
                name
            )

            print(
                "TYPE:",
                description.type
            )
        }

        print("")
        print("MODEL OUTPUTS:")

        for (
            name,
            description
        ) in model
            .modelDescription
            .outputDescriptionsByName
            .sorted(
                by: {
                    $0.key < $1.key
                }
            ) {

            print(
                "OUTPUT:",
                name
            )

            print(
                "TYPE:",
                description.type
            )
        }

        print("")
        print("==============================")
        print("")
    }

    // MARK: - Start Session

    func startSession() {

        sessionQueue.async { [weak self] in

            guard
                let self,
                !self.captureSession.isRunning
            else {
                return
            }

            self.captureSession.startRunning()

            DispatchQueue.main.async {
                self.debugStatus =
                    "Camera running"
            }
        }
    }

    // MARK: - Stop Session

    func stopSession() {

        sessionQueue.async { [weak self] in

            guard
                let self,
                self.captureSession.isRunning
            else {
                return
            }

            self.captureSession.stopRunning()

            DispatchQueue.main.async {
                self.debugStatus =
                    "Camera stopped"
            }
        }
    }

    // MARK: - Camera Permission

    private func checkCameraPermission() {

        switch AVCaptureDevice.authorizationStatus(
            for: .video
        ) {

        case .authorized:

            setupSession()

        case .notDetermined:

            AVCaptureDevice.requestAccess(
                for: .video
            ) { [weak self] granted in

                if granted {
                    self?.setupSession()
                }
            }

        case .denied:

            print(
                "❌ Camera permission denied"
            )

            DispatchQueue.main.async {
                self.debugStatus =
                    "Camera permission denied"
            }

        case .restricted:

            print(
                "❌ Camera restricted"
            )

            DispatchQueue.main.async {
                self.debugStatus =
                    "Camera restricted"
            }

        @unknown default:

            break
        }
    }

    // MARK: - Setup Camera

    private func setupSession() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            self.captureSession.beginConfiguration()

            if self.captureSession.canSetSessionPreset(
                .hd1920x1080
            ) {

                self.captureSession.sessionPreset =
                    .hd1920x1080

            } else {

                self.captureSession.sessionPreset =
                    .high
            }

            // BACK CAMERA

            guard
                let videoDevice =
                    AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .back
                    ),

                let videoInput =
                    try? AVCaptureDeviceInput(
                        device: videoDevice
                    ),

                self.captureSession.canAddInput(
                    videoInput
                )
            else {

                print(
                    "❌ Could not configure back camera"
                )

                self.captureSession.commitConfiguration()

                return
            }

            self.captureSession.addInput(
                videoInput
            )

            if self.captureSession.canAddOutput(
                self.videoOutput
            ) {

                self.captureSession.addOutput(
                    self.videoOutput
                )

                self.videoOutput
                    .alwaysDiscardsLateVideoFrames =
                    true

                self.videoOutput
                    .setSampleBufferDelegate(
                        self,
                        queue:
                            DispatchQueue(
                                label:
                                    "videoBufferQueue",
                                qos:
                                    .userInteractive
                            )
                    )
            }

            self.captureSession.commitConfiguration()

            self.startSession()
        }
    }

    // MARK: - Orientation

    private func currentOrientationAndSize()
        -> (
            CGImagePropertyOrientation,
            CGSize
        ) {

        let interfaceOrientation:
            UIInterfaceOrientation

        if let windowScene =
            UIApplication.shared
                .connectedScenes
                .compactMap({
                    $0 as? UIWindowScene
                })
                .first(
                    where: {
                        $0.activationState ==
                            .foregroundActive
                    }
                )
            ??
            UIApplication.shared
                .connectedScenes
                .compactMap({
                    $0 as? UIWindowScene
                })
                .first {

            interfaceOrientation =
                windowScene.interfaceOrientation

        } else {

            interfaceOrientation =
                .portrait
        }

        switch interfaceOrientation {

        case .landscapeLeft:

            return (
                .up,
                CGSize(
                    width: 1920,
                    height: 1080
                )
            )

        case .landscapeRight:

            return (
                .down,
                CGSize(
                    width: 1920,
                    height: 1080
                )
            )

        case .portraitUpsideDown:

            return (
                .left,
                CGSize(
                    width: 1080,
                    height: 1920
                )
            )

        case .portrait:

            return (
                .right,
                CGSize(
                    width: 1080,
                    height: 1920
                )
            )

        default:

            return (
                .right,
                CGSize(
                    width: 1080,
                    height: 1920
                )
            )
        }
    }

    // MARK: - Capture Output

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard
            let pixelBuffer =
                CMSampleBufferGetImageBuffer(
                    sampleBuffer
                )
        else {
            return
        }

        let (
            orientation,
            videoSize
        ) =
            currentOrientationAndSize()

        let handler =
            VNImageRequestHandler(
                cvPixelBuffer:
                    pixelBuffer,
                orientation:
                    orientation,
                options: [:]
            )

        do {

            try handler.perform(
                [bodyPoseRequest]
            )

            guard
                let observations =
                    bodyPoseRequest.results,
                !observations.isEmpty
            else {

                DispatchQueue.main.async { [weak self] in

                    self?.poseModel =
                        PoseModel(
                            detectedPeople: [],
                            videoSize:
                                videoSize
                        )

                    self?.prediction =
                        "?"

                    self?.confidence =
                        0.0

                    self?.isMatching =
                        false

                    self?.debugStatus =
                        "No person detected"
                }

                return
            }

            // MARK: People

            var rawPeople: [
                (
                    joints:
                        [
                            VNHumanBodyPoseObservation
                                .JointName: CGPoint
                        ],

                    jointList:
                        [JointPoint],

                    avgX:
                        CGFloat
                )
            ] = []

            for observation
                in observations.prefix(2) {

                let recognizedPoints =
                    try observation.recognizedPoints(
                        .all
                    )

                var jointDict: [
                    VNHumanBodyPoseObservation
                        .JointName: CGPoint
                ] = [:]

                var jointList:
                    [JointPoint] = []

                var sumX:
                    CGFloat = 0

                var countX:
                    CGFloat = 0

                for (
                    jointName,
                    point
                ) in recognizedPoints
                where point.confidence > 0.1 {

                    let mappedPoint =
                        CGPoint(
                            x:
                                point.location.x,
                            y:
                                1.0 -
                                point.location.y
                        )

                    jointDict[
                        jointName
                    ] =
                        mappedPoint

                    jointList.append(
                        JointPoint(
                            name:
                                jointName,
                            location:
                                mappedPoint,
                            confidence:
                                point.confidence
                        )
                    )

                    sumX +=
                        mappedPoint.x

                    countX += 1
                }

                if jointDict[.root] == nil,

                   let leftHip =
                    jointDict[.leftHip],

                   let rightHip =
                    jointDict[.rightHip] {

                    jointDict[.root] =
                        CGPoint(
                            x:
                                (
                                    leftHip.x +
                                    rightHip.x
                                ) / 2.0,

                            y:
                                (
                                    leftHip.y +
                                    rightHip.y
                                ) / 2.0
                        )
                }

                if jointDict[.neck] == nil,

                   let leftShoulder =
                    jointDict[.leftShoulder],

                   let rightShoulder =
                    jointDict[.rightShoulder] {

                    jointDict[.neck] =
                        CGPoint(
                            x:
                                (
                                    leftShoulder.x +
                                    rightShoulder.x
                                ) / 2.0,

                            y:
                                (
                                    leftShoulder.y +
                                    rightShoulder.y
                                ) / 2.0
                        )
                }

                let avgX =
                    countX > 0
                    ? sumX / countX
                    : 0.5

                rawPeople.append(
                    (
                        joints:
                            jointDict,

                        jointList:
                            jointList,

                        avgX:
                            avgX
                    )
                )
            }

            // MARK: Predict

            if let firstObservation =
                observations.first {

                predict(
                    observation:
                        firstObservation
                )
            }

            rawPeople.sort {
                $0.avgX <
                    $1.avgX
            }

            var people:
                [DetectedPerson] = []

            for (
                index,
                personData
            ) in rawPeople.enumerated() {

                people.append(
                    DetectedPerson(
                        personIndex:
                            index,

                        joints:
                            personData.joints,

                        jointList:
                            personData.jointList
                    )
                )
            }

            DispatchQueue.main.async { [weak self] in

                self?.poseModel =
                    PoseModel(
                        detectedPeople:
                            people,

                        videoSize:
                            videoSize
                    )
            }

        } catch {

            print(
                "Vision error:",
                error.localizedDescription
            )

            DispatchQueue.main.async { [weak self] in
                self?.debugStatus =
                    "Vision error"
            }
        }
    }

    // MARK: - Make Features

    private func makeFeatures(
        from observation:
            VNHumanBodyPoseObservation
    ) -> [
        String: MLFeatureValue
    ] {

        typealias Joint =
            VNHumanBodyPoseObservation
                .JointName

        let jointMap: [
            String: Joint
        ] = [

            "head_joint":
                .nose,

            "left_eye_joint":
                .leftEye,

            "right_eye_joint":
                .rightEye,

            "left_ear_joint":
                .leftEar,

            "right_ear_joint":
                .rightEar,

            "left_shoulder_1_joint":
                .leftShoulder,

            "right_shoulder_1_joint":
                .rightShoulder,

            "left_forearm_joint":
                .leftElbow,

            "right_forearm_joint":
                .rightElbow,

            "left_hand_joint":
                .leftWrist,

            "right_hand_joint":
                .rightWrist,

            "left_upLeg_joint":
                .leftHip,

            "right_upLeg_joint":
                .rightHip,

            "left_leg_joint":
                .leftKnee,

            "right_leg_joint":
                .rightKnee,

            "left_foot_joint":
                .leftAnkle,

            "right_foot_joint":
                .rightAnkle
        ]

        var features: [
            String: MLFeatureValue
        ] = [:]

        guard let model else {
            return features
        }

        let inputs =
            model
                .modelDescription
                .inputDescriptionsByName

        for featureName
            in inputs.keys {

            let prefix =
                "VNRecognizedPointKey(_rawValue: "

            guard
                featureName.hasPrefix(
                    prefix
                )
            else {
                continue
            }

            guard
                let prefixRange =
                    featureName.range(
                        of:
                            prefix
                    )
            else {
                continue
            }

            let remainder =
                featureName[
                    prefixRange.upperBound...
                ]

            guard
                let closing =
                    remainder.firstIndex(
                        of: ")"
                    )
            else {
                continue
            }

            let jointName =
                String(
                    remainder[
                        remainder.startIndex..<closing
                    ]
                )

            guard
                let joint =
                    jointMap[jointName]
            else {
                continue
            }

            let value: Double

            if let point =
                try? observation.recognizedPoint(
                    joint
                ),
               point.confidence > 0.1 {

                if featureName.hasSuffix(
                    "_x"
                ) {

                    value =
                        Double(
                            point.location.x
                        )

                } else if featureName.hasSuffix(
                    "_y"
                ) {

                    value =
                        Double(
                            point.location.y
                        )

                } else {

                    continue
                }

            } else {

                value = 0.0
            }

            features[
                featureName
            ] =
                MLFeatureValue(
                    double:
                        value
                )
        }

        return features
    }

    // MARK: - Prediction

    private func predict(
        observation:
            VNHumanBodyPoseObservation
    ) {

        guard let model else {

            DispatchQueue.main.async {
                self.debugStatus =
                    "Model unavailable"
            }

            return
        }

        let features =
            makeFeatures(
                from:
                    observation
            )

        let expectedCount =
            model
                .modelDescription
                .inputDescriptionsByName
                .count

        let actualCount =
            features.count

        DispatchQueue.main.async { [weak self] in

            self?.debugInputCount =
                "\(actualCount) / \(expectedCount)"
        }

        guard
            actualCount ==
                expectedCount
        else {

            DispatchQueue.main.async { [weak self] in

                self?.prediction =
                    "Input error"

                self?.confidence =
                    0.0

                self?.isMatching =
                    false

                self?.debugStatus =
                    "Input count mismatch"
            }

            return
        }

        do {

            let provider =
                try MLDictionaryFeatureProvider(
                    dictionary:
                        features
                )

            let output =
                try model.prediction(
                    from:
                        provider
                )

            // MARK: Raw Label

            let rawLabel =
                output
                    .featureValue(
                        for:
                            "label"
                    )?
                    .stringValue
                    ?? ""

            // MARK: Probability Dictionary

            guard
                let probabilityFeature =
                    output.featureValue(
                        for:
                            "labelProbability"
                    )
            else {

                DispatchQueue.main.async { [weak self] in

                    self?.prediction =
                        "No probability"

                    self?.confidence =
                        0.0

                    self?.debugStatus =
                        "labelProbability missing"
                }

                return
            }

            // dictionaryValue is already:
            // [AnyHashable: NSNumber]

            let dictionary =
                probabilityFeature
                    .dictionaryValue

            var probabilities:
                [
                    String: Double
                ] = [:]

            for (
                key,
                value
            ) in dictionary {

                let keyString =
                    String(
                        describing:
                            key
                    )

                probabilities[
                    keyString
                ] =
                    value.doubleValue
            }

            // MARK: Highest Probability

            guard
                let best =
                    probabilities.max(
                        by: {
                            $0.value <
                                $1.value
                        }
                    )
            else {

                DispatchQueue.main.async { [weak self] in

                    self?.prediction =
                        "No prediction"

                    self?.confidence =
                        0.0

                    self?.debugStatus =
                        "Empty probabilities"
                }

                return
            }

            let predictedLabel =
                best.key

            let predictedConfidence =
                best.value

            // MARK: Matching

            let matches =
                predictedLabel
                    .lowercased()
                    ==
                targetPose
                    .lowercased()
                &&
                predictedConfidence >=
                    confidenceThreshold

            // MARK: Debug String

            let probabilityText =
                probabilities
                    .sorted {
                        $0.key <
                            $1.key
                    }
                    .map {
                        "\($0.key): " +
                        String(
                            format:
                                "%.4f",
                            $0.value
                        )
                    }
                    .joined(
                        separator:
                            "\n"
                    )

            let bestText =
                String(
                    format:
                        "Label %@ = %.6f (%.2f%%)",
                    predictedLabel,
                    predictedConfidence,
                    predictedConfidence * 100
                )

            // MARK: Console Debug

            print("")
            print("==============================")
            print("CORE ML DEBUG")
            print("==============================")

            print(
                "RAW LABEL:",
                rawLabel
            )

            print(
                "PROBABILITIES:"
            )

            for (
                label,
                probability
            ) in probabilities {

                print(
                    "  \(label):",
                    probability,
                    "(",
                    probability * 100,
                    "%)"
                )
            }

            print(
                "SELECTED LABEL:",
                predictedLabel
            )

            print(
                "SELECTED PROBABILITY:",
                predictedConfidence
            )

            print(
                "PERCENT:",
                predictedConfidence * 100
            )

            print(
                "TARGET:",
                targetPose
            )

            print(
                "THRESHOLD:",
                confidenceThreshold
            )

            print(
                "MATCH:",
                matches
            )

            print("==============================")
            print("")

            // MARK: Publish

            DispatchQueue.main.async { [weak self] in

                guard let self else {
                    return
                }

                self.prediction =
                    "Label \(predictedLabel)"

                self.confidence =
                    predictedConfidence

                self.isMatching =
                    matches

                self.debugRawLabel =
                    rawLabel.isEmpty
                    ? "(empty)"
                    : rawLabel

                self.debugProbabilities =
                    probabilityText

                self.debugBestProbability =
                    bestText

                self.debugStatus =
                    "Prediction OK"
            }

        } catch {

            print("")
            print("==============================")
            print("CORE ML ERROR")
            print("==============================")

            print(
                error
            )

            print(
                error.localizedDescription
            )

            print("==============================")
            print("")

            DispatchQueue.main.async { [weak self] in

                self?.prediction =
                    "Prediction error"

                self?.confidence =
                    0.0

                self?.isMatching =
                    false

                self?.debugStatus =
                    "Core ML error"
            }
        }
    }
}
