import SwiftUI

/// A vertical center divider line splitting the camera screen into
/// Player 1 (Left / Upper Body) and Player 2 (Right / Lower Body).
struct CenterDividerLineView: View {
    var lineColor: Color = Color.black.opacity(0.85)
    var lineWidth: CGFloat = 4

    var body: some View {
        Rectangle()
            .fill(lineColor)
            .frame(width: lineWidth)
            .frame(maxHeight: .infinity)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
    }
}

// MARK: - Preview
#Preview("Center Divider Line") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        CenterDividerLineView()
    }
}
