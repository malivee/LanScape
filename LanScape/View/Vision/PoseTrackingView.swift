//
//  PoseTrackingView.swift
//  LanScape
//

import SwiftUI
import UIKit
import AVFoundation

struct PoseTrackingView: View {

    // =========================================================
    // MARK: - Services
    // =========================================================

    @StateObject
    private var visionService = VisionService()

    @StateObject
    private var tutorialController = TutorialController()


    // =========================================================
    // MARK: - Environment
    // =========================================================

    @Environment(\.dismiss)
    private var dismiss


    // =========================================================
    // MARK: - Gameplay
    // =========================================================

    @State
    private var hitboxResults: [HitboxResult] = []

    @State
    private var isMovementSuccessful = false

    @State
    private var movementNumber = 1

    private let totalMovements = 5


    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                // =================================================
                // CAMERA
                // =================================================

                CameraPreviewView(
                    session: visionService.captureSession,
                    onOrientationChanged: { orientation in

                        visionService.updateVideoOrientation(
                            orientation
                        )
                    }
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()
                .ignoresSafeArea()


                // =================================================
                // VISION JOINT OVERLAY
                // =================================================

                PoseSkeletonOverlayView(
                    detectedPeople:
                        visionService
                            .poseModel
                            .detectedPeople,

                    videoSize:
                        visionService
                            .poseModel
                            .videoSize
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()
                .ignoresSafeArea()


                // =================================================
                // GAME FLOW
                // =================================================

                if !tutorialController.hasStarted {

                    tutorialPhase

                } else {

                    gameplayPhase
                }


                // =================================================
                // DEBUG CONTROLS
                // =================================================

                testControlsOverlay
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .ignoresSafeArea()

            // =====================================================
            // IMPORTANT:
            //
            // Use the actual SwiftUI geometry size for hitbox
            // validation.
            // =====================================================

            .onReceive(
                visionService
                    .poseModel
                    .$detectedPeople
            ) { people in

                updateHitboxes(
                    people: people,
                    viewSize: geometry.size
                )
            }
        }
        .ignoresSafeArea()

        // =========================================================
        // LIFECYCLE
        // =========================================================

        .onAppear {
            handleAppear()
        }

        .onDisappear {
            handleDisappear()
        }
    }


    // =============================================================
    // MARK: - Tutorial
    // =============================================================

    @ViewBuilder
    private var tutorialPhase: some View {

        GeometryReader { geometry in

            TutorialOverlayView(
                tutorial:
                    tutorialController,

                detectedPeople:
                    visionService
                        .poseModel
                        .detectedPeople,

                videoSize:
                    visionService
                        .poseModel
                        .videoSize,

                viewSize:
                    geometry.size
            )
        }
        .ignoresSafeArea()
    }


    // =============================================================
    // MARK: - Gameplay
    // =============================================================

    @ViewBuilder
    private var gameplayPhase: some View {

        GeometryReader { geometry in

            ZStack {

                // =================================================
                // CENTER DIVIDER
                // =================================================

                CenterDividerLineView()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .ignoresSafeArea()


                // =================================================
                // HITBOXES
                // =================================================

                MovementHitboxOverlayView(
                    hitboxes:
                        MovementHitboxLayout
                            .hitboxes(
                                for: movementNumber
                            ),

                    results:
                        hitboxResults,

                    viewSize:
                        geometry.size
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .ignoresSafeArea()


                // =================================================
                // SUCCESS
                // =================================================

                if isMovementSuccessful {

                    Text("PERFECT!")
                        .font(
                            .system(
                                size: 64,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundColor(.white)
                        .shadow(
                            color:
                                .black.opacity(0.7),
                            radius: 12
                        )
                        .transition(
                            .scale
                                .combined(
                                    with: .opacity
                                )
                        )
                }


                // =================================================
                // HEADER
                //
                // IMPORTANT:
                // This VStack pins the header to the top.
                // Previously gameplayHeader was directly inside
                // ZStack, which caused it to appear in the middle.
                // =================================================

                VStack(
                    spacing: 0
                ) {

                    gameplayHeader

                    Spacer()
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
    }


    // =============================================================
    // MARK: - Gameplay Header
    // =============================================================

    @ViewBuilder
    private var gameplayHeader: some View {

        VStack(
            spacing: 12
        ) {

            // =====================================================
            // TOP ROW
            // =====================================================

            HStack {

                // -------------------------------------------------
                // Pause button
                // -------------------------------------------------

                Button {

                    dismiss()

                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                Color.white.opacity(0.92)
                            )
                            .frame(
                                width: 52,
                                height: 52
                            )

                        Image(
                            systemName:
                                "pause.fill"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
                        .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)


                Spacer()


                // -------------------------------------------------
                // Movement number
                // -------------------------------------------------

                Text(
                    "\(movementNumber)/\(totalMovements) Gerakan"
                )
                .font(
                    .system(
                        size: 26,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(.white)
                .shadow(
                    color: .black.opacity(0.8),
                    radius: 4,
                    x: 0,
                    y: 2
                )


                Spacer()


                // -------------------------------------------------
                // Invisible spacer
                // -------------------------------------------------

                Color.clear
                    .frame(
                        width: 52,
                        height: 52
                    )
            }


            // =====================================================
            // PROGRESS BAR
            // =====================================================

            GeometryReader { geometry in

                let spacing: CGFloat = 8

                let totalWidth =
                    geometry.size.width

                let segmentWidth =
                    (
                        totalWidth
                        -
                        (
                            spacing
                            *
                            CGFloat(
                                totalMovements - 1
                            )
                        )
                    )
                    /
                    CGFloat(
                        totalMovements
                    )


                HStack(
                    spacing: spacing
                ) {

                    ForEach(
                        0..<totalMovements,
                        id: \.self
                    ) { index in

                        RoundedRectangle(
                            cornerRadius: 5
                        )
                        .fill(

                            index < movementNumber

                            ? Color.blue

                            : Color.white.opacity(0.35)
                        )
                        .frame(
                            width:
                                segmentWidth,
                            height: 7
                        )
                        .animation(
                            .easeInOut(
                                duration: 0.25
                            ),
                            value:
                                movementNumber
                        )
                    }
                }
            }
            .frame(
                height: 7
            )
        }

        .padding(
            .horizontal,
            30
        )

        .padding(
            .top,
            18
        )

        .padding(
            .bottom,
            18
        )

        // =========================================================
        // IMPORTANT:
        //
        // NO .background()
        //
        // The camera is now visible behind the header.
        // =========================================================
    }

    // =============================================================
    // MARK: - Hitbox Processing
    // =============================================================

    private func updateHitboxes(
        people: [DetectedPerson],
        viewSize: CGSize
    ) {

        // ---------------------------------------------------------
        // Only validate during gameplay.
        // ---------------------------------------------------------

        guard
            tutorialController.hasStarted
        else {
            return
        }


        // ---------------------------------------------------------
        // Hitbox layout
        // ---------------------------------------------------------

        let hitboxes =
            MovementHitboxLayout
                .hitboxes(
                    for: movementNumber
                )


        // ---------------------------------------------------------
        // Video size
        // ---------------------------------------------------------

        let videoSize =
            visionService
                .poseModel
                .videoSize


        guard
            videoSize.width > 0,
            videoSize.height > 0
        else {
            return
        }


        // ---------------------------------------------------------
        // View size
        // ---------------------------------------------------------

        guard
            viewSize.width > 0,
            viewSize.height > 0
        else {
            return
        }


        // ---------------------------------------------------------
        // Validate all hitboxes
        // ---------------------------------------------------------

        let results =
            MovementHitboxValidator.validate(

                people:
                    people,

                hitboxes:
                    hitboxes,

                viewSize:
                    viewSize,

                videoSize:
                    videoSize,

                convert: {
                    point,
                    size,
                    video
                    in

                    convertPoint(
                        point,
                        viewSize: size,
                        videoSize: video
                    )
                }
            )


        // ---------------------------------------------------------
        // Update UI
        // ---------------------------------------------------------

        DispatchQueue.main.async {

            hitboxResults =
                results


            // -----------------------------------------------------
            // Every required hitbox must be hit.
            // -----------------------------------------------------

            let allHit =
                !results.isEmpty
                &&
                results.allSatisfy {
                    $0.isHit
                }


            if allHit {

                movementSucceeded()
            }
        }
    }


    // =============================================================
    // MARK: - Coordinate Conversion
    // =============================================================

    private func convertPoint(
        _ point: CGPoint,
        viewSize: CGSize,
        videoSize: CGSize
    ) -> CGPoint {

        guard
            videoSize.width > 0,
            videoSize.height > 0,
            viewSize.width > 0,
            viewSize.height > 0
        else {
            return .zero
        }


        let videoWidth =
            videoSize.width

        let videoHeight =
            videoSize.height


        // =========================================================
        // Aspect ratios
        // =========================================================

        let videoAspect =
            videoWidth /
            videoHeight

        let viewAspect =
            viewSize.width /
            viewSize.height


        var scale: CGFloat

        var offsetX: CGFloat = 0

        var offsetY: CGFloat = 0


        // =========================================================
        // AVCaptureVideoPreviewLayer uses resizeAspectFill
        //
        // We must reproduce the same crop here.
        // =========================================================

        if viewAspect > videoAspect {

            scale =
                viewSize.width /
                videoWidth


            let renderedHeight =
                videoHeight * scale


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
                viewSize.height /
                videoHeight


            let renderedWidth =
                videoWidth * scale


            offsetX =
                (
                    viewSize.width
                    -
                    renderedWidth
                )
                /
                2
        }


        // =========================================================
        // FRONT CAMERA MIRROR
        // =========================================================

        let mirroredX =
            1.0 - point.x


        // =========================================================
        // VISION -> UI Y FLIP
        //
        // Vision:
        //     origin = bottom-left
        //
        // SwiftUI:
        //     origin = top-left
        // =========================================================

        let flippedY =
            1.0 - point.y


        // =========================================================
        // Final screen position
        // =========================================================

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
                flippedY
                *
                videoHeight
                *
                scale
                +
                offsetY
        )
    }


    // =============================================================
    // MARK: - Movement Success
    // =============================================================

    private func movementSucceeded() {

        guard
            !isMovementSuccessful
        else {
            return
        }


        // ---------------------------------------------------------
        // Success animation
        // ---------------------------------------------------------

        withAnimation(
            .spring(
                response: 0.35,
                dampingFraction: 0.7
            )
        ) {

            isMovementSuccessful =
                true
        }


        print(
            "🔥 ALL 8 HITBOXES HIT"
        )


        // ---------------------------------------------------------
        // Wait before next movement
        // ---------------------------------------------------------

        DispatchQueue.main.asyncAfter(
            deadline:
                .now() + 1.0
        ) {

            advanceMovement()
        }
    }


    // =============================================================
    // MARK: - Next Movement
    // =============================================================

    private func advanceMovement() {

        hitboxResults = []

        isMovementSuccessful =
            false


        if movementNumber <
            totalMovements {

            withAnimation(
                .easeInOut(
                    duration: 0.25
                )
            ) {

                movementNumber += 1
            }


            print(
                "➡️ Movement:",
                movementNumber
            )

        } else {

            print(
                "🎉 SEQUENCE COMPLETE"
            )


            // -----------------------------------------------------
            // For now restart at 1.
            // Replace this with your completion screen later.
            // -----------------------------------------------------

            movementNumber = 1
        }
    }


    // =============================================================
    // MARK: - Lifecycle
    // =============================================================

    private func handleAppear() {

        forceLandscape()


        // ---------------------------------------------------------
        // Reset tutorial
        // ---------------------------------------------------------

        tutorialController.reset()


        // ---------------------------------------------------------
        // Reset gameplay
        // ---------------------------------------------------------

        movementNumber =
            1

        hitboxResults =
            []

        isMovementSuccessful =
            false


        // ---------------------------------------------------------
        // Start camera
        // ---------------------------------------------------------

        visionService.startSession()
    }


    private func handleDisappear() {

        visionService.stopSession()
    }


    // =============================================================
    // MARK: - Landscape
    // =============================================================

    private func forceLandscape() {

        // ---------------------------------------------------------
        // Force device orientation
        // ---------------------------------------------------------

        UIDevice.current.setValue(
            UIInterfaceOrientation
                .landscapeLeft
                .rawValue,
            forKey:
                "orientation"
        )


        // ---------------------------------------------------------
        // iOS 16+
        // ---------------------------------------------------------

        if let windowScene =
            UIApplication.shared
                .connectedScenes
                .compactMap({
                    $0 as? UIWindowScene
                })
                .first {

            if #available(
                iOS 16.0,
                *
            ) {

                let preferences =
                    UIWindowScene
                        .GeometryPreferences
                        .iOS(
                            interfaceOrientations:
                                .landscape
                        )


                windowScene
                    .requestGeometryUpdate(
                        preferences
                    ) { error in

                        print(
                            "Landscape error:",
                            error
                                .localizedDescription
                        )
                    }
            }
        }


        UIViewController
            .attemptRotationToDeviceOrientation()
    }


    // =============================================================
    // MARK: - Debug
    // =============================================================

    #if DEBUG

    @ViewBuilder
    private var testControlsOverlay: some View {

        VStack {

            Spacer()


            HStack {

                Spacer()


                Menu {

                    // =================================================
                    // Tutorial
                    // =================================================

                    Button(
                        "1. Player Setup"
                    ) {

                        tutorialController
                            .debugSetStep(
                                .playerSetup
                            )

                        resetGameplay()
                    }


                    Button(
                        "2. Countdown 3"
                    ) {

                        tutorialController
                            .debugSetStep(
                                .countdown3
                            )

                        resetGameplay()
                    }


                    Button(
                        "3. Countdown 2"
                    ) {

                        tutorialController
                            .debugSetStep(
                                .countdown2
                            )

                        resetGameplay()
                    }


                    Button(
                        "4. Countdown 1"
                    ) {

                        tutorialController
                            .debugSetStep(
                                .countdown1
                            )

                        resetGameplay()
                    }


                    Button(
                        "5. Start Gameplay"
                    ) {

                        tutorialController
                            .debugSkipToStarted()

                        resetGameplay()
                    }


                    Divider()


                    // =================================================
                    // Gameplay
                    // =================================================

                    Button(
                        "Next Movement"
                    ) {

                        advanceMovement()
                    }


                    Button(
                        "Simulate Success"
                    ) {

                        movementSucceeded()
                    }


                    Divider()


                    Button(
                        "Reset Everything"
                    ) {

                        tutorialController.reset()

                        resetGameplay()
                    }

                } label: {

                    HStack(
                        spacing: 6
                    ) {

                        Image(
                            systemName:
                                "ladybug"
                        )

                        Text(
                            debugPhaseName
                        )
                    }
                    .font(
                        .system(
                            size: 12,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.white)
                    .padding(
                        .horizontal,
                        12
                    )
                    .padding(
                        .vertical,
                        7
                    )
                    .background(
                        Color.black
                            .opacity(0.75)
                    )
                    .clipShape(
                        Capsule()
                    )
                }
                .padding(
                    .trailing,
                    20
                )
                .padding(
                    .bottom,
                    20
                )
            }
        }
    }


    // =============================================================
    // MARK: - Reset Gameplay
    // =============================================================

    private func resetGameplay() {

        movementNumber =
            1

        hitboxResults =
            []

        isMovementSuccessful =
            false
    }


    // =============================================================
    // MARK: - Debug Phase
    // =============================================================

    private var debugPhaseName: String {

        if tutorialController.hasStarted {

            return
                "Gameplay \(movementNumber)/\(totalMovements)"
        }


        return
            tutorialController
                .currentStep
                .title
    }

    #else

    private var testControlsOverlay: some View {

        EmptyView()
    }

    #endif
}


// =============================================================
// MARK: - Preview
// =============================================================

#Preview("Pose Tracking View") {

    PoseTrackingView()
        .previewInterfaceOrientation(
            .landscapeLeft
        )
}
