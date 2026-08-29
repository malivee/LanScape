//
//  TutorialSymbolGuideView.swift
//  LanScape
//

import SwiftUI

struct TutorialSymbolGuideView: View {
    var onNext: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 10) {
                // MARK: - Top Header
                HStack {
                    Text("Tutorial #2")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("Perhatikan simbol dan warna")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text("Tutorial #2")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 40)
                .padding(.top, 14)

                Spacer()

                // MARK: - Main White Modal Card
                mainModalCard
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onNext?()
        }
    }

    // MARK: - Main Modal Card
    private var mainModalCard: some View {
        VStack(spacing: 12) {
            // Title
            Text("Petunjuk Simbol dan Warna")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.top, 4)

            // 2 Side-by-Side Cards
            HStack(spacing: 16) {
                // Orang 1 Card
                playerGuideCard(
                    playerTitle: "Orang 1",
                    badgeColor: Color(hex: "FFD84D"),
                    badgeTextColor: .black,
                    borderColor: Color(hex: "4D70FF"),
                    leftHandColor: Color(hex: "FF3B30"),
                    rightHandColor: Color(hex: "FFD84D"),
                    leftLegColor: Color(hex: "FF3B30"),
                    rightLegColor: Color(hex: "FFD84D")
                )

                // Orang 2 Card
                playerGuideCard(
                    playerTitle: "Orang 2",
                    badgeColor: Color(hex: "00D2FF"),
                    badgeTextColor: .black,
                    borderColor: Color.gray.opacity(0.25),
                    leftHandColor: Color(hex: "34C759"),
                    rightHandColor: Color(hex: "00D2FF"),
                    leftLegColor: Color(hex: "34C759"),
                    rightLegColor: Color(hex: "00D2FF")
                )
            }
            .padding(.horizontal, 8)

            // Bottom Prompt Pill ("Sentuh layar untuk lanjut")
            Button(action: {
                onNext?()
            }) {
                HStack(spacing: 6) {
                    Text("Sentuh layar untuk lanjut")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "1E4BA3"))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(hex: "F0F4FF"))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(hex: "1E4BA3").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.bottom, 2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        )
        .frame(maxWidth: 820)
    }

    // MARK: - Individual Player Guide Card
    @ViewBuilder
    private func playerGuideCard(
        playerTitle: String,
        badgeColor: Color,
        badgeTextColor: Color,
        borderColor: Color,
        leftHandColor: Color,
        rightHandColor: Color,
        leftLegColor: Color,
        rightLegColor: Color
    ) -> some View {
        ZStack(alignment: .top) {
            // Card background & border
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 2.5)
                )

            VStack(spacing: 4) {
                // Top Badge Pill
                Text(playerTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(badgeTextColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .background(badgeColor)
                    .clipShape(Capsule())
                    .padding(.top, 8)

                // Standing Figure with Indicator Overlays
                figureContainer(
                    leftHandColor: leftHandColor,
                    rightHandColor: rightHandColor,
                    leftLegColor: leftLegColor,
                    rightLegColor: rightLegColor
                )
                .frame(height: 270)
                .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity)
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
                // 1. Standing Person Image
                Image("standingGuide")
                    .resizable()
                    .scaledToFit()
                    .frame(height: h * 0.95)
                    .position(x: w * 0.5, y: h * 0.5)

                // 2. Faint Skeleton Overlay Lines
                skeletonOverlayLines(width: w, height: h)

                // 3. Side Labels: "Kiri" & "Kanan"
                Text("Kiri")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(white: 0.25))
                    .position(x: w * 0.12, y: h * 0.58)

                Text("Kanan")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(white: 0.25))
                    .position(x: w * 0.88, y: h * 0.58)

                // 4. Hand Indicators (Circles)
                // Left Hand (viewer's left)
                circleJointIndicator(color: leftHandColor, size: 34)
                    .position(x: w * 0.29, y: h * 0.58)

                // Right Hand (viewer's right)
                circleJointIndicator(color: rightHandColor, size: 34)
                    .position(x: w * 0.71, y: h * 0.58)

                // 5. Leg Indicators (Squares)
                // Left Leg (viewer's left)
                squareJointIndicator(color: leftLegColor, size: 34)
                    .position(x: w * 0.36, y: h * 0.90)

                // Right Leg (viewer's right)
                squareJointIndicator(color: rightLegColor, size: 34)
                    .position(x: w * 0.64, y: h * 0.90)
            }
        }
    }

    // MARK: - Circle Joint Indicator (Hands)
    @ViewBuilder
    private func circleJointIndicator(color: Color, size: CGFloat) -> some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 4)

            // Stroke ring
            Circle()
                .stroke(color, lineWidth: 3.5)
                .frame(width: size, height: size)

            // Inner translucent white center
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: size * 0.65, height: size * 0.65)
                .shadow(color: Color.white, radius: 4)
        }
    }

    // MARK: - Square Joint Indicator (Legs)
    @ViewBuilder
    private func squareJointIndicator(color: Color, size: CGFloat) -> some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.35))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 4)

            // Stroke rounded square
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: 3.5)
                .frame(width: size, height: size)

            // Inner translucent white center
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.65))
                .frame(width: size * 0.65, height: size * 0.65)
                .shadow(color: Color.white, radius: 4)
        }
    }

    // MARK: - Faint Skeleton Overlay Lines
    private func skeletonOverlayLines(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let head = CGPoint(x: width * 0.50, y: height * 0.14)
            let neck = CGPoint(x: width * 0.50, y: height * 0.24)
            let lShoulder = CGPoint(x: width * 0.38, y: height * 0.27)
            let rShoulder = CGPoint(x: width * 0.62, y: height * 0.27)

            let lElbow = CGPoint(x: width * 0.34, y: height * 0.42)
            let rElbow = CGPoint(x: width * 0.66, y: height * 0.42)

            let lWrist = CGPoint(x: width * 0.29, y: height * 0.58)
            let rWrist = CGPoint(x: width * 0.71, y: height * 0.58)

            let midSpine = CGPoint(x: width * 0.50, y: height * 0.42)
            let lHip = CGPoint(x: width * 0.42, y: height * 0.53)
            let rHip = CGPoint(x: width * 0.58, y: height * 0.53)

            let lKnee = CGPoint(x: width * 0.40, y: height * 0.72)
            let rKnee = CGPoint(x: width * 0.60, y: height * 0.72)

            let lAnkle = CGPoint(x: width * 0.36, y: height * 0.90)
            let rAnkle = CGPoint(x: width * 0.64, y: height * 0.90)

            // Neck to shoulders
            path.move(to: head)
            path.addLine(to: neck)

            // Torso box
            path.move(to: lShoulder)
            path.addLine(to: rShoulder)
            path.addLine(to: rHip)
            path.addLine(to: lHip)
            path.closeSubpath()

            // Spine
            path.move(to: neck)
            path.addLine(to: midSpine)

            // Left arm
            path.move(to: lShoulder)
            path.addLine(to: lElbow)
            path.addLine(to: lWrist)

            // Right arm
            path.move(to: rShoulder)
            path.addLine(to: rElbow)
            path.addLine(to: rWrist)

            // Left leg
            path.move(to: lHip)
            path.addLine(to: lKnee)
            path.addLine(to: lAnkle)

            // Right leg
            path.move(to: rHip)
            path.addLine(to: rKnee)
            path.addLine(to: rAnkle)
        }
        .stroke(Color.white.opacity(0.65), lineWidth: 1.8)
    }
}

// MARK: - Preview
#Preview("Tutorial Symbol Guide") {
    TutorialSymbolGuideView()
        .previewInterfaceOrientation(.landscapeLeft)
}
