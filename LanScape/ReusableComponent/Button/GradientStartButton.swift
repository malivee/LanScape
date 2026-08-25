import SwiftUI

struct GradientStartButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan], 
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview("Start Button") {
    GradientStartButton(title: "Mulai", action: {})
        .padding()
}
