import SwiftUI

struct GradientStartButton: View {
    let title: String
    
    var fontSize: CGFloat = 22
    var fontWeight: Font.Weight = .bold
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.gradient1, .gradient2, .gradient3],
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
    GradientStartButton(title: "Mulai", fontSize: 22, fontWeight: .bold, action: {})
        .padding()
}
