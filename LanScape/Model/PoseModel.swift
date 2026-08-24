import Foundation
import CoreGraphics
import Vision
import SwiftUI

public enum PlayerRole: String, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    case fullBody = "Full Body"
    
    public var title: String {
        switch self {
        case .upperBody: return "Player 1: Upper Body"
        case .lowerBody: return "Player 2: Lower Body"
        case .fullBody: return "Full Body"
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .upperBody: return .cyan
        case .lowerBody: return .green
        case .fullBody: return .yellow
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

public struct PoseBodyDefinitions {
    /* ini buat yang upper body
     separatornya ada disini*/
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
    
    public static let lowerBodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]
    
    
    public static let coreConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip)
    ]
    
    public static var allConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        upperBodyConnections + lowerBodyConnections + coreConnections
    }
    
    public static let upperBodyJoints: Set<VNHumanBodyPoseObservation.JointName> = [
        .nose, .neck, .leftEye, .rightEye, .leftEar, .rightEar,
        .leftShoulder, .rightShoulder, .root,
        .leftElbow, .leftWrist, .rightElbow, .rightWrist
    ]
    
    public static let lowerBodyJoints: Set<VNHumanBodyPoseObservation.JointName> = [
        .leftHip, .rightHip,
        .leftKnee, .rightKnee,
        .leftAnkle, .rightAnkle
    ]
    
    public static var allJoints: Set<VNHumanBodyPoseObservation.JointName> {
        upperBodyJoints.union(lowerBodyJoints)
    }
}

struct JointPoint: Identifiable {
    let id = UUID()
    let name: VNHumanBodyPoseObservation.JointName
    let location: CGPoint
    let confidence: Float
}

struct DetectedPerson: Identifiable {
    let id = UUID()
    let personIndex: Int
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
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
    
    var activeConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        return role.connections
    }
    
    var filteredJointList: [JointPoint] {
        let allowedJoints = role.relevantJoints
        return jointList.filter { allowedJoints.contains($0.name) }
    }
}

struct PoseModel {
    var detectedPeople: [DetectedPerson] = []
    var videoSize: CGSize = CGSize(width: 1080, height: 1920)
}

