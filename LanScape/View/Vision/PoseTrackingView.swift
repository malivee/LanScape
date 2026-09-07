//
//  PoseTrackingView.swift
//  LanScape
//

import SwiftUI
import UIKit
import AVFoundation

struct PoseTrackingView: View {

    // =========================================================
    // MARK: - Enums
    // =========================================================

    enum PoseCaptureState: Equatable {
        case showingPosePreview(secondsRemaining: Int)
        case countdown(number: Int)
        case flashShutter
        case photoCaptured
        case miniGameTutorial(game: MiniGameMetadata)
        case interactionChallenge(game: MiniGameMetadata)
        case challengeSuccess
        case challengeFailure(penalty: PenaltyStickerType)
    }

    // =========================================================
    // MARK: - Services & Environment
    // =========================================================

    var selectedMusic: MusicData?
    
    init(selectedMusic: MusicData? = nil) {
        self.selectedMusic = selectedMusic
    }

    private var musicService = BackgroundMusicService.shared
    private var cameraService = CameraService.shared

    @State
    private var audioMonitor = AudioLevelMonitor()

    @State
    private var motionService = MotionDetectionService()

    @State
    private var penaltyService = FacePenaltyService()

    @State
    private var visionHandTracker = VisionHandTrackingService()

    @Environment(\.dismiss)
    private var dismiss

    // =========================================================
    // MARK: - State
    // =========================================================

    @State
    private var sessionMiniGames: [MiniGameMetadata] = MiniGameCatalog.selectRandomChallenges(count: 4)

    @State
    private var movementNumber: Int = 1

    private let totalMovements: Int = 5

    @State
    private var captureState: PoseCaptureState = .countdown(number: 5)

    @State
    private var capturedPhotos: [UIImage] = []

    @State
    private var activeTimerTask: Task<Void, Never>? = nil

    @State
    private var sessionStartTime: Date? = nil

    @State
    private var sessionDuration: TimeInterval = 0

    @State
    private var showCompletionView: Bool = false

    @State
    private var showCustomizePhotoView: Bool = false

    @State
    private var shutterFlashOpacity: Double = 0.0

    @State
    private var hasInitialized: Bool = false

    @State
    private var isSessionLoading: Bool = true

    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Live Camera Preview
                CameraPreviewView(
                    session: cameraService.captureSession,
                    onOrientationChanged: { orientation in
                        cameraService.updateVideoOrientation(orientation)
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()


                // 2.5 Live Face Penalty Overlay (renders stickers over faces when penalty is active)
                FacePenaltyLiveOverlay(penaltyService: penaltyService, geometry: geometry)

                // 3. Header & Mini Badge
                VStack(spacing: 0) {
                    gameplayHeader

                    if case .countdown = captureState {
                        // Top-right mini pose thumbnail badge during countdown only
                        HStack {
                            Spacer()
                            MiniPoseThumbnailBadge(
                                imageName: currentPoseImageName,
                                size: UIDevice.isIPad ? 175 : 105
                            )
                            .padding(.trailing, UIDevice.isIPad ? 28 : 50)
                            .padding(.top, 6)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)

                // 4. Overlays according to state
                switch captureState {
                case .showingPosePreview(let secondsRemaining):
                    posePreviewOverlay(secondsRemaining: secondsRemaining)

                case .countdown(let number):
                    countdownOverlay(number: number)

                case .flashShutter:
                    Color.white
                        .opacity(shutterFlashOpacity)
                        .ignoresSafeArea()

                case .photoCaptured:
                    photoCapturedOverlay

                case .miniGameTutorial(let game):
                    PreChallengeTutorialView(
                        metadata: game,
                        onStart: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                captureState = .interactionChallenge(game: game)
                            }
                        },
                        onExit: {
                            musicService.stop()
                            activeTimerTask?.cancel()
                            dismiss()
                        }
                    )
                    .transition(.opacity)

                case .interactionChallenge(let game):
                    interactionOverlay(for: game)
                        .transition(.opacity)

                case .challengeSuccess:
                    ChallengeSuccessOverlay()

                case .challengeFailure(let penalty):
                    ChallengeFailureOverlay(penaltySticker: penalty)
                }

                // 5. White flash effect overlay
                if shutterFlashOpacity > 0 {
                    Color.white
                        .opacity(shutterFlashOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // 6. Debug Menu
                #if DEBUG
                testControlsOverlay
                #endif

                // 7. Polished Game Loading Screen
                if isSessionLoading {
                    GameLoadingView(
                        title: "Menyiapkan Kamera & Panggung...",
                        subtitle: "Pastikan kalian berdiri atau duduk dengan nyaman!"
                    )
                    .transition(.opacity)
                    .zIndex(150)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
        .fullScreenCover(isPresented: $showCustomizePhotoView) {
            CustomizePhotoView(
                photos: capturedPhotos
            ) { editedPhotos in

                // Receive the edited 5 photos
                capturedPhotos = editedPhotos

                // Close editor
                showCustomizePhotoView = false

                // Then open CompletionView
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showCompletionView = true
                }
            }
        }

        .fullScreenCover(isPresented: $showCompletionView) {
            CompletionView(
                durationSeconds: sessionDuration > 0 ? sessionDuration : 180,
                capturedPhotos: capturedPhotos,
                onRestart: {
                    showCompletionView = false
                    restartSession()
                },
                onMainMenu: {
                    showCompletionView = false
                    dismiss()

                    NotificationCenter.default.post(
                        name: NSNotification.Name("PopToRoot"),
                        object: nil
                    )
                }
            )
        }    }

    // =========================================================
    // MARK: - State Overlays
    // =========================================================

    // State 1: 3-Second Pose Preview Card
    @ViewBuilder
    private func posePreviewOverlay(secondsRemaining: Int) -> some View {
        ZStack {
            Color.black.opacity(0.40)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                PoseInstructionView(
                    mainTitle: currentPoseMainTitle,
                    subTitle: currentPoseSubTitle,
                    imageName: currentPoseImageName
                )
                .id(movementNumber)

                // Countdown badge for preview
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Perhatikan pose: \(secondsRemaining)s")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.70))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 6)

                Spacer()
            }
        }
        .transition(.opacity)
    }

    // State 2: 5.. 4.. 3.. 2.. 1.. Countdown
    @ViewBuilder
    private func countdownOverlay(number: Int) -> some View {
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 150 : 96
        let numberFont: CGFloat = isPad ? 88 : 54
        
        ZStack {
            VStack {
                Spacer()

                // Circular glowing countdown badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E4BA3"), Color(hex: "00D2FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: Color(hex: "00D2FF").opacity(0.6), radius: isPad ? 18 : 10)

                    Circle()
                        .stroke(Color.white, lineWidth: isPad ? 5 : 3.5)
                        .frame(width: circleSize, height: circleSize)

                    Text("\(number)")
                        .id(number)
                        .font(.system(size: numberFont, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 4)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: number)

                Text("Tahan gaya kalian!")
                    .font(.system(size: isPad ? 28 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 28 : 18)
                    .padding(.vertical, isPad ? 10 : 6)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.top, isPad ? 16 : 8)
                    .shadow(color: .black.opacity(0.4), radius: 6)

                Spacer()
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // State 3: Captured Photo Flash & Feedback
    @ViewBuilder
    private var photoCapturedOverlay: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            VStack {
                Spacer()

                HStack(spacing: isPad ? 12 : 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: isPad ? 32 : 20, weight: .bold))
                    Text("FOTO TERCATAT!")
                        .font(.system(size: isPad ? 36 : 22, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 36 : 20)
                .padding(.vertical, isPad ? 16 : 10)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color.blue.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.green.opacity(0.7), radius: isPad ? 16 : 10)
                .scaleEffect(1.05)
                .transition(.scale.combined(with: .opacity))

                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    // State 4: Post-Photo Interactive Mini-Game Overlay
    @ViewBuilder
    private func interactionOverlay(for game: MiniGameMetadata) -> some View {
        switch game.id {
        case .handClap:
            HandClapChallengeView(
                audioMonitor: audioMonitor,
                visionHandTracker: visionHandTracker,
                onSuccess: {
                    handleChallengeSuccess()
                },
                onFailure: {
                    handleChallengeFailure()
                }
            )
            .transition(.opacity)

        case .fastTap:
            FastTapChallengeView(
                visionHandTracker: visionHandTracker,
                onSuccess: {
                    handleChallengeSuccess()
                },
                onFailure: {
                    handleChallengeFailure()
                }
            )
            .transition(.opacity)

        case .fastMove:
            FastMoveChallengeView(
                motionService: motionService,
                onSuccess: {
                    handleChallengeSuccess()
                },
                onFailure: {
                    handleChallengeFailure()
                }
            )
            .transition(.opacity)

        case .sayILoveYou:
            SayILoveYouChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .fanSmoke:
            FanSmokeChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .waveHello:
            WaveHelloChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .doubleThumbsUp:
            DoubleThumbsUpChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .batteryHug:
            BatteryHugChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .gentleHeadPat:
            GentleHeadPatChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .fishLips:
            FishLipsChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .mouthOpen:
            MouthOpenChallengeView(
                visionHandTracker: visionHandTracker,
                audioMonitor: audioMonitor,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .blowCandle:
            BlowCandleChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .laughOutLoud:
            LaughOutLoudChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .sleepyPose:
            SleepyPoseChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)

        case .gentleHighFive:
            GentleHighFiveChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleChallengeSuccess() },
                onFailure: { handleChallengeFailure() }
            )
            .transition(.opacity)
        }
    }

    // =========================================================
    // MARK: - Header
    // =========================================================

    @ViewBuilder
    private var gameplayHeader: some View {
        let isPad = UIDevice.isIPad
        let btnSize: CGFloat = isPad ? 52 : 38
        
        VStack(spacing: isPad ? 12 : 6) {
            HStack {
                // Pause / Exit button
                Button {
                    musicService.stop()
                    activeTimerTask?.cancel()
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: btnSize, height: btnSize)
                            .shadow(color: .black.opacity(0.2), radius: 4)

                        Image(systemName: "xmark")
                            .font(.system(size: isPad ? 20 : 15, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(movementNumber)/\(totalMovements) Gerakan")
                    .font(.system(size: isPad ? 26 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)

                Spacer()

                Color.clear
                    .frame(width: btnSize, height: btnSize)
            }

            // Progress Bar
            GeometryReader { geometry in
                let spacing: CGFloat = isPad ? 8 : 4
                let totalWidth = geometry.size.width
                let calculatedWidth = (totalWidth - (spacing * CGFloat(totalMovements - 1))) / CGFloat(totalMovements)
                let segmentWidth = max(0, calculatedWidth)

                HStack(spacing: spacing) {
                    ForEach(0..<totalMovements, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(index < movementNumber ? Color.blue : Color.white.opacity(0.35))
                            .frame(width: segmentWidth, height: isPad ? 7 : 5)
                            .animation(.easeInOut(duration: 0.25), value: movementNumber)
                    }
                }
            }
            .frame(height: isPad ? 7 : 5)
        }
        .padding(.horizontal, isPad ? 30 : 54)
        .padding(.top, isPad ? 18 : 8)
        .padding(.bottom, isPad ? 18 : 8)
    }


    // =========================================================
    // MARK: - Flow & Timers
    // =========================================================

    private func startCurrentPoseCycle() {
        activeTimerTask?.cancel()

        activeTimerTask = Task { @MainActor in
            // Countdown 5, 4, 3, 2, 1 (starts immediately without startup delay)
            for num in (1...5).reversed() {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    captureState = .countdown(number: num)
                }
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }

            // 3. Trigger Flash Shutter & Capture Photo (strictly awaited)
            await triggerCapture()
        }
    }

    @MainActor
    private func triggerCapture() async {
        guard !Task.isCancelled else { return }

        // Flash animation
        withAnimation(.easeIn(duration: 0.08)) {
            shutterFlashOpacity = 0.95
        }

        // Await actual photo capture asynchronously
        let capturedImage = await cameraService.capturePhoto()
        guard !Task.isCancelled else { return }

        // If penalty is active, bake penalty stickers onto this captured photo!
        let baseImage = capturedImage ?? UIImage(named: self.currentPoseImageName)
        if let image = baseImage {
            let finalImage = penaltyService.isPenaltyActive ? await penaltyService.bakePenaltyOntoImageAsync(image) : image
            self.capturedPhotos.append(finalImage)
        }

        // Clear active penalty now that it has been applied to this photo
        penaltyService.clearPenalty()

        // Fade out flash
        do {
            try await Task.sleep(nanoseconds: 120_000_000)
        } catch { return }

        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            shutterFlashOpacity = 0.0
            captureState = .photoCaptured
        }

        // Show photo captured confirmation badge briefly
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
        } catch { return }

        guard !Task.isCancelled else { return }

        advanceToPostPhotoFlow()
    }

    private func advanceToPostPhotoFlow() {
        guard !Task.isCancelled else { return }

        if movementNumber < totalMovements {
            let gameIndex = (movementNumber - 1) % max(1, sessionMiniGames.count)
            let selectedGame = sessionMiniGames.indices.contains(gameIndex) ? sessionMiniGames[gameIndex] : (MiniGameCatalog.allGames[.handClap] ?? MiniGameCatalog.selectRandomChallenges(count: 1)[0])
            
            // Duck background music volume for audio-based games so voice/laughter is easily detected
            if selectedGame.sensorType == .audioVoice || selectedGame.sensorType == .audioClap || selectedGame.id == .mouthOpen {
                musicService.setVolume(0.25)
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                captureState = .miniGameTutorial(game: selectedGame)
            }
        }  else {
            // All 5 photos captured!
            musicService.setVolume(0.75)

            sessionDuration = Date().timeIntervalSince(sessionStartTime ?? Date()
            )

            // Open photo editor BEFORE CompletionView
            showCustomizePhotoView = true
        }
    }

    private func handleChallengeSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        activeTimerTask?.cancel()
        activeTimerTask = Task { @MainActor in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                captureState = .challengeSuccess
            }

            // Celebratory display: 2 seconds
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch { return }

            guard !Task.isCancelled else { return }

            advanceToNextPose()
        }
    }

    private func handleChallengeFailure() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        activeTimerTask?.cancel()

        let penalty = PenaltyStickerType.allCases.randomElement() ?? .banana
        penaltyService.activatePenalty(sticker: penalty)

        activeTimerTask = Task { @MainActor in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                captureState = .challengeFailure(penalty: penalty)
            }

            // Penalty notification display: 2.4 seconds
            do {
                try await Task.sleep(nanoseconds: 2_400_000_000)
            } catch { return }

            guard !Task.isCancelled else { return }

            advanceToNextPose()
        }
    }

    private func advanceToNextPose() {
        guard !Task.isCancelled else { return }
        
        // Restore music volume to full energetic level
        musicService.setVolume(0.75)

        if movementNumber < totalMovements {
            withAnimation(.easeInOut(duration: 0.25)) {
                movementNumber += 1
            }
            startCurrentPoseCycle()
        } else {
            // Sequence completed
            sessionDuration = Date().timeIntervalSince(sessionStartTime ?? Date())
            showCustomizePhotoView = true
        }
    }

    private func restartSession() {
        activeTimerTask?.cancel()
        audioMonitor.stopMonitoring()
        motionService.reset()
        visionHandTracker.reset()
        penaltyService.clearPenalty()
        movementNumber = 1
        capturedPhotos = []
        sessionStartTime = Date()
        sessionMiniGames = MiniGameCatalog.selectRandomChallenges(count: 4)
        
        let songAsset = selectedMusic?.assetName ?? MusicData.sample.first?.assetName ?? "JarangPulang.mp3"
        musicService.play(assetName: songAsset, isLooping: true, volume: 0.75)
        
        isSessionLoading = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.30)) {
                isSessionLoading = false
            }
            startCurrentPoseCycle()
        }
    }

    // =========================================================
    // MARK: - Lifecycle
    // =========================================================

    private func handleAppear() {
        forceLandscape()
        cameraService.startSession()

        cameraService.onPixelBufferAvailable = { [weak motionService, weak penaltyService, weak visionHandTracker] buffer in
            if penaltyService?.isPenaltyActive == true {
                penaltyService?.processLiveBuffer(buffer)
            }
            if visionHandTracker?.isTrackingActive == true {
                visionHandTracker?.processPixelBuffer(buffer)
            }
            if motionService?.isTrackingActive == true {
                motionService?.processPixelBuffer(buffer)
            }
        }

        let songAsset = selectedMusic?.assetName ?? MusicData.sample.first?.assetName ?? "JarangPulang.mp3"
        musicService.play(assetName: songAsset, isLooping: true, volume: 0.75)

        if !hasInitialized {
            hasInitialized = true
            movementNumber = 1
            capturedPhotos = []
            sessionStartTime = Date()
            sessionMiniGames = MiniGameCatalog.selectRandomChallenges(count: 4)
            
            Task { @MainActor in
                // Snappy loading presentation so camera hardware stabilizes and transitions gracefully
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.30)) {
                    isSessionLoading = false
                }
                startCurrentPoseCycle()
            }
        }
    }

    private func handleDisappear() {
        activeTimerTask?.cancel()
        cameraService.stopSession()
        cameraService.onPixelBufferAvailable = nil
        audioMonitor.stopMonitoring()
        visionHandTracker.reset()
        penaltyService.clearPenalty()
        musicService.stop()
        hasInitialized = false
        isSessionLoading = true
    }

    private func forceLandscape() {
        if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            if #available(iOS 16.0, *) {
                if !windowScene.interfaceOrientation.isLandscape {
                    let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
                    windowScene.requestGeometryUpdate(preferences) { _ in }
                }
            }
        }
    }

    // =========================================================
    // MARK: - Pose Info Helpers
    // =========================================================

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

    // =========================================================
    // MARK: - Debug
    // =========================================================

    #if DEBUG
    @ViewBuilder
    private var testControlsOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button("Ambil Foto Sekarang") {
                        Task { @MainActor in
                            await triggerCapture()
                        }
                    }

                    Button("Lewati ke Hitung Mundur") {
                        activeTimerTask?.cancel()
                        activeTimerTask = Task { @MainActor in
                            for num in (1...5).reversed() {
                                guard !Task.isCancelled else { return }
                                withAnimation {
                                    captureState = .countdown(number: num)
                                }
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                            }
                            await triggerCapture()
                        }
                    }

                    Button("Test Tutorial Game Acak") {
                        activeTimerTask?.cancel()
                        let randomGame = MiniGameCatalog.allGames.values.randomElement() ?? sessionMiniGames[0]
                        withAnimation {
                            captureState = .miniGameTutorial(game: randomGame)
                        }
                    }

                    Button("Test Main Mini-Game Acak") {
                        activeTimerTask?.cancel()
                        let randomGame = MiniGameCatalog.allGames.values.randomElement() ?? sessionMiniGames[0]
                        withAnimation {
                            captureState = .interactionChallenge(game: randomGame)
                        }
                    }

                    Button("Test Efek Berhasil (Hore!)") {
                        handleChallengeSuccess()
                    }

                    Button("Test Gagal & Beri Hukuman Wajah") {
                        handleChallengeFailure()
                    }

                    if penaltyService.isPenaltyActive {
                        Button("Hapus Hukuman Wajah") {
                            penaltyService.clearPenalty()
                        }
                    }

                    Divider()

                    Button("Gerakan Selanjutnya") {
                        advanceToNextPose()
                    }

                    Button("Ke Halaman Hasil") {
                        activeTimerTask?.cancel()
                        sessionDuration = 180
                        showCompletionView = true
                    }

                    Button("Reset Sesi") {
                        restartSession()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.badge.ellipsis")
                        Text("Pose \(movementNumber)/\(totalMovements)")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .allowsHitTesting(true)
        .zIndex(999)
    }
    #endif
}

// =============================================================
// MARK: - Preview
// =============================================================

#Preview("Pose Tracking View") {
    PoseTrackingView()
        .previewInterfaceOrientation(.landscapeLeft)
}
