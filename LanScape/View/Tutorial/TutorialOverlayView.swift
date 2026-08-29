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

                countdownOverlay(
                    number: tutorial.countdown
                )

            case .colorMatchingGuide:
                TutorialSymbolGuideView()

            case .practiceHold:
                practiceHoldView

            case .tutorialCompleted:
                tutorialCompletedView

            case .readyCountdown3,
                 .readyCountdown2,
                 .readyCountdown1:

                countdownOverlay(
                    number: tutorial.countdown
                )

            case .started:
                startedView
            }
        }
        .allowsHitTesting(false)
    }

    // =========================================================
    // MARK: - Practice Hold View
    // =========================================================

    @ViewBuilder
    private var practiceHoldView: some View {

        ZStack {

            Color.black
                .opacity(0.60)
                .ignoresSafeArea()

            Rectangle()
                .fill(
                    Color.white.opacity(0.35)
                )
                .frame(width: 2)
                .ignoresSafeArea()

            MovementHitboxOverlayView(
                hitboxes:
                    MovementHitboxLayout.hitboxes(
                        for: 1
                    ),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            ZStack {

                Circle()
                    .fill(
                        Color(hex: "6A85B6")
                            .opacity(0.88)
                    )
                    .frame(
                        width: 150,
                        height: 150
                    )
                    .shadow(
                        color: Color.black.opacity(0.4),
                        radius: 12
                    )

                Circle()
                    .stroke(
                        Color.white,
                        lineWidth: 4.5
                    )
                    .frame(
                        width: 150,
                        height: 150
                    )

                Text(
                    "\(tutorial.countdown)"
                )
                .id(tutorial.countdown)
                .font(
                    .system(
                        size: 88,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(.white)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 4
                )
                .transition(
                    .scale.combined(
                        with: .opacity
                    )
                )
            }
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.65
                ),
                value: tutorial.countdown
            )

            VStack {

                Text(
                    "Tahan posisimu selama 5 detik"
                )
                .font(
                    .system(
                        size: 34,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(
                    Color.black.opacity(0.55)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            Color.white.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.5),
                    radius: 8
                )
                .padding(.top, 40)

                Spacer()
            }
        }
    }

    // =========================================================
    // MARK: - Tutorial Slide View
    // =========================================================

    @ViewBuilder
    private func tutorialSlideView(
        text: String
    ) -> some View {

        ZStack {

            Color.black
                .opacity(0.70)
                .ignoresSafeArea()

            Rectangle()
                .fill(
                    Color.white.opacity(0.20)
                )
                .frame(width: 1.5)
                .ignoresSafeArea()

            MovementHitboxOverlayView(
                hitboxes:
                    MovementHitboxLayout.hitboxes(
                        for: 1
                    ),
                results: [],
                viewSize: viewSize
            )
            .ignoresSafeArea()

            VStack {

                Text(text)
                    .font(
                        .system(
                            size: 44,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
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
    // MARK: - Tutorial Completed
    // =========================================================

    @ViewBuilder
    private var tutorialCompletedView: some View {

        ZStack {

            Color.black
                .opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                Spacer()

                Text(
                    "Keren Tutorial Selesai!"
                )
                .font(
                    .system(
                        size: 52,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

                Text(
                    "Bersiap masuk ke game"
                )
                .font(
                    .system(
                        size: 26,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundColor(
                    .white.opacity(0.9)
                )

                Spacer()
            }
            .transition(
                .scale.combined(
                    with: .opacity
                )
            )
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
                .opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer()

                Text("Bersiap dalam...")
                    .font(
                        .system(
                            size: 26,
                            weight: .medium,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)

                ZStack {

                    Circle()
                        .fill(
                            Color(hex: "1E4BA3")
                        )
                        .frame(
                            width: 140,
                            height: 140
                        )

                    Circle()
                        .stroke(
                            Color.white.opacity(0.5),
                            lineWidth: 4
                        )
                        .frame(
                            width: 140,
                            height: 140
                        )

                    Text("\(number)")
                        .id(number)
                        .font(
                            .system(
                                size: 84,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.white)
                        .transition(
                            .scale.combined(
                                with: .opacity
                            )
                        )
                }
                .animation(
                    .spring(
                        response: 0.35,
                        dampingFraction: 0.65
                    ),
                    value: number
                )

                Spacer()
            }
        }
    }

    // =========================================================
    // MARK: - Started View
    // =========================================================

    @ViewBuilder
    private var startedView: some View {

        ZStack {

            Color.black
                .opacity(0.5)
                .ignoresSafeArea()

            VStack {

                Spacer()

                Text("Mulai!")
                    .font(
                        .system(
                            size: 80,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)
                    .transition(
                        .scale.combined(
                            with: .opacity
                        )
                    )

                Spacer()
            }
        }
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
        }
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


