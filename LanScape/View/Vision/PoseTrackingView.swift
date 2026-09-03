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
        case interactionChallenge(interactionIndex: Int)
        case challengeSuccess
        case challengeFailure(penalty: PenaltyStickerType)
    }

    // =========================================================
    // MARK: - Services & Environment
    // =========================================================

    var selectedMusic: MusicData? = nil

    @ObservedObject
    private var musicService = BackgroundMusicService.shared

    @StateObject
    private var cameraService = CameraService()

    @StateObject
    private var audioMonitor = AudioLevelMonitor()

    @StateObject
    private var motionService = MotionDetectionService()

    @StateObject
    private var penaltyService = FacePenaltyService()

    @StateObject
    private var visionHandTracker = VisionHandTrackingService()

    @Environment(\.dismiss)
    private var dismiss

    // =========================================================
    // MARK: - State
    // =========================================================

    @State
    private var movementNumber: Int = 1

    private let totalMovements: Int = 5

    @State
    private var captureState: PoseCaptureState = .showingPosePreview(secondsRemaining: 3)

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
    private var shutterFlashOpacity: Double = 0.0

    @State
    private var hasInitialized: Bool = false

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

                // 2. Center Divider Line
                CenterDividerLineView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
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
                                size: 175
                            )
                            .padding(.trailing, 28)
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

                case .interactionChallenge(let interactionIndex):
                    interactionOverlay(for: interactionIndex)

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
        .fullScreenCover(isPresented: $showCompletionView) {
            CompletionView(
                durationSeconds: sessionDuration > 0 ? sessionDuration : 180,
                capturedPhotos: capturedPhotos,
                onRestart: {
                    showCompletionView = false
                    restartSession()
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
                        .frame(width: 150, height: 150)
                        .shadow(color: Color(hex: "00D2FF").opacity(0.6), radius: 18)

                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                        .frame(width: 150, height: 150)

                    Text("\(number)")
                        .id(number)
                        .font(.system(size: 88, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 4)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: number)

                Text("Tahan gaya kalian!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.top, 16)
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
        ZStack {
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .bold))
                    Text("FOTO TERCATAT!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color.blue.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.green.opacity(0.7), radius: 16)
                .scaleEffect(1.05)
                .transition(.scale.combined(with: .opacity))

                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    // State 4: Post-Photo Interactive Mini-Game Overlay
    @ViewBuilder
    private func interactionOverlay(for index: Int) -> some View {
        switch index {
        case 1:
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

        case 2:
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

        case 3:
            ScreamMeterChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: {
                    handleChallengeSuccess()
                },
                onFailure: {
                    handleChallengeFailure()
                }
            )
            .transition(.opacity)

        case 4:
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

        default:
            EmptyView()
        }
    }

    // =========================================================
    // MARK: - Header
    // =========================================================

    @ViewBuilder
    private var gameplayHeader: some View {
        VStack(spacing: 12) {
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
                            .frame(width: 52, height: 52)
                            .shadow(color: .black.opacity(0.2), radius: 4)

                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(movementNumber)/\(totalMovements) Gerakan")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)

                Spacer()

                Color.clear
                    .frame(width: 52, height: 52)
            }

            // Progress Bar
            GeometryReader { geometry in
                let spacing: CGFloat = 8
                let totalWidth = geometry.size.width
                let calculatedWidth = (totalWidth - (spacing * CGFloat(totalMovements - 1))) / CGFloat(totalMovements)
                let segmentWidth = max(0, calculatedWidth)

                HStack(spacing: spacing) {
                    ForEach(0..<totalMovements, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(index < movementNumber ? Color.blue : Color.white.opacity(0.35))
                            .frame(width: segmentWidth, height: 7)
                            .animation(.easeInOut(duration: 0.25), value: movementNumber)
                    }
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 30)
        .padding(.top, 18)
        .padding(.bottom, 18)
    }

    // =========================================================
    // MARK: - Flow & Timers
    // =========================================================

    private func startCurrentPoseCycle() {
        activeTimerTask?.cancel()

        activeTimerTask = Task { @MainActor in
            // 1. Wait 3 seconds showing the pose preview
            for remaining in (1...3).reversed() {
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    captureState = .showingPosePreview(secondsRemaining: remaining)
                }
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }

            // 2. Countdown 5, 4, 3, 2, 1
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
            let finalImage = penaltyService.isPenaltyActive ? penaltyService.bakePenaltyOntoImage(image) : image
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
            // Interactive challenges between photos:
            // After Photo 1 -> Challenge 1: Clapping hands (shrink giant hand)
            // After Photo 2 -> Challenge 2: Fast circle touch with Vision hand tracking
            // After Photo 3 -> Challenge 3: Scream meter in middle
            // After Photo 4 -> Challenge 4: Fast movement
            withAnimation(.easeInOut(duration: 0.3)) {
                captureState = .interactionChallenge(interactionIndex: movementNumber)
            }
        } else {
            // All 5 photos captured! Sequence completed!
            sessionDuration = Date().timeIntervalSince(sessionStartTime ?? Date())
            showCompletionView = true
        }
    }

    private func handleChallengeSuccess() {
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

        if movementNumber < totalMovements {
            withAnimation(.easeInOut(duration: 0.25)) {
                movementNumber += 1
            }
            startCurrentPoseCycle()
        } else {
            // Sequence completed
            sessionDuration = Date().timeIntervalSince(sessionStartTime ?? Date())
            showCompletionView = true
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
        
        let songAsset = selectedMusic?.assetName ?? MusicData.sample.first?.assetName ?? "JarangPulang.mp3"
        musicService.play(assetName: songAsset, isLooping: true, volume: 0.75)
        
        startCurrentPoseCycle()
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
            visionHandTracker?.processPixelBuffer(buffer)
            motionService?.processPixelBuffer(buffer)
        }

        let songAsset = selectedMusic?.assetName ?? MusicData.sample.first?.assetName ?? "JarangPulang.mp3"
        musicService.play(assetName: songAsset, isLooping: true, volume: 0.75)

        if !hasInitialized {
            hasInitialized = true
            movementNumber = 1
            capturedPhotos = []
            sessionStartTime = Date()
            startCurrentPoseCycle()
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
    }

    private func forceLandscape() {
        if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            if #available(iOS 16.0, *) {
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
                windowScene.requestGeometryUpdate(preferences) { _ in }
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

                    Divider()

                    Button("Test Interaksi 1: Tepukan Tangan") {
                        activeTimerTask?.cancel()
                        withAnimation {
                            captureState = .interactionChallenge(interactionIndex: 1)
                        }
                    }

                    Button("Test Interaksi 2: Sentuh Cepat") {
                        activeTimerTask?.cancel()
                        withAnimation {
                            captureState = .interactionChallenge(interactionIndex: 2)
                        }
                    }

                    Button("Test Interaksi 3: Meteran Teriakan") {
                        activeTimerTask?.cancel()
                        withAnimation {
                            captureState = .interactionChallenge(interactionIndex: 3)
                        }
                    }

                    Button("Test Interaksi 4: Gerak Cepat") {
                        activeTimerTask?.cancel()
                        withAnimation {
                            captureState = .interactionChallenge(interactionIndex: 4)
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
