import Foundation
import AVFoundation
import Vision
import Combine
import ImageIO
import UIKit

// MARK: - Vision Service

final class VisionService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    // =========================================================
    // MARK: - Joint Smoothing
    // =========================================================

    private var smoothedJointPositions:
        [String: CGPoint] = [:]

    private let smoothingFactor: CGFloat = 0.20


    // =========================================================
    // MARK: - Published State
    // =========================================================

    @Published var poseModel = PoseModel()

    @Published var debugStatus: String = "Waiting"

    @Published var detectedPlayerCount: Int = 0


    // =========================================================
    // MARK: - Camera
    // =========================================================

    let captureSession = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(
        label: "cameraSessionQueue"
    )

    private let videoBufferQueue = DispatchQueue(
        label: "videoBufferQueue",
        qos: .userInteractive
    )


    // =========================================================
    // MARK: - Vision
    // =========================================================

    private let bodyPoseRequest =
        VNDetectHumanBodyPoseRequest()


    // =========================================================
    // MARK: - State
    // =========================================================

    private var isConfigured = false


    // =========================================================
    // MARK: - Init
    // =========================================================

    override init() {

        super.init()

        checkCameraPermission()
    }


    // =========================================================
    // MARK: - Start Session
    // =========================================================

    func startSession() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard !self.captureSession.isRunning else {
                return
            }

            self.captureSession.startRunning()

            DispatchQueue.main.async {

                self.debugStatus =
                    "Camera running"
            }
        }
    }


    // =========================================================
    // MARK: - Stop Session
    // =========================================================

    func stopSession() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard self.captureSession.isRunning else {
                return
            }

            self.captureSession.stopRunning()

            DispatchQueue.main.async {

                self.debugStatus =
                    "Camera stopped"
            }
        }
    }


    // =========================================================
    // MARK: - Camera Permission
    // =========================================================

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

            DispatchQueue.main.async {

                self.debugStatus =
                    "Camera permission denied"
            }


        case .restricted:

            DispatchQueue.main.async {

                self.debugStatus =
                    "Camera restricted"
            }


        @unknown default:

            break
        }
    }


    // =========================================================
    // MARK: - Setup Camera
    // =========================================================

    private func setupSession() {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            guard !self.isConfigured else {
                return
            }

            self.captureSession.beginConfiguration()


            // -------------------------------------------------
            // Session Preset
            // -------------------------------------------------

            if self.captureSession.canSetSessionPreset(
                .hd1920x1080
            ) {

                self.captureSession.sessionPreset =
                    .hd1920x1080

            } else {

                self.captureSession.sessionPreset =
                    .high
            }


            // -------------------------------------------------
            // Remove Existing Inputs
            // -------------------------------------------------

            for input in self.captureSession.inputs {

                self.captureSession.removeInput(
                    input
                )
            }


            // -------------------------------------------------
            // Front Camera
            // -------------------------------------------------

            guard
                let videoDevice =
                    AVCaptureDevice.default(
                        .builtInWideAngleCamera,
                        for: .video,
                        position: .front
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
                    "❌ Could not configure FRONT camera"
                )

                self.captureSession.commitConfiguration()

                return
            }


            self.captureSession.addInput(
                videoInput
            )


            // -------------------------------------------------
            // Video Output
            // -------------------------------------------------

            if !self.captureSession.outputs.contains(
                self.videoOutput
            ) {

                guard self.captureSession.canAddOutput(
                    self.videoOutput
                ) else {

                    print(
                        "❌ Could not add video output"
                    )

                    self.captureSession.commitConfiguration()

                    return
                }


                self.captureSession.addOutput(
                    self.videoOutput
                )


                self.videoOutput
                    .alwaysDiscardsLateVideoFrames = true


                self.videoOutput.setSampleBufferDelegate(
                    self,
                    queue: self.videoBufferQueue
                )
            }


            // -------------------------------------------------
            // Orientation
            // -------------------------------------------------

            if let connection =
                self.videoOutput.connection(
                    with: .video
                ) {

                if connection.isVideoOrientationSupported {

                    connection.videoOrientation =
                        .landscapeLeft
                }


                // -------------------------------------------------
                // Do NOT mirror Vision output.
                // Preview handles mirroring separately.
                // -------------------------------------------------

                if connection.isVideoMirroringSupported {

                    connection
                        .automaticallyAdjustsVideoMirroring =
                        false

                    connection.isVideoMirrored =
                        false
                }
            }


            self.captureSession.commitConfiguration()

            self.isConfigured = true

            self.startSession()
        }
    }


    // =========================================================
    // MARK: - Video Orientation Sync
    // =========================================================

    func updateVideoOrientation(
        _ orientation: AVCaptureVideoOrientation
    ) {

        sessionQueue.async { [weak self] in

            guard let self else {
                return
            }

            if let connection =
                self.videoOutput.connection(
                    with: .video
                ),
               connection.isVideoOrientationSupported {

                if connection.videoOrientation != orientation {

                    connection.videoOrientation =
                        orientation
                }
            }
        }
    }


    // =========================================================
    // MARK: - Vision Orientation
    // =========================================================

    private func currentOrientationAndSize()
        -> (
            CGImagePropertyOrientation,
            CGSize
        )
    {

        return (
            .up,
            CGSize(
                width: 1920,
                height: 1080
            )
        )
    }


    // =========================================================
    // MARK: - Capture Output
    // =========================================================

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
                cvPixelBuffer: pixelBuffer,
                orientation: orientation,
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

                DispatchQueue.main.async {
                    [weak self] in

                    self?.poseModel =
                        PoseModel(
                            detectedPeople: [],
                            videoSize: videoSize
                        )

                    self?.detectedPlayerCount =
                        0

                    self?.debugStatus =
                        "No person detected"
                }

                return
            }


            // =====================================================
            // ONLY FOUR GAMEPLAY JOINTS
            // =====================================================

            let trackedJoints:
                [VNHumanBodyPoseObservation.JointName] = [

                    .leftWrist,
                    .rightWrist,
                    .leftAnkle,
                    .rightAnkle
                ]


            // =====================================================
            // RAW PEOPLE
            // =====================================================

            var rawPeople:
                [
                    (
                        joints:
                            [
                                VNHumanBodyPoseObservation.JointName:
                                    CGPoint
                            ],

                        jointList:
                            [JointPoint],

                        avgX:
                            CGFloat
                    )
                ] = []


            // =====================================================
            // PROCESS UP TO TWO PEOPLE
            // =====================================================

            for observation in observations.prefix(2) {

                let recognizedPoints =
                    try observation.recognizedPoints(
                        .all
                    )


                var jointDict:
                    [
                        VNHumanBodyPoseObservation.JointName:
                            CGPoint
                    ] = [:]


                var jointList:
                    [JointPoint] = []


                var sumX:
                    CGFloat = 0


                var countX:
                    CGFloat = 0


                // =================================================
                // PROCESS FOUR JOINTS
                // =================================================

                for jointName in trackedJoints {

                    if let point =
                        recognizedPoints[jointName],
                       point.confidence > 0.1 {

                        // -------------------------------------------------
                        // Convert Vision coordinate
                        //
                        // Vision:
                        // origin = bottom-left
                        //
                        // Our mapped coordinate:
                        // origin = top-left
                        // -------------------------------------------------

                        let mappedPoint =
                            CGPoint(
                                x: point.location.x,
                                y: 1.0 - point.location.y
                            )


                        // -------------------------------------------------
                        // Keep raw mapped coordinate in dictionary
                        // -------------------------------------------------

                        jointDict[jointName] =
                            mappedPoint


                        // -------------------------------------------------
                        // IMPORTANT:
                        //
                        // Smooth the MAPPED point.
                        //
                        // Previously the raw Vision point was passed here.
                        // -------------------------------------------------

                        let smoothedPoint =
                            smoothJoint(
                                mappedPoint,
                                personIndex: 0,
                                jointName: jointName
                            )


                        // -------------------------------------------------
                        // JointPoint
                        // -------------------------------------------------

                        jointList.append(

                            JointPoint(
                                name: jointName,

                                location:
                                    smoothedPoint,

                                confidence:
                                    point.confidence
                            )
                        )


                        // -------------------------------------------------
                        // Person center
                        // -------------------------------------------------

                        sumX += mappedPoint.x

                        countX += 1
                    }
                }


                let avgX =
                    countX > 0
                    ? (sumX / countX)
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


            // =========================================================
            // PLAYER ORDER
            // =========================================================
            //
            // Front-camera preview is mirrored.
            //
            // Leftmost person on screen
            //      -> Player 1
            //
            // Rightmost person on screen
            //      -> Player 2
            // =========================================================

            rawPeople.sort {
                $0.avgX > $1.avgX
            }


            var people:
                [DetectedPerson] = []


            // =========================================================
            // ONE PERSON
            // =========================================================

            if rawPeople.count == 1 {

                let p =
                    rawPeople[0]


                // -----------------------------------------------------
                // Mirrored screen:
                //
                // avgX > 0.5
                //     -> left side of preview
                //     -> Player 1
                //
                // avgX <= 0.5
                //     -> right side of preview
                //     -> Player 2
                // -----------------------------------------------------

                let assignedIndex =
                    p.avgX <= 0.5
                    ? 1
                    : 0


                people.append(

                    DetectedPerson(
                        personIndex:
                            assignedIndex,

                        joints:
                            p.joints,

                        jointList:
                            p.jointList
                    )
                )
            }


            // =========================================================
            // TWO PEOPLE
            // =========================================================

            else {

                for (index, personData)
                    in rawPeople.enumerated() {

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
            }


            // =========================================================
            // UPDATE UI
            // =========================================================

            DispatchQueue.main.async {
                [weak self] in

                self?.poseModel =
                    PoseModel(
                        detectedPeople:
                            people,

                        videoSize:
                            videoSize
                    )


                self?.detectedPlayerCount =
                    people.count


                self?.debugStatus =
                    "Tracking \(people.count) player(s)"
            }


        } catch {

            DispatchQueue.main.async {
                [weak self] in

                self?.debugStatus =
                    "Vision error: \(error.localizedDescription)"
            }
        }
    }


    // =========================================================
    // MARK: - Smooth Joint
    // =========================================================

    private func smoothJoint(
        _ point: CGPoint,
        personIndex: Int,
        jointName:
            VNHumanBodyPoseObservation.JointName
    ) -> CGPoint {

        let key =
            "\(personIndex)_\(jointName.rawValue)"


        // ---------------------------------------------------------
        // First detection
        // ---------------------------------------------------------

        guard let previous =
                smoothedJointPositions[key]
        else {

            smoothedJointPositions[key] =
                point

            return point
        }


        // ---------------------------------------------------------
        // Exponential smoothing
        // ---------------------------------------------------------

        let smoothed =
            CGPoint(

                x:
                    previous.x
                    +
                    (
                        point.x
                        -
                        previous.x
                    )
                    *
                    smoothingFactor,

                y:
                    previous.y
                    +
                    (
                        point.y
                        -
                        previous.y
                    )
                    *
                    smoothingFactor
            )


        smoothedJointPositions[key] =
            smoothed


        return smoothed
    }
}
