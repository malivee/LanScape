import SwiftUI
import Vision

/// Draws real-time skeleton overlay lines and joint dots on top of the camera feed.
/// - Player 1 (Upper Body): Head, arms, hands, and upper torso in yellow/green.
/// - Player 2 (Lower Body): Hips, legs, knees, and ankles in blue/green.
struct PoseSkeletonOverlayView: View {
    let detectedPeople: [DetectedPerson]
    let videoSize: CGSize
    let isMatching: Bool

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            ForEach(detectedPeople) { person in
                let playerColor = isMatching ? Color.green : person.role.primaryColor
                let allowedJoints = person.role.relevantJoints

                // MARK: - Skeleton Lines
                Path { path in
                    for (startJoint, endJoint) in person.activeConnections {
                        guard
                            allowedJoints.contains(startJoint),
                            allowedJoints.contains(endJoint),
                            let startNorm = person.joints[startJoint],
                            let endNorm = person.joints[endJoint]
                        else {
                            continue
                        }

                        let startPoint = convertPoint(startNorm, viewSize: viewSize, videoSize: videoSize)
                        let endPoint = convertPoint(endNorm, viewSize: viewSize, videoSize: videoSize)

                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                }
                .stroke(
                    playerColor,
                    style: StrokeStyle(
                        lineWidth: isMatching ? 6 : 4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .shadow(color: playerColor.opacity(0.8), radius: 5)

                // MARK: - Joint Circles
                ForEach(person.filteredJointList) { joint in
                    let screenPoint = convertPoint(joint.location, viewSize: viewSize, videoSize: videoSize)

                    Circle()
                        .fill(playerColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: playerColor.opacity(0.8), radius: 4)
                        .position(screenPoint)
                }

                // MARK: - Player Floating Label Pill
                if let anchorNorm = person.role == .upperBody
                    ? (person.joints[.neck] ?? person.joints[.nose])
                    : (person.joints[.root] ?? person.joints[.leftHip]) {

                    let anchorPoint = convertPoint(anchorNorm, viewSize: viewSize, videoSize: videoSize)

                    Text(person.role == .upperBody ? "P1: UPPER" : "P2: LOWER")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(playerColor.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3)
                        .position(
                            x: anchorPoint.x,
                            y: max(anchorPoint.y - 30, 25)
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Point Conversion
    private func convertPoint(
        _ point: CGPoint,
        viewSize: CGSize,
        videoSize: CGSize
    ) -> CGPoint {
        let videoWidth: CGFloat = videoSize.width > 0 ? videoSize.width : 1920
        let videoHeight: CGFloat = videoSize.height > 0 ? videoSize.height : 1080

        let videoAspect = videoWidth / videoHeight
        let viewAspect = viewSize.width / viewSize.height

        let scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if viewAspect > videoAspect {
            scale = viewSize.width / videoWidth
            let renderedHeight = videoHeight * scale
            offsetY = (viewSize.height - renderedHeight) / 2.0
        } else {
            scale = viewSize.height / videoHeight
            let renderedWidth = videoWidth * scale
            offsetX = (viewSize.width - renderedWidth) / 2.0
        }

        // Camera Preview is mirrored horizontally for the front camera
        let mirroredX = 1.0 - point.x
        let x = mirroredX * videoWidth * scale + offsetX
        let y = point.y * videoHeight * scale + offsetY

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview
#Preview("Pose Skeleton Overlay") {
    ZStack {
        Color.black.ignoresSafeArea()
        PoseSkeletonOverlayView(
            detectedPeople: [],
            videoSize: CGSize(width: 1920, height: 1080),
            isMatching: false
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}
