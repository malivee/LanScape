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

    // =========================================================
    // MARK: - Player Rectangle Configuration
    // =========================================================

    private let rectangleWidthRatio: CGFloat = 0.35
    private let rectangleHeightRatio: CGFloat = 0.82
    private let rectangleGapRatio: CGFloat = 0.13

    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {
        ZStack {
            switch tutorial.currentStep {
            case .playerSetup:
                playerSetupPhase

            case .setupCountdown3,
                 .setupCountdown2,
                 .setupCountdown1:
                countdownOverlay(number: tutorial.countdown)

            case .tutorialIntro:
                textBannerOverlay(
                    stepNumber: "Tutorial #2",
                    text: "Sebelum mulai, perhatikan\nlangkah-langkah berikut, yuk!",
                    bottomCaption: "Perhatikan simbol dan warna"
                )

            case .symbolColorGuide:
                TutorialSymbolGuideView(onNext: {
                    tutorial.nextStep()
                })

            case .progressHeaderGuide:
                progressHeaderGuideView

            case .poseAppearanceExplanation:
                textBannerOverlay(
                    stepNumber: nil,
                    text: "Setiap pose akan muncul di tengah layar\nselama beberapa detik."
                )

            case .poseInstructionCard:
                poseInstructionCardView

            case .followPoseIntro:
                followPoseIntroView

            case .hitboxTargetPreview:
                hitboxTargetPreviewView

            case .hitboxExplanation:
                hitboxExplanationView

            case .matchPointsGuide:
                matchPointsGuideView

            case .holdInstruction:
                holdInstructionView

            case .practiceHoldCountdown:
                practiceHoldCountdownView

            case .poseSuccess:
                poseSuccessView

            case .tutorialCompleted:
                tutorialCompletedView
                
            case .prePlayerSetup1:
                prePlayerSetupView(text: tutorial.currentStep.instruction)
            
            case .prePlayerSetup2:
                prePlayerSetupView(text: tutorial.currentStep.instruction)
                

            case .readyCountdown3,
                 .readyCountdown2,
                 .readyCountdown1:
                countdownOverlay(number: tutorial.countdown)

            case .started:
                startedView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            switch tutorial.currentStep {
            case .playerSetup,
                 .setupCountdown3,
                 .setupCountdown2,
                 .setupCountdown1,
                 .practiceHoldCountdown,
                 .readyCountdown3,
                 .readyCountdown2,
                 .readyCountdown1,
                 .started:
                break
            default:
                tutorial.nextStep()
            }
        }
        .allowsHitTesting(true)
    }

    // =========================================================
    // MARK: - Storyboard Step Views
    // =========================================================

    // Slide 1, 5: Clean Text Banner Overlay
    @ViewBuilder
    private func textBannerOverlay(stepNumber: String? = nil, text: String, bottomCaption: String? = nil) -> some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()

            VStack {
                if let stepNumber {
                    HStack {
                        Text(stepNumber)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 24)
                }

                Spacer()

                Text(text)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 60)

                Spacer()

                if let bottomCaption {
                    Text(bottomCaption)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                }
            }
        }
    }

    // Slide 4: Progress Header Explanation with Header Spotlight
    @ViewBuilder
    private var progressHeaderGuideView: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack {
                // Top Header Preview with Highlight
                PoseSessionHeaderView(
                    currentStepIndex: 0,
                    totalSteps: 5,
                    onPause: {}
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                )

                Spacer()

                Text("Kalian bisa melihat progress dan jumlah pose di sini")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 120)

                Spacer()
            }
        }
    }

    // Slide 6: Pose Instruction Card Display
    @ViewBuilder
    private var poseInstructionCardView: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack {
                // Top Header
                PoseSessionHeaderView(
                    currentStepIndex: 0,
                    totalSteps: 5,
                    onPause: {}
                )

                Spacer()

                // Center Reusable Card
                PoseInstructionView(
                    mainTitle: "Pose Pertama",
                    subTitle: "Pose Fusion",
                    imageName: "Fusion"
                )

                Spacer()
            }
        }
    }

    // Slide 7: Follow Pose Intro + Mini Thumbnail Badge
    @ViewBuilder
    private var followPoseIntroView: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }

            // Center Text
            VStack {
                Spacer()
                Text("Ikuti posenya!")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
        }
    }

    // Slide 8: Hitbox Target Preview
    @ViewBuilder
    private var hitboxTargetPreviewView: some View {
        ZStack {
            // Center Divider
            CenterDividerLineView()
                .frame(width: viewSize.width, height: viewSize.height)
                .ignoresSafeArea()

            // Hitboxes
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 6),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }
        }
    }

    // Slide 9: Hitbox Explanation
    @ViewBuilder
    private var hitboxExplanationView: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea()

            // Center Divider
            CenterDividerLineView()
                .frame(width: viewSize.width, height: viewSize.height)
                .ignoresSafeArea()

            // Hitboxes
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 6),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }

            // Center Text
            VStack {
                Spacer()
                Text("Pastikan tangan dan kaki kalian mengenai masing-masing titiknya.")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 60)
                Spacer()
            }
        }
    }

    // Slide 10: Match Points Guide
    @ViewBuilder
    private var matchPointsGuideView: some View {
        ZStack {
            // Center Divider
            CenterDividerLineView()
                .frame(width: viewSize.width, height: viewSize.height)
                .ignoresSafeArea()

            // Hitboxes
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 6),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // Top Left Helper Badge & Top Right Thumbnail
            VStack {
                HStack {
                    HStack(spacing: 8) {
                        Text("Contoh Gerakan Benar")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "1E4BA3"))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color(hex: "1E4BA3").opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
                    .padding(.leading, 28)
                    .padding(.top, 20)

                    Spacer()

                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }
        }
    }

    // Slide 11: Hold Instruction
    @ViewBuilder
    private var holdInstructionView: some View {
        ZStack {
            Color.black.opacity(0.60).ignoresSafeArea()

            // Center Divider
            CenterDividerLineView()
                .frame(width: viewSize.width, height: viewSize.height)
                .ignoresSafeArea()

            // Hitboxes
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 6),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }

            // Center Text
            VStack {
                Spacer()
                Text("Tahan posisi kalian selama 5 detik!")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                Spacer()
            }
        }
    }

    // Slide 12: Practice Hold Countdown
    @ViewBuilder
    private var practiceHoldCountdownView: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            // Center Divider
            CenterDividerLineView()
                .frame(width: viewSize.width, height: viewSize.height)
                .ignoresSafeArea()

            // Hitboxes
            MovementHitboxOverlayView(
                hitboxes: MovementHitboxLayout.hitboxes(for: 6),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }

            // Center Countdown Circle
            ZStack {
                Circle()
                    .fill(Color(hex: "6A85B6").opacity(0.88))
                    .frame(width: 150, height: 150)
                    .shadow(color: Color.black.opacity(0.4), radius: 12)

                Circle()
                    .stroke(Color.white, lineWidth: 4.5)
                    .frame(width: 150, height: 150)

                Text("\(tutorial.countdown)")
                    .id(tutorial.countdown)
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                    .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: tutorial.countdown)

            // Top Banner
            VStack {
                Text("Tahan posisimu selama 5 detik")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 8)
                    .padding(.top, 35)

                Spacer()
            }
        }
    }

    // Slide 13: Pose Success ("BERHASIL!")
    @ViewBuilder
    private var poseSuccessView: some View {
        ZStack {
            Color.black.opacity(0.50).ignoresSafeArea()

            // Top Right Thumbnail Badge
            VStack {
                HStack {
                    Spacer()
                    MiniPoseThumbnailBadge(imageName: "Fusion", size: 175)
                        .padding(.trailing, 28)
                        .padding(.top, 20)
                }
                Spacer()
            }

            // Center Celebratory Text
            VStack {
                Spacer()
                Text("BERHASIL!")
                    .font(.system(size: 58, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 10)
                    .transition(.scale.combined(with: .opacity))
                Spacer()
            }
        }
    }

    // Slide 14: Tutorial Completed
    @ViewBuilder
    private var tutorialCompletedView: some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Tutorial selesai.\nMari kita lanjut!")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)

                Text("Ketuk layar untuk bersiap")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)

                Spacer()
            }
            .transition(.scale.combined(with: .opacity))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tutorial.nextStep()
        }
    }
    
    // =========================================================
    // MARK: - Duduk di kursi
    // =========================================================
    
    @ViewBuilder
    private func prePlayerSetupView(text: String) -> some View {
        ZStack {
            Color.black
                .opacity(0.50)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text(text)
                    .font(
                        .system(
                            size: 28,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)

                Spacer()
            }
        }
    }

    // =========================================================
    // MARK: - Countdown
    // =========================================================

    @ViewBuilder
    private func countdownOverlay(
        number: Int
    ) -> some View {

        ZStack {
            Color.black
                .opacity(0.60)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if number > 0 {
                    Text("Bersiap dalam...")
                        .font(
                            .system(
                                size: 30,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 6)

                    ZStack {
                        Circle()
                            .fill(Color(hex: "1E4BA3"))
                            .frame(width: 140, height: 140)
                            .shadow(color: Color(hex: "1E4BA3").opacity(0.8), radius: 16)

                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 4.5)
                            .frame(width: 140, height: 140)

                        Text("\(number)")
                            .id(number)
                            .font(
                                .system(
                                    size: 84,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .animation(
                        .spring(
                            response: 0.35,
                            dampingFraction: 0.65
                        ),
                        value: number
                    )
                } else {
                    // Ayo Berpose! (Matches storyboard screenshot)
                    Text("Ayo Berpose!")
                        .font(
                            .system(
                                size: 64,
                                weight: .heavy,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "1E4BA3"), radius: 12, x: 0, y: 4)
                        .shadow(color: Color.blue.opacity(0.8), radius: 24, x: 0, y: 0)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
            }
        }
    }

    // =========================================================
    // MARK: - Started View
    // =========================================================

    @ViewBuilder
    private var startedView: some View {
        countdownOverlay(number: 0)
    }

    // =========================================================
    // MARK: - Player Setup Phase
    // =========================================================


    @ViewBuilder
    private var playerSetupPhase: some View {

        ZStack {

            // -------------------------------------------------
            // Darken outside the two player areas
            // -------------------------------------------------

            outsideAreaOverlay()

            // -------------------------------------------------
            // Header
            // -------------------------------------------------

            VStack(spacing: 0) {

                Text(setupInstruction())
                    .font(
                        .system(
                            size: 24,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 18)

                Spacer()
            }

            // -------------------------------------------------
            // Player rectangles
            // -------------------------------------------------

            playerRectangles()

            // =================================================
            // GANTI ORANG — TENGAH ANTARA PLAYER 1 & PLAYER 2
            // =================================================

            VStack {
                Spacer()

                Button {
                    // aksi ganti player
                    // panggil fungsi changePlayer di sini
                } label: {
                    Text("Ubah orang")
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.white)
                }

                Spacer()
            }        }
    }
    // =========================================================
    // MARK: - Setup Instruction
    // =========================================================

    private func setupInstruction() -> String {

        let (
            player1Rect,
            player2Rect
        ) = rectanglePositions()

        let player1 =
            detectedPeople.first {
                $0.personIndex == 0
            }

        let player2 =
            detectedPeople.first {
                $0.personIndex == 1
            }

        let player1Count =
            detectedPointCount(
                person: player1,
                targetRect: player1Rect
            )

        let player2Count =
            detectedPointCount(
                person: player2,
                targetRect: player2Rect
            )

        let total =
            player1Count + player2Count

        // Both players have all 4 points
        if player1Count == 4 &&
            player2Count == 4 {

            return "Yeay, kalian sudah terlihat jelas di kamera!"
        }

        // No points detected
        if total == 0 {

            return "Pastikan seluruh tubuh kalian terlihat jelas."
        }

        // 1 point
        if total == 1 {

            return "Berikan sedikit jarak lagi!"
        }

        // 2 points
        if total == 2 {

            return "Sudah hampir tepat!"
        }

        // 3 points
        if total == 3 {

            return "Sudah hampir tepat!"
        }

        // One player complete but the other is not
        if player1Count == 4 ||
            player2Count == 4 {

            return "Tetap di area ini, ya!"
        }

        return "Sudah hampir tepat!"
    }

    // =========================================================
    // MARK: - Outside Area Overlay
    // =========================================================

    @ViewBuilder
    private func outsideAreaOverlay() -> some View {

        let (
            player1Rect,
            player2Rect
        ) = rectanglePositions()

        Canvas { context, size in

            var path = Path()

            // Entire screen
            path.addRect(
                CGRect(
                    origin: .zero,
                    size: size
                )
            )

            // Player 1 hole
            path.addPath(
                Path(
                    roundedRect:
                        player1Rect,
                    cornerRadius: 14
                )
            )

            // Player 2 hole
            path.addPath(
                Path(
                    roundedRect:
                        player2Rect,
                    cornerRadius: 14
                )
            )

            context.fill(
                path,
                with:
                    .color(
                        Color.black.opacity(0.65)
                    ),
                style:
                    FillStyle(
                        eoFill: true
                    )
            )
        }
        .allowsHitTesting(false)
    }

    // =========================================================
    // MARK: - Player Rectangles
    // =========================================================

    @ViewBuilder
    private func playerRectangles() -> some View {

        let (
            player1Rect,
            player2Rect
        ) = rectanglePositions()

        let player1 =
            detectedPeople.first {
                $0.personIndex == 0
            }

        let player2 =
            detectedPeople.first {
                $0.personIndex == 1
            }

        // -----------------------------------------------------
        // Validate Player 1
        // -----------------------------------------------------

        let player1State =
            TutorialPositionValidator.validate(
                person: player1,
                targetRect: player1Rect,
                viewSize: viewSize,
                videoSize: videoSize,
                convert: {
                    point,
                    size,
                    video in

                    convertPoint(
                        point,
                        viewSize: size,
                        videoSize: video
                    )
                }
            )

        // -----------------------------------------------------
        // Validate Player 2
        // -----------------------------------------------------

        let player2State =
            TutorialPositionValidator.validate(
                person: player2,
                targetRect: player2Rect,
                viewSize: viewSize,
                videoSize: videoSize,
                convert: {
                    point,
                    size,
                    video in

                    convertPoint(
                        point,
                        viewSize: size,
                        videoSize: video
                    )
                }
            )

        // -----------------------------------------------------
        // Update controller
        // -----------------------------------------------------

        Color.clear
            .frame(
                width: 0,
                height: 0
            )
            .allowsHitTesting(false)
            .onAppear {

                tutorial.updatePlayerStates(
                    player1: player1State,
                    player2: player2State
                )
            }
            .onChange(
                of: player1State
            ) { _, newValue in

                tutorial.updatePlayerStates(
                    player1: newValue,
                    player2: player2State
                )
            }
            .onChange(
                of: player2State
            ) { _, newValue in

                tutorial.updatePlayerStates(
                    player1: player1State,
                    player2: newValue
                )
            }

        // -----------------------------------------------------
        // Player 1
        // -----------------------------------------------------

        tutorialRectangle(
            rect: player1Rect,
            title: "PLAYER 1",
            state: player1State
        )

        // -----------------------------------------------------
        // Player 2
        // -----------------------------------------------------

        tutorialRectangle(
            rect: player2Rect,
            title: "PLAYER 2",
            state: player2State
        )
    }

    // =========================================================
    // MARK: - Rectangle Positions
    // =========================================================

    private func rectanglePositions()
        -> (
            CGRect,
            CGRect
        ) {

        let rectangleWidth =
            viewSize.width *
            rectangleWidthRatio

        let rectangleHeight =
            viewSize.height *
            rectangleHeightRatio

        let rectangleGap =
            viewSize.width *
            rectangleGapRatio

        let totalWidth =
            rectangleWidth +
            rectangleGap +
            rectangleWidth

        let startX =
            (
                viewSize.width -
                totalWidth
            ) / 2

        let startY =
            (
                viewSize.height -
                rectangleHeight
            ) / 2

        let player1 =
            CGRect(
                x: startX,
                y: startY,
                width: rectangleWidth,
                height: rectangleHeight
            )

        let player2 =
            CGRect(
                x:
                    startX +
                    rectangleWidth +
                    rectangleGap,
                y: startY,
                width: rectangleWidth,
                height: rectangleHeight
            )

        return (
            player1,
            player2
        )
    }

    // =========================================================
    // MARK: - Tutorial Rectangle
    // =========================================================

    @ViewBuilder
    private func tutorialRectangle(
        rect: CGRect,
        title: String,
        state: TutorialRectangleState
    ) -> some View {

        let personIndex =
            title == "PLAYER 1" ? 0 : 1

        let person =
            detectedPeople.first {
                $0.personIndex == personIndex
            }

        let pointCount =
            detectedPointCount(
                person: person,
                targetRect: rect
            )

        let progress =
            CGFloat(pointCount) / 4.0

        ZStack {

            // =====================================================
            // TRANSPARENT INSIDE
            // =====================================================

            RoundedRectangle(
                cornerRadius: 14
            )
            .fill(
                Color.white.opacity(0.025)
            )

            // =====================================================
            // OUTLINE
            // =====================================================

            if pointCount == 0 {

                // -------------------------------------------------
                // 0 / 4
                // FULL RED
                // -------------------------------------------------

                RoundedRectangle(
                    cornerRadius: 14
                )
                .stroke(
                    Color.red,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            } else {

                // -------------------------------------------------
                // GREEN PROGRESS
                //
                // 1/4 = 25%
                // 2/4 = 50%
                // 3/4 = 75%
                // 4/4 = 100%
                // -------------------------------------------------

                RectangleProgressShape(
                    progress: progress,
                    cornerRadius: 14
                )
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .animation(
                    .easeInOut(duration: 0.35),
                    value: pointCount
                )
            }

            // =====================================================
            // PLAYER LABEL
            // =====================================================

            VStack {

                HStack {



                    Spacer()

                    Image(
                        systemName:
                            pointCount == 4
                            ? "checkmark.circle.fill"
                            : "xmark.circle.fill"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundColor(
                        pointCount == 4
                        ? .green
                        : .red
                    )
                }

                Spacer()

                Text("\(pointCount)/4 titik")
                    .font(
                        .system(
                            size: 14,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(
                        pointCount == 4
                        ? .green
                        : .white
                    )
                    .shadow(
                        color: Color.black.opacity(0.7),
                        radius: 4
                    )
            }
            .padding(12)
        }
        .frame(
            width: rect.width,
            height: rect.height
        )
        .position(
            x: rect.midX,
            y: rect.midY
        )
    }
    // =========================================================
    // MARK: - Count Exactly Four Required Points
    // =========================================================

    private func detectedPointCount(
        person: DetectedPerson?,
        targetRect: CGRect
    ) -> Int {

        guard let person else {
            return 0
        }

        let requiredJoints:
            [VNHumanBodyPoseObservation.JointName] = [

                .leftWrist,
                .rightWrist,
                .leftAnkle,
                .rightAnkle
            ]

        var count = 0

        for joint in requiredJoints {

            guard
                let point =
                    person.joints[joint]
            else {
                continue
            }

            let converted =
                convertPoint(
                    point,
                    viewSize: viewSize,
                    videoSize: videoSize
                )

            if targetRect.contains(
                converted
            ) {

                count += 1
            }
        }

        return min(
            count,
            4
        )
    }

    // =========================================================
    // MARK: - Convert Vision Point To Screen
    // =========================================================

    private func convertPoint(
        _ point: CGPoint,
        viewSize: CGSize,
        videoSize: CGSize
    ) -> CGPoint {

        let videoWidth =
            videoSize.width > 0
            ? videoSize.width
            : 1920

        let videoHeight =
            videoSize.height > 0
            ? videoSize.height
            : 1080

        let videoAspect =
            videoWidth / videoHeight

        let viewAspect =
            viewSize.width / viewSize.height

        let scale: CGFloat

        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if viewAspect > videoAspect {

            scale =
                viewSize.width /
                videoWidth

            let renderedHeight =
                videoHeight * scale

            offsetY =
                (
                    viewSize.height -
                    renderedHeight
                ) / 2

        } else {

            scale =
                viewSize.height /
                videoHeight

            let renderedWidth =
                videoWidth * scale

            offsetX =
                (
                    viewSize.width -
                    renderedWidth
                ) / 2
        }

        // Back camera is mirrored in the UI.
        let mirroredX =
            1.0 - point.x

        return CGPoint(
            x:
                mirroredX *
                videoWidth *
                scale +
                offsetX,

            y:
                point.y *
                videoHeight *
                scale +
                offsetY
        )
    }
}


