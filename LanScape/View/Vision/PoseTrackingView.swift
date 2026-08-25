import SwiftUI

/// Main screen for:
/// 1. Player positioning tutorial
/// 2. Countdown
/// 3. Core ML movement sequence validation
///
/// Flow:
///
/// Player Setup
///      ↓
/// Both players inside rectangles
///      ↓
/// Stance 1
///      ↓
/// Stance 2
///      ↓
/// Stance 3
///      ↓
/// Stance 4
///      ↓
/// Countdown 3 → 2 → 1
///      ↓
/// STARTED
///      ↓
/// Core ML Pose 1 → 2 → 3 → 4
///      ↓
/// Completed
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
    // MARK: - Effective Matching
    // =========================================================

    /// Core ML matching is only relevant after
    /// the tutorial has finished.
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
            // 1. CAMERA
            // =================================================

            CameraPreviewView(
                session:
                    visionService.captureSession
            )
            .ignoresSafeArea()


            // =================================================
            // 2. SKELETON
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
            // 3. TUTORIAL / MOVEMENT PHASE
            // =================================================

            if !tutorialController.hasStarted {

                tutorialPhase

            } else {

                movementPhase
            }


            // =================================================
            // 4. TEST / DEBUG CONTROLS
            // =================================================

            testControlsOverlay


            // =================================================
            // 5. COMPLETION MODAL
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
        // MARK: Lifecycle
        // =====================================================

        .onAppear {

            handleAppear()
        }

        .onDisappear {

            handleDisappear()
        }


        // =====================================================
        // MARK: Tutorial Completion
        // =====================================================

        .onChange(
            of:
                tutorialController.hasStarted
        ) { _, hasStarted in

            guard
                hasStarted
            else {
                return
            }

            startMovementSequence()
        }


        // =====================================================
        // MARK: Core ML Match
        // =====================================================

        .onChange(
            of:
                visionService.isMatching
        ) { _, isMatching in

            // Do not let Core ML advance
            // during tutorial/setup.

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

            // =================================================
            // CENTER DIVIDER
            // =================================================

            CenterDividerLineView()
                .ignoresSafeArea()


            // =================================================
            // MOVEMENT GUIDE
            // =================================================

            PoseGuideOverlayView(

                step:
                    currentStep,

                isMatching:
                    isEffectiveMatching
            )
            .ignoresSafeArea()


            // =================================================
            // HUD
            // =================================================

            VStack(
                spacing: 0
            ) {

                // ---------------------------------------------
                // Session Header
                // ---------------------------------------------

                PoseSessionHeaderView(

                    currentStepIndex:
                        currentStepIndex,

                    totalSteps:
                        steps.count,

                    onPause: {
                        dismiss()
                    }
                )


                // ---------------------------------------------
                // Status HUD
                // ---------------------------------------------

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


                // ---------------------------------------------
                // Instruction
                // ---------------------------------------------

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

        // Reset movement sequence.

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        // IMPORTANT:
        //
        // Do NOT call syncTargetPose()
        // here.
        //
        // Core ML movement validation
        // begins only after tutorial finishes.

        visionService.startSession()
    }


    private func handleDisappear() {

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        visionService.stopSession()
    }


    // =========================================================
    // MARK: - Start Movement Sequence
    // =========================================================

    private func startMovementSequence() {

        guard
            tutorialController.hasStarted
        else {
            return
        }

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil

        // Tell Core ML which movement to detect.

        syncTargetPose()
    }


    // =========================================================
    // MARK: - Sync Core ML Target
    // =========================================================

    private func syncTargetPose() {

        visionService.targetPose =
            "\(currentStep.id)"
    }


    // =========================================================
    // MARK: - Core ML Match Evaluation
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
        // MATCHED
        // =====================================================

        if isMatching {

            guard
                !isSuccessHolding,
                stepAdvanceTask == nil
            else {
                return
            }


            // ---------------------------------------------
            // Visual success state
            // ---------------------------------------------

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


            // ---------------------------------------------
            // Require stable match for 1.2 seconds
            // ---------------------------------------------

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

                        // Make sure the pose is
                        // still matching when
                        // the hold completes.

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

            // Pose broke before the
            // 1.2 second hold finished.

            if !isSuccessHolding {

                stepAdvanceTask?.cancel()

                stepAdvanceTask =
                    nil
            }
        }
    }


    // =========================================================
    // MARK: - Advance Movement
    // =========================================================

    private func advanceToNextStep() {

        guard
            tutorialController.hasStarted
        else {
            return
        }


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


            // Tell Core ML about the
            // next movement.

            syncTargetPose()


        } else {

            // =============================================
            // ALL MOVEMENTS COMPLETE
            // =============================================

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

        // Cancel movement timer.

        stepAdvanceTask?.cancel()

        stepAdvanceTask =
            nil


        // Reset movement.

        currentStepIndex =
            0

        isSuccessHolding =
            false

        isCompleted =
            false


        // Reset tutorial.

        tutorialController.reset()


        // Remove the Core ML target
        // until tutorial is complete.

        visionService.targetPose =
            ""
    }


    // =========================================================
    // MARK: - Force Landscape
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
    // MARK: - Test Controls
    // =========================================================

    @ViewBuilder
    private var testControlsOverlay:
        some View {

        VStack {

            Spacer()

            HStack {

                Menu {

                    // =========================================
                    // Tutorial Test
                    // =========================================

                    if !tutorialController.hasStarted {

                        Button(
                            "Reset Tutorial"
                        ) {

                            tutorialController.reset()
                        }

                    } else {

                        // =====================================
                        // Core ML Test
                        // =====================================

                        Button(
                            "Simulasikan Cocok (Next Step)"
                        ) {

                            handleMatchEvaluation(
                                isMatching:
                                    true
                            )
                        }

                        Divider()


                        // =====================================
                        // Jump to Movement
                        // =====================================

                        ForEach(
                            0..<steps.count,
                            id:
                                \.self
                        ) { index in

                            Button(
                                "Lompat ke \(steps[index].title)"
                            ) {

                                stepAdvanceTask?.cancel()

                                stepAdvanceTask =
                                    nil

                                withAnimation {

                                    currentStepIndex =
                                        index

                                    isSuccessHolding =
                                        false

                                    isCompleted =
                                        false
                                }

                                syncTargetPose()
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
                                "slider.horizontal.3"
                        )

                        if tutorialController.hasStarted {

                            Text(
                                "Target: \(currentStep.title) (\(currentStep.id))"
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
                        .white.opacity(
                            0.85
                        )
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
                            0.6
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
    }
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
