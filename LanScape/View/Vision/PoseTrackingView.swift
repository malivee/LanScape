//
//  PoseTrackingView.swift
//  LanScape
//

import SwiftUI
import UIKit

struct PoseTrackingView:
    View {

    // =========================================================
    // MARK: - Services
    // =========================================================

    @StateObject
    private var visionService =
        VisionService()


    @StateObject
    private var tutorialController =
        TutorialController()


    @StateObject
    private var movementIntroTutorial =
        MovementIntroTutorial()


    // =========================================================
    // MARK: - Environment
    // =========================================================

    @Environment(\.dismiss)
    private var dismiss


    // =========================================================
    // MARK: - Movement
    // =========================================================

    @State
    private var currentStepIndex:
        Int = 0


    @State
    private var isSuccessHolding:
        Bool = false


    @State
    private var isCompleted:
        Bool = false


    @State
    private var stepAdvanceTask:
        Task<Void, Never>? =
            nil


    private let steps:
        [PoseStep] =
        PoseStep.sampleSequence


    private var currentStep:
        PoseStep {

        steps[
            min(
                currentStepIndex,
                steps.count - 1
            )
        ]
    }


    // =========================================================
    // MARK: - Effective Match
    // =========================================================

    private var isEffectiveMatching:
        Bool {

        guard
            tutorialController.hasStarted,
            !movementIntroTutorial.isShowing
        else {

            return false
        }


        return
            visionService.isMatching
            ||
            isSuccessHolding
    }


    // =========================================================
    // MARK: BODY
    // =========================================================

    var body:
        some View {

        ZStack {

            // =================================================
            // CAMERA
            // =================================================

            CameraPreviewView(
                session:
                    visionService.captureSession
            )
            .ignoresSafeArea()


            // =================================================
            // SKELETON
            // =================================================

            PoseSkeletonOverlayView(

                detectedPeople:
                    visionService
                        .poseModel
                        .detectedPeople,

                videoSize:
                    visionService
                        .poseModel
                        .videoSize,

                isMatching:
                    isEffectiveMatching
            )
            .ignoresSafeArea()


            // =================================================
            // GAME FLOW
            // =================================================

            if !tutorialController.hasStarted {

                // ---------------------------------------------
                // PLAYER SETUP / COUNTDOWN
                // ---------------------------------------------

                tutorialPhase

            } else {

                // ---------------------------------------------
                // AFTER "MULAI"
                // ---------------------------------------------

                if movementIntroTutorial.isShowing {

                    // -----------------------------------------
                    // MOVE #1 TUTORIAL
                    // -----------------------------------------

                    MovementIntroTutorialView(

                        tutorial:
                            movementIntroTutorial,

                        step:
                            currentStep
                    )
                    .ignoresSafeArea()

                } else {

                    // -----------------------------------------
                    // ACTUAL MOVEMENT
                    // -----------------------------------------

                    movementPhase
                }
            }


            // =================================================
            // DEBUG
            // =================================================

            testControlsOverlay


            // =================================================
            // COMPLETED
            // =================================================

            if isCompleted {

                PoseCompletionModalView(

                    onRestart:
                        restartSequence,

                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(
                    .opacity
                        .combined(
                            with: .scale
                        )
                )
            }
        }


        // =====================================================
        // APPEAR
        // =====================================================

        .onAppear {

            handleAppear()
        }


        // =====================================================
        // DISAPPEAR
        // =====================================================

        .onDisappear {

            handleDisappear()
        }


        // =====================================================
        // MULAI → FIRST MOVEMENT TUTORIAL
        // =====================================================

        .onChange(
            of:
                tutorialController.hasStarted
        ) { _, started in

            guard
                started
            else {
                return
            }


            beginMovementSequence()
        }


        // =====================================================
        // MOVEMENT INTRO FINISHED
        // =====================================================

        .onChange(
            of:
                movementIntroTutorial.isShowing
        ) { _, showing in

            guard
                !showing,
                tutorialController.hasStarted
            else {
                return
            }


            // =============================================
            // Now the actual first movement begins.
            // =============================================

            syncTargetPose()
        }


        // =====================================================
        // CORE ML MATCH
        // =====================================================

        .onChange(
            of:
                visionService.isMatching
        ) { _, isMatching in

            guard
                tutorialController.hasStarted,
                !movementIntroTutorial.isShowing
            else {
                return
            }


            handleMatchEvaluation(
                isMatching:
                    isMatching
            )
        }
    }


    // =========================================================
    // MARK: - Tutorial Phase
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
    // MARK: - Movement Phase
    // =========================================================

    @ViewBuilder
    private var movementPhase:
        some View {

        ZStack {

            // =================================================
            // CENTER DIVIDER
            // =================================================

            CenterDividerLineView()
                .ignoresSafeArea()


            // =================================================
            // EXISTING MOVEMENT GUIDE
            // =================================================

            PoseGuideOverlayView(

                step:
                    currentStep,

                isMatching:
                    isEffectiveMatching
            )
            .ignoresSafeArea()


            // =================================================
            // HEADER / HUD
            // =================================================

            VStack(
                spacing:
                    0
            ) {

                PoseSessionHeaderView(

                    currentStepIndex:
                        currentStepIndex,

                    totalSteps:
                        steps.count,

                    onPause: {
                        dismiss()
                    }
                )


                PoseStatusHudView(

                    isP1Detected:
                        visionService
                            .poseModel
                            .detectedPeople
                            .contains {
                                $0.personIndex == 0
                            },

                    isP2Detected:
                        visionService
                            .poseModel
                            .detectedPeople
                            .contains {
                                $0.personIndex == 1
                            },

                    isMatching:
                        isEffectiveMatching,

                    prediction:
                        visionService
                            .prediction,

                    targetPose:
                        visionService
                            .targetPose,

                    confidence:
                        visionService
                            .confidence
                )
                .padding(
                    .top,
                    8
                )


                Spacer()


                InstructionBannerView(

                    text:
                        isEffectiveMatching
                        ? "Bagus! Gerakan Cocok!"
                        : "Ikuti gerakannya",

                    isSuccess:
                        isEffectiveMatching
                )
                .padding(
                    .bottom,
                    290
                )
            }
        }
    }


    // =========================================================
    // MARK: - Appear
    // =========================================================

    private func handleAppear() {

        // ---------------------------------------------
        // Force landscape
        // ---------------------------------------------

        forceLandscape()


        // ---------------------------------------------
        // Reset tutorial
        // ---------------------------------------------

        tutorialController.reset()


        // ---------------------------------------------
        // Reset movement tutorial
        // ---------------------------------------------

        movementIntroTutorial.reset()


        // ---------------------------------------------
        // Reset movement
        // ---------------------------------------------

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false


        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil


        // ---------------------------------------------
        // Don't validate a movement yet.
        // ---------------------------------------------

        visionService.targetPose =
            ""


        // ---------------------------------------------
        // Start camera
        // ---------------------------------------------

        visionService.startSession()
    }


    // =========================================================
    // MARK: - Disappear
    // =========================================================

    private func handleDisappear() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        visionService.stopSession()
    }


    // =========================================================
    // MARK: - Begin Movement Sequence
    // =========================================================

    private func beginMovementSequence() {

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false


        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil


        // =====================================================
        // IMPORTANT
        //
        // The first movement starts with the tutorial.
        //
        // We DON'T set targetPose yet.
        // =====================================================

        visionService.targetPose =
            ""


        movementIntroTutorial.start()
    }


    // =========================================================
    // MARK: - Sync Target
    // =========================================================

    private func syncTargetPose() {

        visionService.targetPose =
            "\(currentStep.id)"

        visionService.resetMatchingState()
    }


    // =========================================================
    // MARK: - Match Evaluation
    // =========================================================

    private func handleMatchEvaluation(
        isMatching:
            Bool
    ) {

        guard
            tutorialController.hasStarted,
            !movementIntroTutorial.isShowing,
            !isCompleted
        else {
            return
        }


        if isMatching {

            guard
                stepAdvanceTask == nil
            else {
                return
            }


            // =============================================
            // Visual success
            // =============================================

            withAnimation(
                .spring(
                    response:
                        0.5,

                    dampingFraction:
                        0.75
                )
            ) {

                isSuccessHolding =
                    true
            }


            // =============================================
            // Hold for 1.0 second to confirm pose
            // =============================================

            stepAdvanceTask =
                Task { @MainActor in

                    do {
                        try await Task.sleep(
                            nanoseconds:
                                1_000_000_000
                        )
                    } catch {
                        return
                    }

                    guard
                        !Task.isCancelled,
                        self.visionService.isMatching
                    else {
                        withAnimation {
                            self.isSuccessHolding = false
                        }
                        self.stepAdvanceTask = nil
                        return
                    }

                    self.advanceToNextMovement()
                }


        } else {

            // When match is lost, cancel pending advance immediately
            stepAdvanceTask?.cancel()
            stepAdvanceTask =
                nil

            if isSuccessHolding {
                withAnimation {
                    isSuccessHolding =
                        false
                }
            }
        }
    }


    // =========================================================
    // MARK: - Advance Movement
    // =========================================================

    private func advanceToNextMovement() {

        stepAdvanceTask?.cancel()
        stepAdvanceTask =
            nil

        if currentStepIndex + 1 < steps.count {

            withAnimation(
                .easeInOut(
                    duration:
                        0.35
                )
            ) {

                currentStepIndex += 1

                isSuccessHolding =
                    false
            }


            // =============================================
            // Next movement starts immediately.
            // =============================================

            syncTargetPose()

        } else {

            withAnimation(
                .spring(
                    response:
                        0.5,

                    dampingFraction:
                        0.8
                )
            ) {

                isCompleted =
                    true

                isSuccessHolding =
                    false
            }
        }
    }


    // =========================================================
    // MARK: - Restart
    // =========================================================

    private func restartSequence() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil


        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false


        tutorialController.reset()

        movementIntroTutorial.reset()


        visionService.targetPose =
            ""
    }


    // =========================================================
    // MARK: - Landscape
    // =========================================================

    private func forceLandscape() {

        UIDevice.current.setValue(
            UIInterfaceOrientation.landscapeRight.rawValue,
            forKey: "orientation"
        )

        if let windowScene =
            UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {

            if #available(iOS 16.0, *) {

                let preferences =
                    UIWindowScene.GeometryPreferences.iOS(
                        interfaceOrientations:
                            .landscapeRight
                    )

                windowScene.requestGeometryUpdate(
                    preferences
                ) { error in

                    print(
                        "Landscape rotation error:",
                        error.localizedDescription
                    )
                }
            }
        }

        UIViewController
            .attemptRotationToDeviceOrientation()
    }

    // =========================================================
    // MARK: - DEBUG
    // =========================================================

    #if DEBUG

    private var testControlsOverlay:
        some View {

        VStack {

            Spacer()


            HStack {

                Spacer()


                Menu {

                    // =========================================
                    // PLAYER SETUP
                    // =========================================

                    Button(
                        "1. Player Setup"
                    ) {

                        resetDebugState()

                        tutorialController
                            .debugSetStep(
                                .playerSetup
                            )
                    }


                    // =========================================
                    // COUNTDOWN 3
                    // =========================================

                    Button(
                        "2. Countdown 3"
                    ) {

                        movementIntroTutorial.finish()

                        tutorialController
                            .debugSetStep(
                                .countdown3
                            )
                    }


                    // =========================================
                    // COUNTDOWN 2
                    // =========================================

                    Button(
                        "3. Countdown 2"
                    ) {

                        movementIntroTutorial.finish()

                        tutorialController
                            .debugSetStep(
                                .countdown2
                            )
                    }


                    // =========================================
                    // COUNTDOWN 1
                    // =========================================

                    Button(
                        "4. Countdown 1"
                    ) {

                        movementIntroTutorial.finish()

                        tutorialController
                            .debugSetStep(
                                .countdown1
                            )
                    }


                    // =========================================
                    // MULAI
                    // =========================================

                    Button(
                        "5. Mulai"
                    ) {

                        movementIntroTutorial.finish()

                        tutorialController
                            .debugSkipToStarted()

                        beginMovementSequence()
                    }


                    // =========================================
                    // MOVE #1 TUTORIAL PAGE 1
                    // =========================================

                    Button(
                        "6. Move #1 Tutorial 1"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.start()
                    }


                    // =========================================
                    // MOVE #1 TUTORIAL PAGE 2
                    // =========================================

                    Button(
                        "7. Move #1 Tutorial 2"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.start()

                        movementIntroTutorial.next()
                    }


                    // =========================================
                    // MOVE #1 ACTUAL
                    // =========================================

                    Button(
                        "8. Move #1 Actual"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.finish()

                        currentStepIndex =
                            0

                        syncTargetPose()
                    }


                    // =========================================
                    // MOVE #2
                    // =========================================

                    Button(
                        "9. Move #2"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.finish()

                        currentStepIndex =
                            min(
                                1,
                                steps.count - 1
                            )

                        syncTargetPose()
                    }


                    // =========================================
                    // MOVE #3
                    // =========================================

                    Button(
                        "10. Move #3"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.finish()

                        currentStepIndex =
                            min(
                                2,
                                steps.count - 1
                            )

                        syncTargetPose()
                    }


                    // =========================================
                    // MOVE #4
                    // =========================================

                    Button(
                        "11. Move #4"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.finish()

                        currentStepIndex =
                            min(
                                3,
                                steps.count - 1
                            )

                        syncTargetPose()
                    }


                    // =========================================
                    // MOVE #5
                    // =========================================

                    Button(
                        "12. Move #5"
                    ) {

                        resetDebugMovement()

                        tutorialController
                            .debugSkipToStarted()

                        movementIntroTutorial.finish()

                        currentStepIndex =
                            min(
                                4,
                                steps.count - 1
                            )

                        syncTargetPose()
                    }


                    Divider()


                    // =========================================
                    // RESET
                    // =========================================

                    Button(
                        "Reset Everything"
                    ) {

                        resetEverything()
                    }

                } label: {

                    HStack(
                        spacing:
                            6
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
                    .padding(
                        .horizontal,
                        12
                    )
                    .padding(
                        .vertical,
                        7
                    )
                    .background(
                        Color.black.opacity(
                            0.75
                        )
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


    // =========================================================
    // MARK: - Debug Reset
    // =========================================================

    private func resetDebugState() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        movementIntroTutorial.reset()

        visionService.targetPose =
            ""
    }


    private func resetDebugMovement() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false
    }


    private func resetEverything() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        tutorialController.reset()

        movementIntroTutorial.reset()

        visionService.targetPose =
            ""
    }


    // =========================================================
    // MARK: - Debug Name
    // =========================================================

    private var debugPhaseName:
        String {

        if movementIntroTutorial.isShowing {

            switch movementIntroTutorial.currentPage {

            case .followMovement:
                return "Move #1 Tutorial 1"

            case .moveCloser:
                return "Move #1 Tutorial 2"
            }
        }


        if tutorialController.hasStarted {

            return "Move #\(currentStepIndex + 1)"
        }


        return tutorialController
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

#Preview(
    "Pose Tracking View"
) {

    PoseTrackingView()
        .previewInterfaceOrientation(
            .landscapeRight
        )
}
