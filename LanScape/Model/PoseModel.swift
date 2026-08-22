import Foundation
import CoreGraphics
import Vision

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
}

struct PoseModel {
    var detectedPeople: [DetectedPerson] = []
    var videoSize: CGSize = CGSize(width: 1080, height: 1920)
}
