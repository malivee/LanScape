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
    private var visionService =
        VisionService()

    @StateObject
    private var tutorialController =
        TutorialController()


    // =========================================================
    // MARK: - Environment
    // =========================================================

    @Environment(\.dismiss)
    private var dismiss


    // =========================================================
    // MARK: - Gameplay
    // =========================================================

    @State
    private var hitboxResults:
        [HitboxResult] = []

    @State
    private var isMovementSuccessful =
        false

    @State
    private var movementNumber =
        1

    private let totalMovements =
        5


    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {

        ZStack {

            // =================================================
            // CAMERA
            // =================================================

            CameraPreviewView(

                session:
                    visionService
                    .captureSession,

                onOrientationChanged: {
                    orientation in

                    visionService
                        .updateVideoOrientation(
                            orientation
                        )
                }
            )
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
            // DEBUG
            // =================================================

            testControlsOverlay
        }

        .onAppear {

            handleAppear()
        }

        .onDisappear {

            handleDisappear()
        }

        // IMPORTANT:
        // Whenever Vision produces new people,
        // check the hitboxes again.

        .onReceive(
            visionService
                .poseModel
                .$detectedPeople
        ) { people in

            updateHitboxes(
                people:
                    people
            )
        }
    }


    // =========================================================
    // MARK: - Tutorial
    // =========================================================

    @ViewBuilder
    private var tutorialPhase:
        some View {

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


    // =========================================================
    // MARK: - Gameplay
    // =========================================================

    @ViewBuilder
    private var gameplayPhase:
        some View {

        GeometryReader { geometry in

            ZStack {

                // ---------------------------------------------
                // Center divider
                // ---------------------------------------------

                CenterDividerLineView()
                    .ignoresSafeArea()


                // ---------------------------------------------
                // Hitboxes
                // ---------------------------------------------

                MovementHitboxOverlayView(

                    hitboxes:
                        MovementHitboxLayout
                        .hitboxes(),

                    results:
                        hitboxResults,

                    viewSize:
                        geometry.size
                )


                // ---------------------------------------------
                // Success
                // ---------------------------------------------

                if isMovementSuccessful {

                    Text("PERFECT!")

                        .font(
                            .system(
                                size: 64,
                                weight: .black,
                                design: .rounded
                            )
                        )

                        .foregroundColor(
                            .white
                        )

                        .shadow(
                            color:
                                .black.opacity(
                                    0.7
                                ),

                            radius:
                                12
                        )
                        .transition(
                            .scale
                            .combined(
                                with: .opacity
                            )
                        )
                }


                // ---------------------------------------------
                // Header
                // ---------------------------------------------

                gameplayHeader
            }
        }
        .ignoresSafeArea()
    }


    // =========================================================
    // MARK: - Header
    // =========================================================

    @ViewBuilder
    private var gameplayHeader:
        some View {

        VStack {

            HStack {

                Button {

                    dismiss()

                } label: {

                    ZStack {

                        Circle()
                            .fill(
                                Color.white
                                .opacity(0.85)
                            )
                            .frame(
                                width: 60,
                                height: 60
                            )

                        Image(
                            systemName:
                                "pause.fill"
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .bold
                            )
                        )
                        .foregroundColor(
                            .black
                        )
                    }
                }
                .buttonStyle(.plain)


                Spacer()


                Text(
                    "\(movementNumber)/\(totalMovements) Gerakan"
                )
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(
                    .black
                )


                Spacer()


                Color.clear
                    .frame(
                        width: 60,
                        height: 60
                    )
            }
            .padding(
                .horizontal,
                40
            )
            .padding(
                .top,
                20
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .top
        )
    }


    // =========================================================
    // MARK: - Hitbox Processing
    // =========================================================

    private func updateHitboxes(
        people:
            [DetectedPerson]
    ) {

        guard
            tutorialController.hasStarted
        else {

            return
        }


        let hitboxes =
            MovementHitboxLayout
            .hitboxes()


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


        // IMPORTANT:
        // Use the actual window size if available.

        let viewSize =
            currentViewSize()


        guard
            viewSize.width > 0,
            viewSize.height > 0
        else {

            return
        }


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


        DispatchQueue.main.async {

            hitboxResults =
                results


            let allHit =
                !results.isEmpty &&
                results.allSatisfy {
                    $0.isHit
                }


            if allHit {

                movementSucceeded()
            }
        }
    }


    // =========================================================
    // MARK: - View Size
    // =========================================================

    private func currentViewSize()
        -> CGSize {

        if let scene =
            UIApplication.shared
            .connectedScenes
            .compactMap({
                $0 as? UIWindowScene
            })
            .first {

            return scene.screen.bounds.size
        }

        return UIScreen.main.bounds.size
    }


    // =========================================================
    // MARK: - Coordinate Conversion
    // =========================================================

    private func convertPoint(

        _ point:
            CGPoint,

        viewSize:
            CGSize,

        videoSize:
            CGSize

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


        let videoAspect =
            videoWidth /
            videoHeight

        let viewAspect =
            viewSize.width /
            viewSize.height


        let scale:
            CGFloat

        var offsetX:
            CGFloat = 0

        var offsetY:
            CGFloat = 0


        // =====================================================
        // resizeAspectFill
        // =====================================================

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


        // =====================================================
        // Front camera mirroring
        // =====================================================

        let mirroredX =
            1.0 - point.x


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


    // =========================================================
    // MARK: - Success
    // =========================================================

    private func movementSucceeded() {

        guard
            !isMovementSuccessful
        else {

            return
        }


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


        DispatchQueue.main.asyncAfter(
            deadline:
                .now() + 1.0
        ) {

            advanceMovement()
        }
    }


    // =========================================================
    // MARK: - Next Movement
    // =========================================================

    private func advanceMovement() {

        hitboxResults = []

        isMovementSuccessful =
            false


        if movementNumber <
            totalMovements {

            withAnimation {

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

            movementNumber = 1
        }
    }


    // =========================================================
    // MARK: - Lifecycle
    // =========================================================

    private func handleAppear() {

        forceLandscape()

        tutorialController.reset()

        movementNumber =
            1

        hitboxResults =
            []

        isMovementSuccessful =
            false

        visionService.startSession()
    }


    private func handleDisappear() {

        visionService.stopSession()
    }


    // =========================================================
    // MARK: - Landscape
    // =========================================================

    private func forceLandscape() {

        UIDevice.current.setValue(

            UIInterfaceOrientation
                .landscapeLeft
                .rawValue,

            forKey:
                "orientation"
        )


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


    // =========================================================
    // MARK: - Debug
    // =========================================================

    #if DEBUG

    @ViewBuilder
    private var testControlsOverlay:
        some View {

        VStack {

            Spacer()

            HStack {

                Spacer()

                Menu {

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
                    .foregroundColor(
                        .white
                    )
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


    private func resetGameplay() {

        movementNumber =
            1

        hitboxResults =
            []

        isMovementSuccessful =
            false
    }


    private var debugPhaseName:
        String {

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

    private var testControlsOverlay:
        some View {

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
