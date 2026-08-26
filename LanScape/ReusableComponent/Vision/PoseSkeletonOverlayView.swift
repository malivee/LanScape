import SwiftUI
import Vision

/// Draws real-time 8-joint tracking indicators (4 distinct colored joints per player):
///
/// Person 1 (Yellow Palette):
/// - Right Wrist: #FFD84D
/// - Left Wrist: #FFF066
/// - Right Leg: #FFC13D
/// - Left Leg: #C6FF4D
///
/// Person 2 (Blue Palette):
/// - Right Wrist: #0088FF
/// - Left Wrist: #33E0FF
/// - Right Leg: #5A6BFF
/// - Left Leg: #8A5CFF
struct PoseSkeletonOverlayView: View {
    let detectedPeople: [DetectedPerson]
    let videoSize: CGSize
    var isMatching: Bool = false

    private let jointSize: CGFloat = 46

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            ForEach(detectedPeople) { person in
                let playerPrimary = person.role.primaryColor

                // MARK: - 4 Distinctly Colored Joint Dots
                ForEach(person.filteredJointList) { joint in
                    let screenPoint = convertPoint(joint.location, viewSize: viewSize, videoSize: videoSize)
                    let jointColor = person.jointColor(for: joint.name)

                    ZStack {
                        // 1. Ambient Outer Colored Glow
                        Circle()
                            .fill(jointColor)
                            .frame(width: jointSize * 1.45, height: jointSize * 1.45)
                            .blur(radius: jointSize * 0.28)
                            .opacity(0.9)

                        // 2. Vibrant Outer Ring
                        Circle()
                            .fill(jointColor)
                            .frame(width: jointSize, height: jointSize)
                            .shadow(color: jointColor.opacity(0.85), radius: jointSize * 0.15)

                        // 3. Inner Contrast Ring
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: jointSize * 0.08)
                            .frame(width: jointSize * 0.78, height: jointSize * 0.78)

                        // 4. Glowing White Center Core
                        Circle()
                            .fill(Color.white)
                            .frame(width: jointSize * 0.54, height: jointSize * 0.54)
                            .shadow(color: Color.white.opacity(0.95), radius: jointSize * 0.08)

                        // 5. Joint Name Tag
                        Text(joint.displayName)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(jointColor.opacity(0.9), lineWidth: 1.2)
                            )
                            .shadow(color: Color.black.opacity(0.4), radius: 3)
                            .offset(y: jointSize * 0.55 + 12)
                    }
                    .position(screenPoint)
                }

                // MARK: - Player Floating Header Pill
                if let anchorPoint = anchorForPerson(person, viewSize: viewSize, videoSize: videoSize) {
                    let jointCount = person.filteredJointList.count

                    HStack(spacing: 6) {
                        Circle()
                            .fill(playerPrimary)
                            .frame(width: 8, height: 8)

                        Text("\(person.role.title) • \(jointCount)/4")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(playerPrimary.opacity(0.85), lineWidth: 1.5)
                    )
                    .shadow(color: playerPrimary.opacity(0.45), radius: 6)
                    .position(
                        x: anchorPoint.x,
                        y: max(anchorPoint.y - 45, 32)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Anchor Calculation
    private func anchorForPerson(
        _ person: DetectedPerson,
        viewSize: CGSize,
        videoSize: CGSize
    ) -> CGPoint? {
        let points = person.filteredJointList.map {
            convertPoint($0.location, viewSize: viewSize, videoSize: videoSize)
        }
        guard !points.isEmpty else { return nil }

        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0

        return CGPoint(x: (minX + maxX) / 2.0, y: minY)
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

        // Camera preview is mirrored horizontally for front camera
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
            videoSize: CGSize(width: 1920, height: 1080)
        )
    }
    .previewInterfaceOrientation(.landscapeLeft)
}
