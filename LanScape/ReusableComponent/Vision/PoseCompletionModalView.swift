import SwiftUI

/// Celebration modal presented when all dance moves in the sequence have been completed.
struct PoseCompletionModalView: View {
    let onRestart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Trophy / Celebration Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.orange.opacity(0.6), radius: 12, x: 0, y: 6)

                    Image(systemName: "star.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Hebat Sekali!")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Semua gerakan berhasil diselesaikan dengan baik.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    Button(action: onRestart) {
                        Text("Ulangi Gerakan")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                    }

                    Button(action: onDismiss) {
                        Text("Kembali")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
            )
            .frame(maxWidth: 520)
            .padding(24)
        }
    }
}

// MARK: - Preview
#Preview("Pose Completion Modal") {
    PoseCompletionModalView(
        onRestart: {},
        onDismiss: {}
    )
    .previewInterfaceOrientation(.landscapeRight)
}
