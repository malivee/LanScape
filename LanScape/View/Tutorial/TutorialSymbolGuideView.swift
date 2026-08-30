//
//  TutorialSymbolGuideView.swift
//  LanScape
//

import SwiftUI

struct TutorialSymbolGuideView: View {
    var onNext: (() -> Void)? = nil

    @State private var isOverlayVisible: Bool = true

    var body: some View {
        ZStack {
            // MARK: - Main Content
            VStack(spacing: 28) {
                Text("Petunjuk Simbol dan Warna")
                    .font(.system(size: 44, weight: .bold))
                
                // players cards
                HStack(spacing: 32) {
                    // Person 1
                    playerGuideCard(
                        playerTitle: "Orang 1",
                        badgeColor: Color(hex: "FFD84D"),
                        badgeTextColor: .black,
                        leftHandColor: Color(hex: "FFE75B"),
                        rightHandColor: Color(hex: "FF0000"),
                        leftLegColor: Color(hex: "FFE75B"),
                        rightLegColor: Color(hex: "FF0000")
                    )
                    
                    // Person 2
                    playerGuideCard(
                        playerTitle: "Orang 2",
                        badgeColor: Color(hex: "00D2FF"),
                        badgeTextColor: .black,
                        leftHandColor: Color(hex: "33E0FF"),
                        rightHandColor: Color(hex: "01FF00"),
                        leftLegColor: Color(hex: "33E0FF"),
                        rightLegColor: Color(hex: "01FF00")
                    )
                }
                .padding(.horizontal, 36)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // overlay dismissed, next page
                guard !isOverlayVisible else { return }
                onNext?()
            }
            
            // MARK: - "Tap to Continue" Overlay
            if isOverlayVisible {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay(
                        HStack(spacing: 8) {
                            Text("Sentuh layar untuk lanjut")
                                .font(.system(size: 28, weight: .bold))
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 24, weight: .semibold))
                        }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .shadow(color: .white.opacity(0.5), radius: 8)
                            .padding(.top, 400)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.35)) {
                            isOverlayVisible = false
                        }
                    }
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Individual Player Guide Card
    @ViewBuilder
    private func playerGuideCard(
        playerTitle: String,
        badgeColor: Color,
        badgeTextColor: Color,
        leftHandColor: Color,
        rightHandColor: Color,
        leftLegColor: Color,
        rightLegColor: Color
    ) -> some View {
        ZStack(alignment: .top) {
            // Card Container
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.gray.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 0)

            VStack(spacing: 4) {
                // Badge Title
                Text(playerTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(badgeTextColor)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 10)
                    .background(badgeColor)
                    .clipShape(Capsule())
                    .padding(.top, 16)

                // Standing figure overlay container showing joint circles and squares
                figureContainer(
                    leftHandColor: leftHandColor,
                    rightHandColor: rightHandColor,
                    leftLegColor: leftLegColor,
                    rightLegColor: rightLegColor
                )
                .frame(height: 260)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Figure Container with Glow Rings and Labels
    @ViewBuilder
    private func figureContainer(
        leftHandColor: Color,
        rightHandColor: Color,
        leftLegColor: Color,
        rightLegColor: Color
    ) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Image("sittingGuide")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 600)
                    .position(x: w * 0.5, y: h * 1.2)

                Text("Kiri")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(white: 0.25))
                    .position(x: w * 0.12, y: h * 1)

                Text("Kanan")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(white: 0.25))
                    .position(x: w * 0.86, y: h * 1)

                // Left Hand
                circleJointIndicator(color: leftHandColor, size: 65)
                    .position(x: w * 0.44, y: h * 1.34)

                // Right Hand
                circleJointIndicator(color: rightHandColor, size: 65)
                    .position(x: w * 0.54, y: h * 1.34)

                // Left Leg
                squareJointIndicator(color: leftLegColor, size: 65)
                    .position(x: w * 0.32, y: h * 2.2)

                // Right Leg
                squareJointIndicator(color: rightLegColor, size: 65)
                    .position(x: w * 0.68, y: h * 2.2)
            }
        }
    }

    // MARK: - Circle Joint Indicator (Hands) - Dual Stacked Radial Gradient
    @ViewBuilder
    private func circleJointIndicator(color: Color, size: CGFloat) -> some View {
        ZStack {
            // Outer Ring Circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            color.opacity(0.6),
                            color
                        ],
                        center: .center,
                        startRadius: size * 0.35,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)

            // Inner Circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.7),
                            color
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.33
                    )
                )
                .frame(width: size * 0.66, height: size * 0.66)
        }
    }

    // MARK: - Square Joint Indicator (Legs) - Dual Stacked Radial Gradient
    @ViewBuilder
    private func squareJointIndicator(color: Color, size: CGFloat) -> some View {
        ZStack {
            // kotak luar
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            color.opacity(0.6),
                            color
                        ],
                        center: .center,
                        startRadius: size * 0.35,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)

            // kotak dalem
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.6),
                            color
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.33
                    )
                )
                .frame(width: size * 0.66, height: size * 0.66)
        }
    }
}

// MARK: - Preview
#Preview("Tutorial Symbol Guide") {
    TutorialSymbolGuideView()
        .previewInterfaceOrientation(.landscapeLeft)
}
