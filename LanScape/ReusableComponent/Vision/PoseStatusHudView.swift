import SwiftUI

/// Heads-Up-Display showing Player 1 and Player 2 connection status
/// along with real-time Core ML detection feedback (Predicted Pose vs Target Pose + Confidence).
struct PoseStatusHudView: View {
    let isP1Detected: Bool
    let isP2Detected: Bool
    let isMatching: Bool
    let prediction: String
    let targetPose: String
    let confidence: Double

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Player 1 Pill
            playerPill(title: "P1: Upper Body", color: .yellow, isDetected: isP1Detected)

            Spacer()

            // Real-Time Match & Detection Feedback Badge
            detectionBadge

            Spacer()

            // Player 2 Pill
            playerPill(title: "P2: Lower Body", color: .blue, isDetected: isP2Detected)
        }
        .padding(.horizontal, 24)
    }

    private var detectionBadge: some View {
        HStack(spacing: 8) {
            if isMatching {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .black))

                Text("COCOK! (\(Int(confidence * 100))%)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            } else {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)

                Text("Deteksi: \(prediction.replacingOccurrences(of: "Label ", with: "Pose ")) (\(Int(confidence * 100))%) • Target: Pose \(targetPose)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            isMatching ? Color.black.opacity(0.7) : Color.black.opacity(0.5)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isMatching ? Color.green.opacity(0.8) : Color.white.opacity(0.2),
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isMatching)
    }

    private func playerPill(title: String, color: Color, isDetected: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isDetected ? color : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .shadow(color: isDetected ? color.opacity(0.8) : .clear, radius: 4)

            Text(title)
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
#Preview("Pose Status HUD — Matched") {
    ZStack {
        Color.black.ignoresSafeArea()
        PoseStatusHudView(
            isP1Detected: true,
            isP2Detected: false,
            isMatching: true,
            prediction: "1",
            targetPose: "1",
            confidence: 0.92
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}

#Preview("Pose Status HUD — Detecting") {
    ZStack {
        Color.black.ignoresSafeArea()
        PoseStatusHudView(
            isP1Detected: true,
            isP2Detected: false,
            isMatching: false,
            prediction: "1",
            targetPose: "2",
            confidence: 0.65
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}
