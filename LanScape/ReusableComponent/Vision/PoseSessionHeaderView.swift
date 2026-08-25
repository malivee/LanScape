import SwiftUI

/// Top navigation and progress header for the pose tracking session.
/// Features a pause/dismiss button on the left and a continuous progress indicator bar.
struct PoseSessionHeaderView: View {
    let currentStepIndex: Int
    let totalSteps: Int
    let onPause: () -> Void

    private var progressRatio: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(totalSteps)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Pause / Exit Button
            Button(action: onPause) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)

                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            // Step Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)

                    // Active progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progressRatio), height: 8)
                        .animation(.easeInOut(duration: 0.4), value: progressRatio)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 24)

            // Step Badge
            Text("\(currentStepIndex + 1)/\(totalSteps)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

// MARK: - Preview
#Preview("Pose Session Header") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            PoseSessionHeaderView(
                currentStepIndex: 1,
                totalSteps: 4,
                onPause: {}
            )
            Spacer()
        }
    }
}
