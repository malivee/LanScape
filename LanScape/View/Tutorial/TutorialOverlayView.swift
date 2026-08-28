//
//  TutorialOverlayView.swift
//  LanScape
//

import SwiftUI
import Vision

struct TutorialOverlayView: View {

    @ObservedObject
    var tutorial: TutorialController

    let detectedPeople: [DetectedPerson]
    let videoSize: CGSize
    let viewSize: CGSize

    // Rectangle size ratios for player setup
    private let rectangleWidthRatio: CGFloat = 0.35
    private let rectangleHeightRatio: CGFloat = 0.82
    private let rectangleGapRatio: CGFloat = 0.13

    var body: some View {
        ZStack {
            // =================================================
            // 1. PHASE SPECIFIC CONTENT
            // =================================================
            switch tutorial.currentStep {
            case .playerSetup:
                playerSetupPhase

            case .setupCountdown3, .setupCountdown2, .setupCountdown1:
                countdownOverlay(number: tutorial.countdown)

            case .colorMatchingGuide:
                tutorialSlideView(
                    text: "Arahkan titik di tubuh sesuai dengan titik di layar"
                )

            case .practiceHold:
                tutorialSlideView(
                    text: "Lalu tahan posisi tangan dan kaki  selama 5 detik"
                )

            case .tutorialCompleted:
                tutorialCompletedView

            case .readyCountdown3, .readyCountdown2, .readyCountdown1:
                countdownOverlay(number: tutorial.countdown)

            case .started:
                startedView
            }
        }
        .allowsHitTesting(false)
    }


    // =========================================================
    // MARK: - Reusable Tutorial Slide View (Menggunakan Hitbox Component)
    // =========================================================

    @ViewBuilder
    private func tutorialSlideView(text: String) -> some View {
        ZStack {
            // 1. Dark Backdrop (Layar gelap & fokus)
            Color.black.opacity(0.70).ignoresSafeArea()

            // 2. Center Divider Line
            Rectangle()
                .fill(Color.white.opacity(0.20))
                .frame(width: 1.5)
                .ignoresSafeArea()

            // 3. Reusable Movement Hitbox Component
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 1),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // 4. Simple Clean White Text (Terletak rapi di bagian atas agar tidak tertimpa)
            VStack {
                Text(text)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 60)
                    .padding(.top, 45)

                Spacer()
            }
        }
    }


    // =========================================================
    // MARK: - Tutorial Completed View (Transisi Sebelum Game)
    // =========================================================

    @ViewBuilder
    private var tutorialCompletedView: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                
                
                Text("\(Text("Keren ").font(.system(size: 72, weight: .heavy, design: .rounded)))Tutorial Selesai!")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Bersiap masuk ke game")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // =========================================================
    // MARK: - Countdown Overlay (Persis Sesuai Mockup Gambar)
    // =========================================================

    @ViewBuilder
    private func countdownOverlay(number: Int) -> some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Header text
                Text("Bersiap dalam...")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                // Blue Solid Circle dengan Border Putih
                ZStack {
                    Circle()
                        .fill(Color(hex: "1E4BA3"))
                        .frame(width: 140, height: 140)

                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .frame(width: 140, height: 140)

                    Text("\(number)")
                        .id(number)
                        .font(.system(size: 84, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: number)

                Spacer()
            }
        }
    }


    // =========================================================
    // MARK: - Started Overlay View (Teks Bersih "Mulai!")
    // =========================================================

    @ViewBuilder
    private var startedView: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack {
                Spacer()

                Text("Mulai!")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))

                Spacer()
            }
        }
    }


    // =========================================================
    // MARK: - Phase 1: Player Setup
    // =========================================================

    @ViewBuilder
    private var playerSetupPhase: some View {
        ZStack {
            outsideAreaOverlay()

            VStack {
                VStack(spacing: 4) {
                    Text("Persiapan Pemain")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Posisikan tubuh di dalam area kotak masing-masing.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 18)

                Spacer()
            }

            playerRectangles()
        }
    }

    @ViewBuilder
    private func outsideAreaOverlay() -> some View {
        let (player1Rect, player2Rect) = rectanglePositions()

        Canvas { context, size in
            var path = Path()
            path.addRect(CGRect(origin: .zero, size: size))
            path.addPath(Path(roundedRect: player1Rect, cornerRadius: 14))
            path.addPath(Path(roundedRect: player2Rect, cornerRadius: 14))

            context.fill(
                path,
                with: .color(Color.black.opacity(0.65)),
                style: FillStyle(eoFill: true)
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func playerRectangles() -> some View {
        let (player1Rect, player2Rect) = rectanglePositions()

        let player1 = detectedPeople.first { $0.personIndex == 0 }
        let player2 = detectedPeople.first { $0.personIndex == 1 }

        let player1State = TutorialPositionValidator.validate(
            person: player1,
            targetRect: player1Rect,
            viewSize: viewSize,
            videoSize: videoSize,
            convert: { point, size, video in
                convertPoint(point, viewSize: size, videoSize: video)
            }
        )

        let player2State = TutorialPositionValidator.validate(
            person: player2,
            targetRect: player2Rect,
            viewSize: viewSize,
            videoSize: videoSize,
            convert: { point, size, video in
                convertPoint(point, viewSize: size, videoSize: video)
            }
        )

        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onAppear {
                tutorial.updatePlayerStates(player1: player1State, player2: player2State)
            }
            .onChange(of: player1State) { _, newValue in
                tutorial.updatePlayerStates(player1: newValue, player2: player2State)
            }
            .onChange(of: player2State) { _, newValue in
                tutorial.updatePlayerStates(player1: player1State, player2: newValue)
            }

        tutorialRectangle(rect: player1Rect, title: "PLAYER 1", state: player1State)
        tutorialRectangle(rect: player2Rect, title: "PLAYER 2", state: player2State)
    }

    private func rectanglePositions() -> (CGRect, CGRect) {
        let rectangleWidth = viewSize.width * rectangleWidthRatio
        let rectangleHeight = viewSize.height * rectangleHeightRatio
        let rectangleGap = viewSize.width * rectangleGapRatio
        let totalWidth = rectangleWidth + rectangleGap + rectangleWidth

        let startX = (viewSize.width - totalWidth) / 2
        let startY = (viewSize.height - rectangleHeight) / 2

        let player1 = CGRect(x: startX, y: startY, width: rectangleWidth, height: rectangleHeight)
        let player2 = CGRect(x: startX + rectangleWidth + rectangleGap, y: startY, width: rectangleWidth, height: rectangleHeight)

        return (player1, player2)
    }

    @ViewBuilder
    private func tutorialRectangle(
        rect: CGRect,
        title: String,
        state: TutorialRectangleState
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(state.color.opacity(0.08))

            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    state.color,
                    style: StrokeStyle(
                        lineWidth: state == .correct ? 5 : 3,
                        lineCap: .round,
                        dash: state == .waiting ? [10, 8] : []
                    )
                )

            VStack {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Image(
                        systemName: state == .correct
                            ? "checkmark.circle.fill"
                            : state == .incorrect
                            ? "xmark.circle.fill"
                            : "circle.dashed"
                    )
                    .foregroundColor(state.color)
                }

                Spacer()

                Text(stateText(state))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(state.color)
            }
            .padding(12)
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    private func stateText(_ state: TutorialRectangleState) -> String {
        switch state {
        case .waiting: return "Menunggu pemain..."
        case .incorrect: return "Posisi belum tepat"
        case .correct: return "Posisi benar"
        }
    }

    private func convertPoint(_ point: CGPoint, viewSize: CGSize, videoSize: CGSize) -> CGPoint {
        let videoWidth = videoSize.width > 0 ? videoSize.width : 1920
        let videoHeight = videoSize.height > 0 ? videoSize.height : 1080

        let videoAspect = videoWidth / videoHeight
        let viewAspect = viewSize.width / viewSize.height

        let scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if viewAspect > videoAspect {
            scale = viewSize.width / videoWidth
            let renderedHeight = videoHeight * scale
            offsetY = (viewSize.height - renderedHeight) / 2
        } else {
            scale = viewSize.height / videoHeight
            let renderedWidth = videoWidth * scale
            offsetX = (viewSize.width - renderedWidth) / 2
        }

        let mirroredX = 1.0 - point.x
        return CGPoint(
            x: mirroredX * videoWidth * scale + offsetX,
            y: point.y * videoHeight * scale + offsetY
        )
    }
}
