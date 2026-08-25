import Foundation
import CoreGraphics
import Vision
import SwiftUI

// MARK: - Player Role

public enum PlayerRole: String, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    case fullBody = "Full Body"

    public var title: String {
        switch self {
        case .upperBody:
            return "Player 1: Upper Body"
        case .lowerBody:
            return "Player 2: Lower Body"
        case .fullBody:
            return "Full Body"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .upperBody:
            return .yellow
        case .lowerBody:
            return .blue
        case .fullBody:
            return .green
        }
    }

    public var connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        switch self {
        case .upperBody:
            return PoseBodyDefinitions.upperBodyConnections
        case .lowerBody:
            return PoseBodyDefinitions.lowerBodyConnections
        case .fullBody:
            return PoseBodyDefinitions.allConnections
        }
    }

    public var relevantJoints: Set<VNHumanBodyPoseObservation.JointName> {
        switch self {
        case .upperBody:
            return PoseBodyDefinitions.upperBodyJoints
        case .lowerBody:
            return PoseBodyDefinitions.lowerBodyJoints
        case .fullBody:
            return PoseBodyDefinitions.allJoints
        }
    }
}

// MARK: - Pose Body Definitions

public struct PoseBodyDefinitions {

    // MARK: Upper Body Connections (Head, Neck, Arms, Hands, Upper Torso)
    public static let upperBodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.nose, .leftEye),
        (.nose, .rightEye),
        (.leftEye, .leftEar),
        (.rightEye, .rightEar),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .rightShoulder),
        (.neck, .root),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist)
    ]

    // MARK: Lower Body Connections (Hips, Knees, Ankles/Feet)
    public static let lowerBodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    // MARK: Torso / Core Connections
    public static let coreConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip)
    ]

    // MARK: All Connections (Full Body)
    public static var allConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        upperBodyConnections + lowerBodyConnections + coreConnections
    }

    // MARK: Upper Joints (Player 1)
    public static let upperBodyJoints: Set<VNHumanBodyPoseObservation.JointName> = [
        .nose,
        .neck,
        .leftEye,
        .rightEye,
        .leftEar,
        .rightEar,
        .leftShoulder,
        .rightShoulder,
        .root,
        .leftElbow,
        .leftWrist,
        .rightElbow,
        .rightWrist
    ]

    // MARK: Lower Joints (Player 2: Kaki sampai Hips)
    public static let lowerBodyJoints: Set<VNHumanBodyPoseObservation.JointName> = [
        .leftHip,
        .rightHip,
        .leftKnee,
        .rightKnee,
        .leftAnkle,
        .rightAnkle
    ]

    // MARK: All Joints
    public static var allJoints: Set<VNHumanBodyPoseObservation.JointName> {
        upperBodyJoints.union(lowerBodyJoints)
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
            // Player 1: Upper Body (Head, Arms, Hands, Torso)
            return .upperBody
        case 1:
            // Player 2: Lower Body (Hips to Feet)
            return .lowerBody
        default:
            return .fullBody
        }
    }

    public var activeConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        role.connections
    }

    public var filteredJointList: [JointPoint] {
        let allowedJoints = role.relevantJoints
        return jointList.filter { allowedJoints.contains($0.name) }
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
