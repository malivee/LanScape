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
            return .cyan

        case .lowerBody:
            return .green

        case .fullBody:
            return .yellow
        }
    }

    public var connections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] {

        switch self {

        case .upperBody:
            return PoseBodyDefinitions.upperBodyConnections

        case .lowerBody:
            return PoseBodyDefinitions.lowerBodyConnections

        case .fullBody:
            return PoseBodyDefinitions.allConnections
        }
    }

    public var relevantJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

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

    // MARK: Upper Body

    public static let upperBodyConnections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] = [

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

    // MARK: Lower Body

    public static let lowerBodyConnections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] = [

        (.leftHip, .rightHip),

        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),

        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    // MARK: Core

    public static let coreConnections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] = [

        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip)
    ]

    // MARK: All Connections

    public static var allConnections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] {

        upperBodyConnections
        + lowerBodyConnections
        + coreConnections
    }

    // MARK: Upper Joints

    public static let upperBodyJoints:
        Set<VNHumanBodyPoseObservation.JointName> = [

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

    // MARK: Lower Joints

    public static let lowerBodyJoints:
        Set<VNHumanBodyPoseObservation.JointName> = [

        .leftHip,
        .rightHip,

        .leftKnee,
        .rightKnee,

        .leftAnkle,
        .rightAnkle
    ]

    // MARK: All Joints

    public static var allJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

        upperBodyJoints.union(
            lowerBodyJoints
        )
    }
}

// MARK: - Joint Point

struct JointPoint: Identifiable {

    let id = UUID()

    let name:
        VNHumanBodyPoseObservation.JointName

    let location: CGPoint

    let confidence: Float
}

// MARK: - Detected Person

struct DetectedPerson: Identifiable {

    let id = UUID()

    let personIndex: Int

    let joints:
        [VNHumanBodyPoseObservation.JointName: CGPoint]

    let jointList: [JointPoint]

    var role: PlayerRole {

        switch personIndex {

        case 0:
            return .upperBody

        case 1:
            return .lowerBody

        default:
            return .fullBody
        }
    }

    var activeConnections:
        [(VNHumanBodyPoseObservation.JointName,
          VNHumanBodyPoseObservation.JointName)] {

        role.connections
    }

    var filteredJointList: [JointPoint] {

        let allowedJoints =
            role.relevantJoints

        return jointList.filter {
            allowedJoints.contains($0.name)
        }
    }
}

// MARK: - Pose Model

struct PoseModel {

    var detectedPeople:
        [DetectedPerson] = []

    // LANDSCAPE 1920 x 1080

    var videoSize:
        CGSize = CGSize(
            width: 1920,
            height: 1080
        )
}
