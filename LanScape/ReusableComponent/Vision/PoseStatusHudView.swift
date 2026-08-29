import SwiftUI

/// Heads-Up-Display showing Player 1 and Player 2 connection status and detected joint counts.
struct PoseStatusHudView: View {
    let p1JointCount: Int
    let p2JointCount: Int
    let isP1Detected: Bool
    let isP2Detected: Bool

    init(
        p1JointCount: Int = 0,
        p2JointCount: Int = 0,
        isP1Detected: Bool = false,
        isP2Detected: Bool = false
    ) {
        self.p1JointCount = p1JointCount
        self.p2JointCount = p2JointCount
        self.isP1Detected = isP1Detected
        self.isP2Detected = isP2Detected
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Player 1 Pill
            playerPill(
                title: "Orang 1",
                jointCount: p1JointCount,
                color: Color(hex: "FFD84D"),
                isDetected: isP1Detected
            )

            Spacer()

            // Center Tracking Badge
            centerBadge

            Spacer()

            // Player 2 Pill
            playerPill(
                title: "Orang 2",
                jointCount: p2JointCount,
                color: Color(hex: "00D2FF"),
                isDetected: isP2Detected
            )
        }
        .padding(.horizontal, 24)
    }

    private var centerBadge: some View {
        let totalJoints = (isP1Detected ? p1JointCount : 0) + (isP2Detected ? p2JointCount : 0)
        let isFullyTracked = isP1Detected && isP2Detected && totalJoints == 8

        return HStack(spacing: 8) {
            Circle()
                .fill(isFullyTracked ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text("Tracking: \(totalJoints)/8 Joints")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isFullyTracked ? Color.green.opacity(0.8) : Color.white.opacity(0.2),
                    lineWidth: 1.5
                )
        )
    }

    private func playerPill(
        title: String,
        jointCount: Int,
        color: Color,
        isDetected: Bool
    ) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isDetected ? color : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .shadow(color: isDetected ? color.opacity(0.8) : .clear, radius: 4)

            Text(isDetected ? "\(title) (\(jointCount)/4)" : "\(title) (Mencari...)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isDetected ? color.opacity(0.7) : Color.white.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview
#Preview("Pose Status HUD") {
    ZStack {
        Color.black.ignoresSafeArea()
        PoseStatusHudView(
            p1JointCount: 4,
            p2JointCount: 4,
            isP1Detected: true,
            isP2Detected: true
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}
