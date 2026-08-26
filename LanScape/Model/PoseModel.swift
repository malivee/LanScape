import Foundation
import CoreGraphics
import Vision
import SwiftUI
import Combine

// MARK: - Player Role

public enum PlayerRole: String, CaseIterable {

    case player1 = "Player 1"
    case player2 = "Player 2"

    // Backward compatibility
    public static var upperBody: PlayerRole {
        .player1
    }

    public static var lowerBody: PlayerRole {
        .player2
    }

    public static var fullBody: PlayerRole {
        .player1
    }

    public var title: String {

        switch self {

        case .player1:
            return "Person 1 (Yellow)"

        case .player2:
            return "Person 2 (Blue)"
        }
    }

    public var primaryColor: Color {

        switch self {

        case .player1:
            return Color(hex: "FFD84D")

        case .player2:
            return Color(hex: "0088FF")
        }
    }

    public var connections:
        [
            (
                VNHumanBodyPoseObservation.JointName,
                VNHumanBodyPoseObservation.JointName
            )
        ] {

        []
    }

    public var relevantJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

        PoseBodyDefinitions.trackedJoints
    }
}

// MARK: - Pose Body Definitions

public struct PoseBodyDefinitions {

    /// Only these four joints are used for gameplay.
    ///
    /// leftWrist  = left hand
    /// rightWrist = right hand
    /// leftAnkle  = left leg
    /// rightAnkle = right leg

    public static let trackedJoints:
        Set<VNHumanBodyPoseObservation.JointName> = [

        .leftWrist,
        .rightWrist,
        .leftAnkle,
        .rightAnkle
    ]

    public static var allJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

        trackedJoints
    }

    // MARK: - Shared Joint Color

    /// IMPORTANT:
    ///
    /// This is the SINGLE source of truth
    /// for the colors used by:
    ///
    /// 1. Vision skeleton points
    /// 2. Hitboxes
    ///
    public static func jointColor(
        for joint:
            VNHumanBodyPoseObservation.JointName,
        personIndex: Int
    ) -> Color {

        // =====================================================
        // PLAYER 1
        // =====================================================

        if personIndex == 0 {

            switch joint {

            // LEFT HAND
            case .leftWrist:
                return Color(hex: "FFD84D")

            // RIGHT HAND
            case .rightWrist:
                return Color(hex: "FF9F1C")

            // LEFT LEG
            case .leftAnkle:
                return Color(hex: "4CD964")

            // RIGHT LEG
            case .rightAnkle:
                return Color(hex: "AF52DE")

            default:
                return Color(hex: "FFD84D")
            }
        }

        // =====================================================
        // PLAYER 2
        // =====================================================

        switch joint {

        // LEFT HAND
        case .leftWrist:
            return Color(hex: "0088FF")

        // RIGHT HAND
        case .rightWrist:
            return Color(hex: "33E0FF")

        // LEFT LEG
        case .leftAnkle:
            return Color(hex: "8A5CFF")

        // RIGHT LEG
        case .rightAnkle:
            return Color(hex: "FF4FA3")

        default:
            return Color(hex: "0088FF")
        }
    }
}

// MARK: - Joint Point

public struct JointPoint: Identifiable {

    public let id = UUID()

    public let name:
        VNHumanBodyPoseObservation.JointName

    public let location: CGPoint

    public let confidence: Float

    public init(
        name:
            VNHumanBodyPoseObservation.JointName,

        location:
            CGPoint,

        confidence:
            Float
    ) {

        self.name = name
        self.location = location
        self.confidence = confidence
    }

    public var displayName: String {

        switch name {

        case .rightWrist:
            return "Right Wrist"

        case .leftWrist:
            return "Left Wrist"

        case .rightAnkle:
            return "Right Leg"

        case .leftAnkle:
            return "Left Leg"

        default:
            return name.rawValue.rawValue
        }
    }
}

// MARK: - Detected Person

public struct DetectedPerson: Identifiable {

    public let id = UUID()

    public let personIndex: Int

    public let joints:
        [
            VNHumanBodyPoseObservation.JointName:
                CGPoint
        ]

    public let jointList:
        [JointPoint]

    public init(
        personIndex: Int,

        joints:
            [
                VNHumanBodyPoseObservation.JointName:
                    CGPoint
            ],

        jointList:
            [JointPoint]
    ) {

        self.personIndex = personIndex
        self.joints = joints
        self.jointList = jointList
    }

    public var role: PlayerRole {

        switch personIndex {

        case 0:
            return .player1

        case 1:
            return .player2

        default:
            return .player1
        }
    }

    public var activeConnections:
        [
            (
                VNHumanBodyPoseObservation.JointName,
                VNHumanBodyPoseObservation.JointName
            )
        ] {

        role.connections
    }

    public var filteredJointList:
        [JointPoint] {

        let allowedJoints =
            role.relevantJoints

        return jointList.filter {
            allowedJoints.contains($0.name)
        }
    }

    public func jointColor(
        for joint:
            VNHumanBodyPoseObservation.JointName
    ) -> Color {

        PoseBodyDefinitions.jointColor(
            for: joint,
            personIndex: personIndex
        )
    }
}

// MARK: - Pose Model

public final class PoseModel:
    ObservableObject {

    @Published
    public var detectedPeople:
        [DetectedPerson] = []

    @Published
    public var videoSize:
        CGSize =
        CGSize(
            width: 1920,
            height: 1080
        )

    public init(
        detectedPeople:
            [DetectedPerson] = [],

        videoSize:
            CGSize =
            CGSize(
                width: 1920,
                height: 1080
            )
    ) {

        self.detectedPeople =
            detectedPeople

        self.videoSize =
            videoSize
    }
}
