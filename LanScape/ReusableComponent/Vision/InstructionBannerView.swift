import SwiftUI

/// Floating text banner providing clear instructions to the user.
struct InstructionBannerView: View {
    let text: String
    var isSuccess: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.8), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                isSuccess
                ? Color.green.opacity(0.35)
                : Color.black.opacity(0.25)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSuccess ? Color.green : Color.white.opacity(0.2),
                        lineWidth: 1.5
                    )
            )
            .animation(.easeInOut(duration: 0.3), value: isSuccess)
    }
}

// MARK: - Preview
#Preview("Instruction Banner") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack(spacing: 20) {
            InstructionBannerView(text: "Ikuti gerakannya", isSuccess: false)
            InstructionBannerView(text: "Bagus! Gerakan Cocok!", isSuccess: true)
        }
    }
}
