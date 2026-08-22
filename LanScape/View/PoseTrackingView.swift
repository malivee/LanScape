import SwiftUI
import Vision

struct PoseTrackingView: View {
    @StateObject private var visionService = VisionService()
    
    private let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.nose, .leftEye),
        (.nose, .rightEye),
        (.leftEye, .leftEar),
        (.rightEye, .rightEar),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.neck, .root),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]
    
    private func convertPoint(_ point: CGPoint, viewSize: CGSize, videoSize: CGSize = CGSize(width: 1080, height: 1920)) -> CGPoint {
        let vWidth: CGFloat = 1080
        let vHeight: CGFloat = 1920
        
        let videoAspect = vWidth / vHeight
        let viewAspect = viewSize.width / viewSize.height
        
        let scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        if viewAspect > videoAspect {
            scale = viewSize.width / vWidth
            let renderedHeight = vHeight * scale
            offsetY = (viewSize.height - renderedHeight) / 2.0
        } else {
            scale = viewSize.height / vHeight
            let renderedWidth = vWidth * scale
            offsetX = (viewSize.width - renderedWidth) / 2.0
        }
        
        let x = point.x * vWidth * scale + offsetX
        let y = point.y * vHeight * scale + offsetY
        
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: visionService.captureSession)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                let viewSize = geometry.size
                
                ForEach(visionService.poseModel.detectedPeople) { person in
                    Path { path in
                        for (startJoint, endJoint) in bodyConnections {
                            if let startNorm = person.joints[startJoint],
                               let endNorm = person.joints[endJoint] {
                                let startPoint = convertPoint(startNorm, viewSize: viewSize)
                                let endPoint = convertPoint(endNorm, viewSize: viewSize)
                                
                                path.move(to: startPoint)
                                path.addLine(to: endPoint)
                            }
                        }
                    }
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    
                    ForEach(person.jointList) { joint in
                        let screenPoint = convertPoint(joint.location, viewSize: viewSize)
                        
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .position(screenPoint)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            visionService.startSession()
        }
        .onDisappear {
            visionService.stopSession()
        }
    }
}

#Preview {
    PoseTrackingView()
}
