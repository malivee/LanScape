import Foundation
import CoreGraphics
import Vision
import SwiftUI

// MARK: - Player Role

public enum PlayerRole: String, CaseIterable {
    case player1 = "Player 1"
    case player2 = "Player 2"

    // Backward-compatibility aliases
    public static var upperBody: PlayerRole { .player1 }
    public static var lowerBody: PlayerRole { .player2 }
    public static var fullBody: PlayerRole { .player1 }

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

    public var connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        []
    }

    public var relevantJoints: Set<VNHumanBodyPoseObservation.JointName> {
        PoseBodyDefinitions.trackedJoints
    }
}

// MARK: - Pose Body Definitions

public struct PoseBodyDefinitions {

    /// 4 Tracked joints per player: 2 hands (left/right wrist) and 2 legs (left/right ankle)
    /// Total of 8 joints across both Player 1 and Player 2
    public static let trackedJoints: Set<VNHumanBodyPoseObservation.JointName> = [
        .rightWrist,  // Right Wrist / Hand
        .leftWrist,   // Left Wrist / Hand
        .rightAnkle,  // Right Leg
        .leftAnkle    // Left Leg
    ]

    public static var allJoints: Set<VNHumanBodyPoseObservation.JointName> {
        trackedJoints
    }

    /// Color lookup per joint per person as specified in design
    public static func jointColor(for joint: VNHumanBodyPoseObservation.JointName, personIndex: Int) -> Color {
        if personIndex == 0 {
            // PERSON 1 (YELLOW)
            switch joint {
            case .rightWrist:
                return Color(hex: "FFD84D")
            case .leftWrist:
                return Color(hex: "FFF066")
            case .rightAnkle, .rightKnee:
                return Color(hex: "FFC13D")
            case .leftAnkle, .leftKnee:
                return Color(hex: "C6FF4D")
            default:
                return Color(hex: "FFD84D")
            }
        } else {
            // PERSON 2 (BLUE)
            switch joint {
            case .rightWrist:
                return Color(hex: "0088FF")
            case .leftWrist:
                return Color(hex: "33E0FF")
            case .rightAnkle, .rightKnee:
                return Color(hex: "5A6BFF")
            case .leftAnkle, .leftKnee:
                return Color(hex: "8A5CFF")
            default:
                return Color(hex: "0088FF")
            }
        }
    }
}

// MARK: - Joint Point

public struct JointPoint: Identifiable {
    public let id = UUID()
    public let name: VNHumanBodyPoseObservation.JointName
    public let location: CGPoint
    public let confidence: Float

    public init(name: VNHumanBodyPoseObservation.JointName, location: CGPoint, confidence: Float) {
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
    public let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    public let jointList: [JointPoint]

    public init(
        personIndex: Int,
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        jointList: [JointPoint]
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

    public var activeConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        role.connections
    }

    public var filteredJointList: [JointPoint] {
        let allowedJoints = role.relevantJoints
        return jointList.filter { allowedJoints.contains($0.name) }
    }

    public func jointColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        PoseBodyDefinitions.jointColor(for: joint, personIndex: personIndex)
    }
}

// MARK: - Pose Model

public struct PoseModel {
    public var detectedPeople: [DetectedPerson] = []
    public var videoSize: CGSize = CGSize(width: 1920, height: 1080)

    public init(detectedPeople: [DetectedPerson] = [], videoSize: CGSize = CGSize(width: 1920, height: 1080)) {
        self.detectedPeople = detectedPeople
        self.videoSize = videoSize
    }
}
