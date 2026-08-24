import SwiftUI
import Vision

struct PoseTrackingView: View {
    @StateObject private var visionService = VisionService()
    
    private func convertPoint(_ point: CGPoint, viewSize: CGSize, videoSize: CGSize) -> CGPoint {
        let vWidth: CGFloat = videoSize.width > 0 ? videoSize.width : 1080
        let vHeight: CGFloat = videoSize.height > 0 ? videoSize.height : 1920
        
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
            // Camera feed (Native AVCaptureVideoPreviewLayer with UIViewControllerRepresentable)
            CameraPreviewView(session: visionService.captureSession)
                .ignoresSafeArea()
            
            // Skeleton & Joint Overlay
            GeometryReader { geometry in
                let viewSize = geometry.size
                let videoSize = visionService.poseModel.videoSize
                
                ForEach(visionService.poseModel.detectedPeople) { person in
                    let playerColor = visionService.isMatching ? Color.green : person.role.primaryColor
                    
                    // Skeleton Lines
                    Path { path in
                        for (startJoint, endJoint) in person.activeConnections {
                            if let startNorm = person.joints[startJoint],
                               let endNorm = person.joints[endJoint] {
                                let startPoint = convertPoint(startNorm, viewSize: viewSize, videoSize: videoSize)
                                let endPoint = convertPoint(endNorm, viewSize: viewSize, videoSize: videoSize)
                                
                                path.move(to: startPoint)
                                path.addLine(to: endPoint)
                            }
                        }
                    }
                    .stroke(playerColor, style: StrokeStyle(lineWidth: visionService.isMatching ? 6 : 4, lineCap: .round, lineJoin: .round))
                    .shadow(color: playerColor.opacity(0.8), radius: 5)
                    
                    // Joint Keypoints
                    ForEach(person.filteredJointList) { joint in
                        let screenPoint = convertPoint(joint.location, viewSize: viewSize, videoSize: videoSize)
                        
                        Circle()
                            .fill(playerColor)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: playerColor.opacity(0.8), radius: 4)
                            .position(screenPoint)
                    }
                    
                    // Floating Player Tag
                    if let anchorNorm = person.role == .upperBody ? (person.joints[.neck] ?? person.joints[.nose]) : (person.joints[.root] ?? person.joints[.leftHip]) {
                        let anchorPoint = convertPoint(anchorNorm, viewSize: viewSize, videoSize: videoSize)
                        
                        Text(person.role == .upperBody ? "P1: UPPER" : "P2: LOWER")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(playerColor.opacity(0.85))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 3)
                            .position(x: anchorPoint.x, y: max(anchorPoint.y - 30, 25))
                    }
                }
            }
            .ignoresSafeArea()
            
            // Top HUD Dashboard (Landscape Optimized)
            VStack {
                HStack(alignment: .center, spacing: 12) {
                    // Player 1 Badge
                    playerPill(
                        title: "P1: Upper Body",
                        color: .cyan,
                        isDetected: visionService.poseModel.detectedPeople.contains { $0.personIndex == 0 }
                    )
                    
                    Spacer()
                    
                    // Center Model Match / Difference Status Card
                    matchStatusCard()
                    
                    Spacer()
                    
                    // Player 2 Badge
                    playerPill(
                        title: "P2: Lower Body",
                        color: .green,
                        isDetected: visionService.poseModel.detectedPeople.contains { $0.personIndex == 1 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
            }
        }
        .onAppear {
            visionService.startSession()
        }
        .onDisappear {
            visionService.stopSession()
        }
    }
    
    @ViewBuilder
    private func matchStatusCard() -> some View {
        if visionService.isMatching {
            // MATCH / BENAR State
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .black))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("BENAR / MATCH!")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("Pose: \(visionService.prediction) (\(Int(visionService.confidence * 100))%)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule().stroke(Color.green.opacity(0.8), lineWidth: 1.5)
            )
            .shadow(color: Color.green.opacity(0.5), radius: 6)
        } else if visionService.prediction != "?" {
            // NOT MATCHING / BEDA State
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .bold))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("BEDA / TIDAK COCOK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("Deteksi: \(visionService.prediction) (Target: \(visionService.targetPose))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule().stroke(Color.orange.opacity(0.6), lineWidth: 1)
            )
        } else {
            // STANDBY / MENUNGGU
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 7, height: 7)
                
                Text("Target: \(visionService.targetPose)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private func playerPill(title: String, color: Color, isDetected: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isDetected ? color : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .shadow(color: isDetected ? color.opacity(0.9) : .clear, radius: 4)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            if isDetected {
                Text("•")
                    .foregroundColor(color)
                    .font(.system(size: 10, weight: .black))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(
            Capsule()
                .stroke(isDetected ? color.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    PoseTrackingView()
}
