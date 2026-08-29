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
            return "Orang 1"

        case .player2:
            return "Orang 2"
        }
    }

    public var primaryColor: Color {

        switch self {

        case .player1:
            return Color(hex: "FFD84D")

        case .player2:
            return Color(hex: "00D2FF")
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

// MARK: - Joint Shape

public enum JointShape {
    case circle
    case square
}

// MARK: - Pose Body Definitions

public struct PoseBodyDefinitions {

    /// Only these four joints are used for gameplay.
    ///
    /// leftWrist  = left hand (Circle)
    /// rightWrist = right hand (Circle)
    /// leftAnkle  = left leg (Square)
    /// rightAnkle = right leg (Square)

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

    // MARK: - Joint Shape

    public static func jointShape(
        for joint: VNHumanBodyPoseObservation.JointName
    ) -> JointShape {
        switch joint {
        case .leftWrist, .rightWrist:
            return .circle
        case .leftAnkle, .rightAnkle:
            return .square
        default:
            return .circle
        }
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
    /// Player 1 (Orang 1):
    ///   - Left (Kiri / Left Wrist & Left Ankle): RED (#FF3B30)
    ///   - Right (Kanan / Right Wrist & Right Ankle): YELLOW (#FFD84D)
    /// Player 2 (Orang 2):
    ///   - Left (Kiri / Left Wrist & Left Ankle): GREEN (#34C759)
    ///   - Right (Kanan / Right Wrist & Right Ankle): CYAN (#00D2FF)
    ///
    public static func jointColor(
        for joint:
            VNHumanBodyPoseObservation.JointName,
        personIndex: Int
    ) -> Color {

        // =====================================================
        // PLAYER 1 (Person 1 / Orang 1)
        // Left = RED, Right = YELLOW
        // =====================================================

        if personIndex == 0 {

            switch joint {

            // LEFT HAND & LEFT LEG -> RED
            case .leftWrist, .leftAnkle:
                return Color(hex: "FF3B30")

            // RIGHT HAND & RIGHT LEG -> YELLOW
            case .rightWrist, .rightAnkle:
                return Color(hex: "FFD84D")

            default:
                return Color(hex: "FF3B30")
            }
        }

        // =====================================================
        // PLAYER 2 (Person 2 / Orang 2)
        // Left = GREEN, Right = CYAN / LIGHT BLUE
        // =====================================================

        switch joint {

        // LEFT HAND & LEFT LEG -> GREEN
        case .leftWrist, .leftAnkle:
            return Color(hex: "34C759")

        // RIGHT HAND & RIGHT LEG -> CYAN
        case .rightWrist, .rightAnkle:
            return Color(hex: "00D2FF")

        default:
            return Color(hex: "34C759")
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

    public var shape: JointShape {
        PoseBodyDefinitions.jointShape(for: name)
    }

    public var displayName: String {

        switch name {

        case .rightWrist:
            return "Right Hand"

        case .leftWrist:
            return "Left Hand"

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

    public func jointShape(
        for joint:
            VNHumanBodyPoseObservation.JointName
    ) -> JointShape {

        PoseBodyDefinitions.jointShape(
            for: joint
        )
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
