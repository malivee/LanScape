import SwiftUI

/// Main screen:
///
/// Tutorial:
/// Player Setup
/// → Stance 1
/// → Stance 2
/// → Stance 3
/// → Stance 4
/// → Countdown
/// → Started
///
/// Then:
///
/// Core ML:
/// Pose 1
/// → Pose 2
/// → Pose 3
/// → Pose 4
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

    @Environment(\.dismiss)
    private var dismiss


    // =========================================================
    // MARK: - Core ML Movement Sequence
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
        Task<Void, Never>? = nil

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
    // MARK: - Matching
    // =========================================================

    private var isEffectiveMatching:
        Bool {

        guard
            tutorialController.hasStarted
        else {
            return false
        }

        return
            visionService.isMatching
            ||
            isSuccessHolding
    }


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
            // TUTORIAL OR MOVEMENT
            // =================================================

            if !tutorialController.hasStarted {

                tutorialPhase

            } else {

                movementPhase
            }


            // =================================================
            // DEBUG CONTROLS
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
        // LIFECYCLE
        // =====================================================

        .onAppear {

            handleAppear()
        }

        .onDisappear {

            handleDisappear()
        }


        // =====================================================
        // TUTORIAL FINISHED
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

            startMovementSequence()
        }


        // =====================================================
        // CORE ML MATCH
        // =====================================================

        .onChange(
            of:
                visionService.isMatching
        ) { _, isMatching in

            // Do not process Core ML movement
            // matching during tutorial.

            guard
                tutorialController.hasStarted
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

            // ---------------------------------------------
            // Divider
            // ---------------------------------------------

            CenterDividerLineView()
                .ignoresSafeArea()


            // ---------------------------------------------
            // Movement Guide
            // ---------------------------------------------

            PoseGuideOverlayView(

                step:
                    currentStep,

                isMatching:
                    isEffectiveMatching
            )
            .ignoresSafeArea()


            // ---------------------------------------------
            // HUD
            // ---------------------------------------------

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
    // MARK: - Lifecycle
    // =========================================================

    private func handleAppear() {

        forceLandscape()

        // Reset tutorial.

        tutorialController.reset()

        // Reset Core ML sequence.

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        // Do not start Core ML target
        // until tutorial finishes.

        visionService.targetPose =
            ""

        visionService.startSession()
    }


    private func handleDisappear() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        visionService.stopSession()
    }


    // =========================================================
    // MARK: - Start Core ML Sequence
    // =========================================================

    private func startMovementSequence() {

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        syncTargetPose()
    }


    // =========================================================
    // MARK: - Target Pose
    // =========================================================

    private func syncTargetPose() {

        visionService.targetPose =
            "\(currentStep.id)"
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
            !isCompleted
        else {
            return
        }


        // =====================================================
        // MATCH
        // =====================================================

        if isMatching {

            guard
                !isSuccessHolding,
                stepAdvanceTask == nil
            else {
                return
            }


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


            // Hold for 1.2 seconds.

            stepAdvanceTask =
                Task {

                    try? await Task.sleep(
                        nanoseconds:
                            1_200_000_000
                    )


                    guard
                        !Task.isCancelled
                    else {
                        return
                    }


                    await MainActor.run {

                        guard
                            visionService.isMatching
                        else {

                            isSuccessHolding =
                                false

                            stepAdvanceTask =
                                nil

                            return
                        }


                        advanceToNextStep()

                        stepAdvanceTask =
                            nil
                    }
                }


        // =====================================================
        // NOT MATCHED
        // =====================================================

        } else {

            if !isSuccessHolding {

                stepAdvanceTask?.cancel()

                stepAdvanceTask =
                    nil
            }
        }
    }


    // =========================================================
    // MARK: - Next Movement
    // =========================================================

    private func advanceToNextStep() {

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

        visionService.targetPose =
            ""
    }


    // =========================================================
    // MARK: - Landscape
    // =========================================================

    private func forceLandscape() {

        UIDevice.current.setValue(
            UIInterfaceOrientation
                .landscapeRight
                .rawValue,

            forKey:
                "orientation"
        )

        UIViewController
            .attemptRotationToDeviceOrientation()
    }


    // =========================================================
    // MARK: - DEBUG MENU
    // =========================================================

    @ViewBuilder
    private var testControlsOverlay:
        some View {

        #if DEBUG

        VStack {

            Spacer()

            HStack {

                Menu {

                    // =========================================
                    // NEXT TUTORIAL STEP
                    // =========================================

                    if !tutorialController.hasStarted {

                        Button(
                            "Next Tutorial Step"
                        ) {

                            tutorialController
                                .debugNextStep()
                        }


                        // =====================================
                        // SKIP ENTIRE TUTORIAL
                        // =====================================

                        Button(
                            "Skip to Started"
                        ) {

                            tutorialController
                                .skipToStarted()
                        }


                        Divider()


                        // =====================================
                        // RESET
                        // =====================================

                        Button(
                            "Reset Tutorial"
                        ) {

                            tutorialController
                                .reset()

                            visionService
                                .targetPose =
                                ""
                        }

                    } else {

                        // =====================================
                        // SIMULATE MATCH
                        // =====================================

                        Button(
                            "Simulasikan Cocok"
                        ) {

                            handleMatchEvaluation(
                                isMatching:
                                    true
                            )
                        }


                        Divider()


                        // =====================================
                        // JUMP TO MOVEMENT
                        // =====================================

                        ForEach(
                            0..<steps.count,
                            id:
                                \.self
                        ) { index in

                            Button(
                                "Lompat ke \(steps[index].title)"
                            ) {

                                jumpToMovement(
                                    index:
                                        index
                                )
                            }
                        }
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

                        if tutorialController.hasStarted {

                            Text(
                                "Target: \(currentStep.title)"
                            )

                        } else {

                            Text(
                                tutorialController
                                    .currentStep
                                    .title
                            )
                        }
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
                        10
                    )
                    .padding(
                        .vertical,
                        6
                    )
                    .background(
                        Color.black.opacity(
                            0.65
                        )
                    )
                    .clipShape(
                        Capsule()
                    )
                }

                Spacer()
            }
            .padding(
                .leading,
                20
            )
            .padding(
                .bottom,
                20
            )
        }

        #endif
    }


    // =========================================================
    // MARK: - DEBUG Movement Jump
    // =========================================================

    #if DEBUG

    private func jumpToMovement(
        index:
            Int
    ) {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        currentStepIndex =
            index

        isSuccessHolding =
            false

        isCompleted =
            false

        syncTargetPose()
    }

    #endif
}


// =============================================================
// MARK: - Preview
// =============================================================

#Preview("Pose Tracking View") {

    PoseTrackingView()
        .previewInterfaceOrientation(
            .landscapeRight
        )
}
