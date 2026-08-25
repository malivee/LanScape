import SwiftUI

/// Overlay displaying the target movement silhouettes.
/// - Unmatched: Player 1 (Upper) is on the bottom-left; Player 2 (Lower) is on the bottom-right.
/// - Matched: Both figures glide to the center and merge into a single united dancing figure with a highlight card.
struct PoseGuideOverlayView: View {
    let step: PoseStep
    let isMatching: Bool

    // Figure image heights
    private let figureHeight: CGFloat = 160
    private let combinedFigureHeight: CGFloat = 125

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            let bottomPadding: CGFloat = 40

            ZStack {
                // =====================================================
                // CENTER MERGED CARD (Visible when Matching)
                // =====================================================
                if isMatching {
                    mergedCenterCard
                        .position(
                            x: totalWidth / 2,
                            y: totalHeight - 160 - bottomPadding
                        )
                        .transition(.scale.combined(with: .opacity))
                }

                // =====================================================
                // SEPARATED FIGURES (Glides to Center when Matching)
                // =====================================================
                if !isMatching {
                    // Left: Upper Body (Player 1)
                    Image(step.upImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: figureHeight)
                        .shadow(color: Color.yellow.opacity(0.6), radius: 8, x: 0, y: 0)
                        .position(
                            x: totalWidth * 0.16,
                            y: totalHeight - figureHeight / 2 - bottomPadding
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    // Right: Lower Body (Player 2)
                    Image(step.downImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: figureHeight)
                        .shadow(color: Color.blue.opacity(0.6), radius: 8, x: 0, y: 0)
                        .position(
                            x: totalWidth * 0.84,
                            y: totalHeight - figureHeight / 2 - bottomPadding
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.72), value: isMatching)
        }
    }

    // MARK: - Merged Center Card
    private var mergedCenterCard: some View {
        ZStack {
            // Highlight background container
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.22))
                .frame(width: 190, height: 260)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.9), Color.green.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: Color.green.opacity(0.5), radius: 16, x: 0, y: 0)

            // Combined figures (Upper on top, Lower below)
            VStack(spacing: -18) {
                Image(step.upImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: combinedFigureHeight)
                    .shadow(color: Color.yellow.opacity(0.8), radius: 6)

                Image(step.downImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: combinedFigureHeight)
                    .shadow(color: Color.blue.opacity(0.8), radius: 6)
            }
            .scaleEffect(1.05)
        }
    }
}

// MARK: - Preview
#Preview("Pose Guide Overlay — Unmatched") {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        PoseGuideOverlayView(
            step: PoseStep.sampleSequence[0],
            isMatching: false
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}

#Preview("Pose Guide Overlay — Matched") {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        PoseGuideOverlayView(
            step: PoseStep.sampleSequence[0],
            isMatching: true
        )
    }
    .previewInterfaceOrientation(.landscapeRight)
}
