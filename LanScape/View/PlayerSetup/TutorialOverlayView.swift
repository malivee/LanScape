//
//  TutorialOverlayView.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 25/08/26.
//


import SwiftUI
import Vision

struct TutorialOverlayView: View {

    @ObservedObject
    var tutorial:
        TutorialController

    let detectedPeople:
        [DetectedPerson]

    let videoSize:
        CGSize

    let viewSize:
        CGSize

    // ---------------------------------------------------------
    // Rectangle size
    // ---------------------------------------------------------

    private let rectangleWidthRatio:
        CGFloat = 0.35

    private let rectangleHeightRatio:
        CGFloat = 0.82

    private let rectangleGapRatio:
        CGFloat = 0.13

    // ---------------------------------------------------------
    // Body
    // ---------------------------------------------------------

    var body: some View {

        ZStack {

            // =================================================
            // TOP TITLE
            // =================================================

            VStack {

                Text(
                    tutorial.currentStep.title
                )
                .font(
                    .system(
                        size:
                            24,

                        weight:
                            .bold,

                        design:
                            .rounded
                    )
                )
                .foregroundColor(
                    .white
                )

                Text(
                    tutorial.currentStep.instruction
                )
                .font(
                    .system(
                        size:
                            14,

                        weight:
                            .medium,

                        design:
                            .rounded
                    )
                )
                .foregroundColor(
                    .white.opacity(
                        0.9
                    )
                )

                Spacer()
            }
            .padding(
                .top,
                18
            )
            
            // =================================================
            // DARKEN EVERYTHING OUTSIDE PLAYER AREAS
            // =================================================

            outsideAreaOverlay()

            // =================================================
            // PLAYER RECTANGLES
            // =================================================

            playerRectangles()

            // =================================================
            // COUNTDOWN
            // =================================================

            if isCountdown {

                countdownView()
            }

            // =================================================
            // STARTED
            // =================================================

            if tutorial.currentStep == .started {

                startedView()
            }
        }
    }

    // MARK: - Countdown Check

    private var isCountdown:
        Bool {

        switch tutorial.currentStep {

        case .countdown1,
             .countdown2,
             .countdown3:

            return true

        default:

            return false
        }
    }
    
    // MARK: - Outside Area Overlay

    @ViewBuilder
    private func outsideAreaOverlay() -> some View {

        let (
            player1Rect,
            player2Rect
        ) = rectanglePositions()

        Canvas { context, size in

            // =====================================================
            // Create one path:
            //
            // 1. Entire screen
            // 2. Player 1 hole
            // 3. Player 2 hole
            //
            // even-odd fill means the two rectangles
            // become transparent holes.
            // =====================================================

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
                    cornerRadius:
                        14
                )
            )

            // Player 2 hole

            path.addPath(
                Path(
                    roundedRect:
                        player2Rect,
                    cornerRadius:
                        14
                )
            )

            // =====================================================
            // Fill everything EXCEPT the two rectangles
            // =====================================================

            context.fill(
                path,
                with:
                    .color(
                        Color.black.opacity(
                            0.55
                        )
                    ),
                style:
                    FillStyle(
                        eoFill:
                            true
                    )
            )
        }
        .allowsHitTesting(false)
    }


    // MARK: - Rectangle Layout

    @ViewBuilder
    private func playerRectangles()
        -> some View {

        let (
            player1Rect,
            player2Rect
        ) =
            rectanglePositions()

        // ---------------------------------------------
        // Update state before rendering
        // ---------------------------------------------

        let player1 =
            detectedPeople.first {
                $0.personIndex == 0
            }

        let player2 =
            detectedPeople.first {
                $0.personIndex == 1
            }

        let player1State =
            TutorialPositionValidator.validate(
                person:
                    player1,

                targetRect:
                    player1Rect,

                viewSize:
                    viewSize,

                videoSize:
                    videoSize,

                convert: {
                    point,
                    size,
                    video in

                    convertPoint(
                        point,
                        viewSize:
                            size,

                        videoSize:
                            video
                    )
                }
            )

        let player2State =
            TutorialPositionValidator.validate(
                person:
                    player2,

                targetRect:
                    player2Rect,

                viewSize:
                    viewSize,

                videoSize:
                    videoSize,

                convert: {
                    point,
                    size,
                    video in

                    convertPoint(
                        point,
                        viewSize:
                            size,

                        videoSize:
                            video
                    )
                }
            )

        // ---------------------------------------------
        // Send states to controller
        // ---------------------------------------------

        Color.clear
            .onAppear {

                tutorial.updatePlayerStates(
                    player1:
                        player1State,

                    player2:
                        player2State
                )
            }
            .onChange(
                of:
                    player1State
            ) { _, newValue in

                tutorial.updatePlayerStates(
                    player1:
                        newValue,

                    player2:
                        player2State
                )
            }
            .onChange(
                of:
                    player2State
            ) { _, newValue in

                tutorial.updatePlayerStates(
                    player1:
                        player1State,

                    player2:
                        newValue
                )
            }

        // ---------------------------------------------
        // Draw P1
        // ---------------------------------------------

        tutorialRectangle(
            rect:
                player1Rect,

            title:
                "PLAYER 1",

            state:
                player1State
        )

        // ---------------------------------------------
        // Draw P2
        // ---------------------------------------------

        tutorialRectangle(
            rect:
                player2Rect,

            title:
                "PLAYER 2",

            state:
                player2State
        )
    }

    // MARK: - Rectangle Positions

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
            rectangleWidth
            +
            rectangleGap
            +
            rectangleWidth

        let startX =
            (
                viewSize.width
                -
                totalWidth
            )
            /
            2

        let startY =
            (
                viewSize.height
                -
                rectangleHeight
            )
            /
            2

        let player1 =
            CGRect(
                x:
                    startX,

                y:
                    startY,

                width:
                    rectangleWidth,

                height:
                    rectangleHeight
            )

        let player2 =
            CGRect(
                x:
                    startX
                    +
                    rectangleWidth
                    +
                    rectangleGap,

                y:
                    startY,

                width:
                    rectangleWidth,

                height:
                    rectangleHeight
            )

        return (
            player1,
            player2
        )
    }

    // MARK: - Rectangle

    @ViewBuilder
    private func tutorialRectangle(
        rect:
            CGRect,

        title:
            String,

        state:
            TutorialRectangleState
    ) -> some View {

        ZStack {

            RoundedRectangle(
                cornerRadius:
                    14
            )
            .fill(
                state.color.opacity(
                    0.08
                )
            )

            RoundedRectangle(
                cornerRadius:
                    14
            )
            .stroke(
                state.color,

                style:
                    StrokeStyle(
                        lineWidth:
                            state == .correct
                            ? 5
                            : 3,

                        lineCap:
                            .round,

                        dash:
                            state == .waiting
                            ? [10, 8]
                            : []
                    )
            )

            VStack {

                HStack {

                    Text(
                        title
                    )
                    .font(
                        .system(
                            size:
                                12,

                            weight:
                                .bold,

                            design:
                                .rounded
                        )
                    )
                    .foregroundColor(
                        .white
                    )

                    Spacer()

                    Image(
                        systemName:
                            state == .correct
                            ? "checkmark.circle.fill"

                            : state == .incorrect
                            ? "xmark.circle.fill"

                            : "circle.dashed"
                    )
                    .foregroundColor(
                        state.color
                    )
                }

                Spacer()

                Text(
                    stateText(
                        state
                    )
                )
                .font(
                    .system(
                        size:
                            11,

                        weight:
                            .semibold,

                        design:
                            .rounded
                    )
                )
                .foregroundColor(
                    state.color
                )
            }
            .padding(
                12
            )
        }
        .frame(
            width:
                rect.width,

            height:
                rect.height
        )
        .position(
            x:
                rect.midX,

            y:
                rect.midY
        )
    }

    // MARK: - State Text

    private func stateText(
        _ state:
            TutorialRectangleState
    ) -> String {

        switch state {

        case .waiting:
            return "Menunggu pemain..."

        case .incorrect:
            return "Posisi belum tepat"

        case .correct:
            return "Posisi benar"
        }
    }

    // MARK: - Countdown

    @ViewBuilder
    private func countdownView()
        -> some View {

        VStack {

            Spacer()

            Text(
                "\(tutorial.countdown)"
            )
            .font(
                .system(
                    size:
                        100,

                    weight:
                        .black,

                    design:
                        .rounded
                )
            )
            .foregroundColor(
                .white
            )
            .shadow(
                radius:
                    10
            )

            Text(
                "Bersiap..."
            )
            .font(
                .system(
                    size:
                        18,

                    weight:
                        .bold,

                    design:
                        .rounded
                )
            )
            .foregroundColor(
                .white
            )

            Spacer()
        }
    }

    // MARK: - Started

    @ViewBuilder
    private func startedView()
        -> some View {

        VStack {

            Spacer()

            Text(
                "Mulai!"
            )
            .font(
                .system(
                    size:
                        90,

                    weight:
                        .black,

                    design:
                        .rounded
                )
            )
            .foregroundColor(
                .white
            )
            .shadow(
                color:
                    .black.opacity(0.6),
                radius:
                    16,
                x:
                    0,
                y:
                    6
            )

            Spacer()
        }
        .transition(
            .scale
                .combined(
                    with: .opacity
                )
        )
    }

    // MARK: - Coordinate Conversion

    private func convertPoint(
        _ point:
            CGPoint,

        viewSize:
            CGSize,

        videoSize:
            CGSize
    ) -> CGPoint {

        let videoWidth =
            videoSize.width

        let videoHeight =
            videoSize.height

        let videoAspect =
            videoWidth
            /
            videoHeight

        let viewAspect =
            viewSize.width
            /
            viewSize.height

        let scale:
            CGFloat

        var offsetX:
            CGFloat = 0

        var offsetY:
            CGFloat = 0

        // Same resizeAspectFill calculation
        // used by AVCaptureVideoPreviewLayer.

        if viewAspect > videoAspect {

            scale =
                viewSize.width
                /
                videoWidth

            let renderedHeight =
                videoHeight
                *
                scale

            offsetY =
                (
                    viewSize.height
                    -
                    renderedHeight
                )
                /
                2

        } else {

            scale =
                viewSize.height
                /
                videoHeight

            let renderedWidth =
                videoWidth
                *
                scale

            offsetX =
                (
                    viewSize.width
                    -
                    renderedWidth
                )
                /
                2
        }

        // Front camera preview is mirrored.

        let mirroredX =
            1.0
            -
            point.x

        return CGPoint(
            x:
                mirroredX
                *
                videoWidth
                *
                scale
                +
                offsetX,

            y:
                point.y
                *
                videoHeight
                *
                scale
                +
                offsetY
        )
    }
}
