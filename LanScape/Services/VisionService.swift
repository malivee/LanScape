//
//  VisionService.swift
//  LanScape
//

import Foundation
import AVFoundation
import Vision
import Combine
import ImageIO
import UIKit

// MARK: - Vision Service

final class VisionService: NSObject,
    ObservableObject,
    AVCaptureVideoDataOutputSampleBufferDelegate
{
    
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
    
    private let videoOutput =
        AVCaptureVideoDataOutput()
    
    private let sessionQueue =
        DispatchQueue(
            label: "cameraSessionQueue"
        )
    
    private let videoBufferQueue =
        DispatchQueue(
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
    // MARK: - Joint Smoothing
    // =========================================================
    
    private var smoothedJointPositions:
        [String: CGPoint] = [:]
    
    private let smoothingFactor:
        CGFloat = 0.20
    
    
    // =========================================================
    // MARK: - Player Lock
    // =========================================================
    
    /*
     These are the last known horizontal positions
     of Player 1 and Player 2.
     
     The values use normalized Vision coordinates:
     
         0.0 ------------------------ 1.0
          left                         right
     
     Once two people are detected, their positions
     become the initial Player 1 / Player 2 anchors.
    */
    
    private var player1AnchorX:
        CGFloat?
    
    private var player2AnchorX:
        CGFloat?
    
    
    /*
     How far a person is allowed to move from their
     previous anchor before we consider the assignment
     unreliable.
     
     This is deliberately fairly large because people
     can move during gameplay.
    */
    
    private let maximumPlayerAssignmentDistance:
        CGFloat = 0.35
    
    
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
    // MARK: - Reset Player Lock
    // =========================================================
    
    /*
     Call this when you want to completely start
     player tracking again.
     
     For example, this can be called when entering
     Player Setup for a new round.
    */
    
    func resetPlayerTracking() {
        
        sessionQueue.async { [weak self] in
            
            guard let self else {
                return
            }
            
            self.player1AnchorX = nil
            self.player2AnchorX = nil
            
            self.smoothedJointPositions.removeAll()
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
                
                
                /*
                 Vision receives the non-mirrored image.
                 The preview itself handles the visual
                 mirroring.
                 */
                
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
        _ orientation:
            AVCaptureVideoOrientation
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
                
                if connection.videoOrientation !=
                    orientation {
                    
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
        didOutput sampleBuffer:
            CMSampleBuffer,
        from connection:
            AVCaptureConnection
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
                
                DispatchQueue.main.async {
                    [weak self] in
                    
                    self?.poseModel =
                        PoseModel(
                            detectedPeople: [],
                            videoSize:
                                videoSize
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
                [
                    VNHumanBodyPoseObservation.JointName
                ] = [
                    .leftWrist,
                    .rightWrist,
                    .leftAnkle,
                    .rightAnkle
                ]
            
            
            // =====================================================
            // RAW PEOPLE
            // =====================================================
            

            
            var rawPeople: [PlayerCandidate] = []
            
            
            // =====================================================
            // PROCESS UP TO TWO PEOPLE
            // =====================================================
            
            for observation
                in observations.prefix(2) {
                
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
                
                for jointName
                    in trackedJoints {
                    
                    guard
                        let point =
                            recognizedPoints[
                                jointName
                            ],
                        point.confidence > 0.1
                    else {
                        continue
                    }
                    
                    
                    // -------------------------------------------------
                    // Convert Vision coordinates
                    //
                    // Vision uses bottom-left origin.
                    // Our mapped coordinates use top-left origin.
                    // -------------------------------------------------
                    
                    let mappedPoint =
                        CGPoint(
                            x:
                                point.location.x,
                            y:
                                1.0
                                -
                                point.location.y
                        )
                    
                    
                    // -------------------------------------------------
                    // Store raw mapped point
                    // -------------------------------------------------
                    
                    jointDict[jointName] =
                        mappedPoint
                    
                    
                    /*
                     IMPORTANT:
                     
                     Do NOT smooth yet.
                     
                     We first need to determine which
                     detected person is Player 1 / Player 2.
                     
                     After that we smooth using the
                     locked player identity.
                     */
                    
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
                    
                    
                    // -------------------------------------------------
                    // Person horizontal center
                    // -------------------------------------------------
                    
                    sumX += mappedPoint.x
                    
                    countX += 1
                }
                
                
                let avgX:
                    CGFloat =
                    countX > 0
                    ? sumX / countX
                    : 0.5
                
                
                rawPeople.append(
                    PlayerCandidate(
                        joints: jointDict,
                        jointList: jointList,
                        avgX: avgX
                    )
                )
            }
            
            
            // =====================================================
            // ASSIGN PLAYER IDENTITIES
            // =====================================================
            
            let assignments =
                assignPlayers(
                    rawPeople
                )
            
            
            // =====================================================
            // CREATE DETECTED PEOPLE
            // =====================================================
            
            var people:
                [DetectedPerson] = []
            
            
            for assignment
                in assignments {
                
                // -------------------------------------------------
                // Smooth joints using LOCKED player index
                // -------------------------------------------------
                
                var smoothedJointList:
                    [JointPoint] = []
                
                
                for joint
                    in assignment.person.jointList {
                    
                    let smoothed =
                        smoothJoint(
                            joint.location,
                            personIndex:
                                assignment.playerIndex,
                            jointName:
                                joint.name
                        )
                    
                    
                    smoothedJointList.append(
                        
                        JointPoint(
                            name:
                                joint.name,
                            location:
                                smoothed,
                            confidence:
                                joint.confidence
                        )
                    )
                }
                
                
                people.append(
                    
                    DetectedPerson(
                        personIndex:
                            assignment.playerIndex,
                        
                        joints:
                            assignment.person.joints,
                        
                        jointList:
                            smoothedJointList
                    )
                )
            }
            
            
            // =====================================================
            // UPDATE UI
            // =====================================================
            
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
    // MARK: - Player Assignment Implementation
    // =========================================================
    
    /*
     Swift does not allow the local RawPerson type from
     captureOutput to be used by another method.
     
     Therefore the actual assignment is implemented below
     using a dedicated tracking structure.
    */
    
    private struct PlayerCandidate {
        
        let joints:
            [
                VNHumanBodyPoseObservation.JointName:
                    CGPoint
            ]
        
        let jointList:
            [JointPoint]
        
        let avgX:
            CGFloat
    }
    
    
    private struct PlayerAssignment {
        
        let person:
            PlayerCandidate
        
        let playerIndex:
            Int
    }
    
    
    private func assignPlayers(
        _ people:
            [PlayerCandidate]
    ) -> [PlayerAssignment] {
        
        guard !people.isEmpty else {
            return []
        }
        
        
        // =====================================================
        // ONE PERSON
        // =====================================================
        
        if people.count == 1 {
            
            let person =
                people[0]
            
            
            // -------------------------------------------------
            // If no lock exists yet, establish it based on
            // which side of the screen the person occupies.
            // -------------------------------------------------
            
            if player1AnchorX == nil &&
               player2AnchorX == nil {
                
                if person.avgX >= 0.5 {
                    
                    player1AnchorX =
                        person.avgX
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                0
                        )
                    ]
                    
                } else {
                    
                    player2AnchorX =
                        person.avgX
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                1
                        )
                    ]
                }
            }
            
            
            // -------------------------------------------------
            // Existing Player 1
            // -------------------------------------------------
            
            if let anchor1 =
                player1AnchorX,
               player2AnchorX == nil {
                
                let distance =
                    abs(
                        person.avgX
                        -
                        anchor1
                    )
                
                
                if distance
                    <= maximumPlayerAssignmentDistance {
                    
                    player1AnchorX =
                        updateAnchor(
                            old:
                                anchor1,
                            new:
                                person.avgX
                        )
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                0
                        )
                    ]
                }
            }
            
            
            // -------------------------------------------------
            // Existing Player 2
            // -------------------------------------------------
            
            if let anchor2 =
                player2AnchorX,
               player1AnchorX == nil {
                
                let distance =
                    abs(
                        person.avgX
                        -
                        anchor2
                    )
                
                
                if distance
                    <= maximumPlayerAssignmentDistance {
                    
                    player2AnchorX =
                        updateAnchor(
                            old:
                                anchor2,
                            new:
                                person.avgX
                        )
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                1
                        )
                    ]
                }
            }
            
            
            // -------------------------------------------------
            // Both anchors exist
            // -------------------------------------------------
            
            if let anchor1 =
                player1AnchorX,
               let anchor2 =
                player2AnchorX {
                
                let distance1 =
                    abs(
                        person.avgX
                        -
                        anchor1
                    )
                
                let distance2 =
                    abs(
                        person.avgX
                        -
                        anchor2
                    )
                
                
                if distance1 <= distance2 {
                    
                    player1AnchorX =
                        updateAnchor(
                            old:
                                anchor1,
                            new:
                                person.avgX
                        )
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                0
                        )
                    ]
                    
                } else {
                    
                    player2AnchorX =
                        updateAnchor(
                            old:
                                anchor2,
                            new:
                                person.avgX
                        )
                    
                    return [
                        PlayerAssignment(
                            person:
                                person,
                            playerIndex:
                                1
                        )
                    ]
                }
            }
            
            
            return []
        }
        
        
        // =====================================================
        // TWO PEOPLE
        // =====================================================
        
        let first =
            people[0]
        
        let second =
            people[1]
        
        
        // -----------------------------------------------------
        // FIRST TIME WE SEE TWO PEOPLE
        // -----------------------------------------------------
        
        if player1AnchorX == nil &&
           player2AnchorX == nil {
            
            /*
             On the mirrored front-camera preview:
             
             Larger raw X corresponds to the LEFT side
             of the visible preview.
             
             Therefore:
             
             larger X → Player 1
             smaller X → Player 2
            */
            
            if first.avgX >= second.avgX {
                
                player1AnchorX =
                    first.avgX
                
                player2AnchorX =
                    second.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            1
                    )
                ]
                
            } else {
                
                player1AnchorX =
                    second.avgX
                
                player2AnchorX =
                    first.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            1
                    )
                ]
            }
        }
        
        
        // =====================================================
        // ONLY PLAYER 1 IS LOCKED
        // =====================================================
        
        if let anchor1 =
            player1AnchorX,
           player2AnchorX == nil {
            
            let distanceFirst =
                abs(
                    first.avgX
                    -
                    anchor1
                )
            
            let distanceSecond =
                abs(
                    second.avgX
                    -
                    anchor1
                )
            
            
            if distanceFirst <= distanceSecond {
                
                player1AnchorX =
                    updateAnchor(
                        old:
                            anchor1,
                        new:
                            first.avgX
                    )
                
                player2AnchorX =
                    second.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            1
                    )
                ]
                
            } else {
                
                player1AnchorX =
                    updateAnchor(
                        old:
                            anchor1,
                        new:
                            second.avgX
                    )
                
                player2AnchorX =
                    first.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            1
                    )
                ]
            }
        }
        
        
        // =====================================================
        // ONLY PLAYER 2 IS LOCKED
        // =====================================================
        
        if let anchor2 =
            player2AnchorX,
           player1AnchorX == nil {
            
            let distanceFirst =
                abs(
                    first.avgX
                    -
                    anchor2
                )
            
            let distanceSecond =
                abs(
                    second.avgX
                    -
                    anchor2
                )
            
            
            if distanceFirst <= distanceSecond {
                
                player2AnchorX =
                    updateAnchor(
                        old:
                            anchor2,
                        new:
                            first.avgX
                    )
                
                player1AnchorX =
                    second.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            1
                    )
                ]
                
            } else {
                
                player2AnchorX =
                    updateAnchor(
                        old:
                            anchor2,
                        new:
                            second.avgX
                    )
                
                player1AnchorX =
                    first.avgX
                
                return [
                    PlayerAssignment(
                        person:
                            first,
                        playerIndex:
                            0
                    ),
                    
                    PlayerAssignment(
                        person:
                            second,
                        playerIndex:
                            1
                    )
                ]
            }
        }
        
        
        // =====================================================
        // BOTH PLAYERS LOCKED
        // =====================================================
        
        guard
            let anchor1 =
                player1AnchorX,
            let anchor2 =
                player2AnchorX
        else {
            return []
        }
        
        
        // -----------------------------------------------------
        // Assignment A
        // -----------------------------------------------------
        
        let normalDistance =
            abs(
                first.avgX
                -
                anchor1
            )
            +
            abs(
                second.avgX
                -
                anchor2
            )
        
        
        // -----------------------------------------------------
        // Assignment B
        // -----------------------------------------------------
        
        let swappedDistance =
            abs(
                first.avgX
                -
                anchor2
            )
            +
            abs(
                second.avgX
                -
                anchor1
            )
        
        
        // -----------------------------------------------------
        // Choose the assignment closest to previous positions
        // -----------------------------------------------------
        
        if normalDistance <= swappedDistance {
            
            player1AnchorX =
                updateAnchor(
                    old:
                        anchor1,
                    new:
                        first.avgX
                )
            
            player2AnchorX =
                updateAnchor(
                    old:
                        anchor2,
                    new:
                        second.avgX
                )
            
            return [
                PlayerAssignment(
                    person:
                        first,
                    playerIndex:
                        0
                ),
                
                PlayerAssignment(
                    person:
                        second,
                    playerIndex:
                        1
                )
            ]
            
        } else {
            
            player1AnchorX =
                updateAnchor(
                    old:
                        anchor1,
                    new:
                        second.avgX
                )
            
            player2AnchorX =
                updateAnchor(
                    old:
                        anchor2,
                    new:
                        first.avgX
                )
            
            return [
                PlayerAssignment(
                    person:
                        second,
                    playerIndex:
                        0
                ),
                
                PlayerAssignment(
                    person:
                        first,
                    playerIndex:
                        1
                )
            ]
        }
    }
    
    
    // =========================================================
    // MARK: - Anchor Update
    // =========================================================
    
    private func updateAnchor(
        old:
            CGFloat,
        new:
            CGFloat
    ) -> CGFloat {
        
        /*
         Don't immediately move the anchor to the new
         position.
         
         Slowly moving the anchor makes the identity
         more stable while still allowing the player
         to move around.
        */
        
        let anchorUpdateFactor:
            CGFloat = 0.10
        
        return
            old
            +
            (
                new
                -
                old
            )
            *
            anchorUpdateFactor
    }
    
    
    // =========================================================
    // MARK: - Joint Smoothing
    // =========================================================
    
    private func smoothJoint(
        _ point:
            CGPoint,
        personIndex:
            Int,
        jointName:
            VNHumanBodyPoseObservation.JointName
    ) -> CGPoint {
        
        /*
         IMPORTANT:
         
         The smoothing key contains the LOCKED player
         identity.
         
         Therefore:
         
         Player 1 + left wrist
         
         has a completely different history from:
         
         Player 2 + left wrist
        */
        
        let key =
            "\(personIndex)_\(jointName.rawValue)"
        
        
        // -----------------------------------------------------
        // First point
        // -----------------------------------------------------
        
        guard let previous =
                smoothedJointPositions[key]
        else {
            
            smoothedJointPositions[key] =
                point
            
            return point
        }
        
        
        // -----------------------------------------------------
        // Exponential smoothing
        // -----------------------------------------------------
        
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
