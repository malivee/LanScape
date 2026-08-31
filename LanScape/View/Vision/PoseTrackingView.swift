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
    
    private var gameplayMusic = GameplayMusicManager.shared

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

    @State
    private var showingPoseInstructionPreview = false

    @State
    private var posePreviewTask: Task<Void, Never>? = nil

    @State
    private var sessionStartTime: Date? = nil

    @State
    private var sessionDuration: TimeInterval = 0

    @State
    private var showCompletionView = false

    private let totalMovements = 5


    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                // =================================================
                // BACKGROUND: LIVE CAMERA OR TUTORIAL ILLUSTRATION
                // =================================================

                if isLiveCameraPhase {
                    // 1. Live Camera Preview
                    CameraPreviewView(
                        session: visionService.captureSession,
                        onOrientationChanged: { orientation in
                            visionService.updateVideoOrientation(orientation)
                        }
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .ignoresSafeArea()

                    // 2. Real-time Joint Skeleton Tracking
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

                } else {
                    // Tutorial Explanation Slides: Static Illustration Image
                    Image("tutorial")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .ignoresSafeArea()
                }

                // =================================================
                // OVERLAY: TUTORIAL FLOW OR GAMEPLAY
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
                    .zIndex(999)
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

        .onChange(of: tutorialController.hasStarted) { _, hasStarted in
            if hasStarted {
                sessionStartTime = Date()
                triggerPosePreview()
            }
        }
        .fullScreenCover(isPresented: $showCompletionView) {
            CompletionView(
                durationSeconds: sessionDuration > 0 ? sessionDuration : 243,
                onRestart: {
                    showCompletionView = false
                    restartGameDirectly()
                },
                onSelectMusic: {
                    showCompletionView = false
                    dismiss()
                },
                onMainMenu: {
                    showCompletionView = false
                    dismiss()
                    NotificationCenter.default.post(name: NSNotification.Name("PopToRoot"), object: nil)
                }
            )
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

                if !showingPoseInstructionPreview {
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
                    .transition(.opacity)
                }


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
                // HEADER & POSE THUMBNAIL BADGE
                // =================================================

                VStack(
                    spacing: 0
                ) {

                    gameplayHeader

                    if !showingPoseInstructionPreview {
                        HStack {
                            Spacer()

                            MiniPoseThumbnailBadge(
                                imageName: currentPoseImageName,
                                size: 175
                            )
                            .padding(.trailing, 28)
                            .padding(.top, 6)
                            .id(movementNumber)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Spacer()
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )


                // =================================================
                // 5-SECOND CENTER POSE PREVIEW MODAL
                // =================================================

                if showingPoseInstructionPreview {

                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VStack {
                        Spacer()

                        PoseInstructionView(
                            mainTitle: currentPoseMainTitle,
                            subTitle: currentPoseSubTitle,
                            imageName: currentPoseImageName
                        )
                        .id(movementNumber)
                        .transition(.scale.combined(with: .opacity))

                        Spacer()
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .zIndex(50)
                }
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
        // Only validate during gameplay when preview has finished.
        // ---------------------------------------------------------

        guard
            tutorialController.hasStarted,
            !showingPoseInstructionPreview
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
        // Y POSITION
        // point.y is already normalized with top-left origin by VisionService
        // =========================================================

        let y =
            point.y
            *
            videoHeight
            *
            scale
            +
            offsetY


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
                y
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

            triggerPosePreview()

            print(
                "➡️ Movement:",
                movementNumber
            )

        } else {
            print(
                "🎉 SEQUENCE COMPLETE"
            )            
            gameplayMusic.stop()

            movementNumber = 1
            triggerPosePreview()
            
            sessionDuration = Date().timeIntervalSince(sessionStartTime ?? Date())
            showCompletionView = true
        }
    }

    private func restartGameDirectly() {
        movementNumber = 1
        hitboxResults = []
        isMovementSuccessful = false
        tutorialController.startReadyCountdown()
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
                // TUTORIAL DEBUG
                // =================================================

                Button("0. Persiapan Pemain") {

                    tutorialController.debugSetStep(.playerSetup)
                    resetGameplay()
                }

                Button("1. Intro Tutorial") {

                    tutorialController.debugSetStep(.tutorialIntro)
                    resetGameplay()
                }

                Button("2. Petunjuk Simbol & Warna") {

                    tutorialController.debugSetStep(.symbolColorGuide)
                    resetGameplay()
                }

                Button("4. Progress Header Guide") {

                    tutorialController.debugSetStep(.progressHeaderGuide)
                    resetGameplay()
                }

                Button("5. Kemunculan Pose") {

                    tutorialController.debugSetStep(.poseAppearanceExplanation)
                    resetGameplay()
                }

                Button("6. Kartu Pose Pertama") {

                    tutorialController.debugSetStep(.poseInstructionCard)
                    resetGameplay()
                }

                Button("7. Ikuti Posenya!") {

                    tutorialController.debugSetStep(.followPoseIntro)
                    resetGameplay()
                }

                Button("8. Titik Target Hitbox") {

                    tutorialController.debugSetStep(.hitboxTargetPreview)
                    resetGameplay()
                }

                Button("9. Penjelasan Titik Target") {

                    tutorialController.debugSetStep(.hitboxExplanation)
                    resetGameplay()
                }

                Button("10. Cocokkan Titik Target") {

                    tutorialController.debugSetStep(.matchPointsGuide)
                    resetGameplay()
                }

                Button("11. Instruksi Tahan Posisi") {

                    tutorialController.debugSetStep(.holdInstruction)
                    resetGameplay()
                }

                Button("12. Countdown Tahan 5s") {

                    tutorialController.debugSetStep(.practiceHoldCountdown)
                    resetGameplay()
                }

                Button("13. Keren Banget!") {

                    tutorialController.debugSetStep(.poseSuccess)
                    resetGameplay()
                }

                Button("14. Tutorial Selesai") {

                    tutorialController.debugSetStep(.tutorialCompleted)
                    resetGameplay()
                }

                Divider()

                // =================================================
                // GAMEPLAY
                // =================================================

                Button("Gerakan Selanjutnya") {

                    advanceMovement()
                }

                Button("Lanjut ke Gameplay") {

                    tutorialController.debugSkipToStarted()

                    resetGameplay()

                    // Setelah masuk gameplay,
                    // tampilkan kartu pose pertama.
                    DispatchQueue.main.async {
                        triggerPosePreview()
                    }
                }

                Button("Simulasikan Berhasil") {

                    movementSucceeded()
                }

                Divider()
                
                
                Button("Ganti Player 1") {
                    visionService.changePlayer1()
                }

                Button("Ganti Player 2") {
                    visionService.changePlayer2()
                }

                Divider()

                // =================================================
                // DIRECT POSE TEST
                // =================================================

                Button("Pose 1 (pose 1)") {

                    tutorialController.debugSkipToStarted()

                    movementNumber = 1

                    triggerPosePreview()
                }

                Button("Pose 2 (pose2)") {

                    tutorialController.debugSkipToStarted()

                    movementNumber = 2

                    triggerPosePreview()
                }

                Button("Pose 3 (pose3)") {

                    tutorialController.debugSkipToStarted()

                    movementNumber = 3

                    triggerPosePreview()
                }

                Button("Pose 4 (pose4)") {

                    tutorialController.debugSkipToStarted()

                    movementNumber = 4

                    triggerPosePreview()
                }

                Button("Pose 5 (pose5)") {

                    tutorialController.debugSkipToStarted()

                    movementNumber = 5

                    triggerPosePreview()
                }

                Divider()

                // =================================================
                // RESET
                // =================================================

                Button("Reset Everything") {

                    tutorialController.reset()
                    resetGameplay()
                }

            } label: {

                HStack(
                    spacing: 6
                ) {

                    Image(
                        systemName: "ladybug"
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
                .contentShape(
                    Capsule()
                )
            }
            .buttonStyle(.plain)
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
    .allowsHitTesting(true)
    .zIndex(999)
}


    // =============================================================
    // MARK: - Current Pose Info
    // =============================================================

    private var currentPoseMainTitle: String {
        switch movementNumber {
        case 1: return "Pose Pertama"
        case 2: return "Pose Kedua"
        case 3: return "Pose Ketiga"
        case 4: return "Pose Keempat"
        case 5: return "Pose Kelima"
        default: return "Pose \(movementNumber)"
        }
    }

    private var currentPoseSubTitle: String {
        switch movementNumber {
        case 1: return "Pose Fusion"
        default: return "Gerakan \(movementNumber)"
        }
    }

    private var currentPoseImageName: String {
        switch movementNumber {
        case 1: return "pose 1"
        case 2: return "pose2"
        case 3: return "pose3"
        case 4: return "pose4"
        case 5: return "pose5"
        default: return "pose 1"
        }
    }

    private func triggerPosePreview() {
        posePreviewTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            showingPoseInstructionPreview = true
            hitboxResults = []
            isMovementSuccessful = false
        }

        posePreviewTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.35)) {
                self.showingPoseInstructionPreview = false
            }
        }
    }


    // =============================================================
    // MARK: - Reset Gameplay
    // =============================================================

    private func resetGameplay() {

        posePreviewTask?.cancel()
        showingPoseInstructionPreview = false

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

    // =============================================================
    // MARK: - Live Camera Phase Helper
    // =============================================================

    private var isLiveCameraPhase: Bool {
        switch tutorialController.currentStep {
        case .playerSetup,
             .setupCountdown3,
             .setupCountdown2,
             .setupCountdown1,
             .readyCountdown3,
             .readyCountdown2,
             .readyCountdown1,
             .prePlayerSetup1,
             .prePlayerSetup2,
             .started:
            return true
        default:
            return tutorialController.hasStarted
        }
    }

    #else

    private var currentPoseImageName: String {
        switch movementNumber {
        case 1: return "pose 1"
        case 2: return "pose2"
        case 3: return "pose3"
        case 4: return "pose4"
        case 5: return "pose5"
        default: return "pose 1"
        }
    }

    private var isLiveCameraPhase: Bool {
        switch tutorialController.currentStep {
        case .playerSetup,
             .setupCountdown3,
             .setupCountdown2,
             .setupCountdown1,
             .readyCountdown3,
             .readyCountdown2,
             .readyCountdown1,
             .started:
            return true
        default:
            return tutorialController.hasStarted
        }
    }

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
