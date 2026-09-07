//
//  MiniGameTestView.swift
//  LanScape
//
//  Created for testing all 19 cooperative mini games directly.
//

import SwiftUI
import AVFoundation

struct MiniGameTestView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Core Services
    @StateObject private var cameraService = CameraService()
    @StateObject private var audioMonitor = AudioLevelMonitor()
    @StateObject private var motionService = MotionDetectionService()
    @StateObject private var visionHandTracker = VisionHandTrackingService()
    
    // Ordered list of all 15 mini-games
    private let allGamesList: [MiniGameID] = [
        .handClap,
        .fastTap,
        .fastMove,
        .sayILoveYou,
        .fanSmoke,
        .waveHello,
        .doubleThumbsUp,
        .batteryHug,
        .gentleHeadPat,
        .fishLips,
        .mouthOpen,
        .blowCandle,
        .laughOutLoud,
        .sleepyPose,
        .gentleHighFive
    ]
    
    @State private var selectedGameID: MiniGameID = .handClap
    @State private var gameSessionKey: UUID = UUID()
    @State private var lastResult: String? = nil
    @State private var isShowingPickerDrawer: Bool = false
    
    enum TestResultOverlayType {
        case success
        case failure(PenaltyStickerType)
    }
    @State private var activeResultOverlay: TestResultOverlayType? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad || geometry.size.height > 550
            
            ZStack {
                // 1. Live Unblurred Camera Preview
                CameraPreviewView(
                    session: cameraService.captureSession,
                    onOrientationChanged: { orientation in
                        cameraService.updateVideoOrientation(orientation)
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
                
                // 2. Active Mini Game Interaction Overlay
                activeGameView
                    .id(gameSessionKey)
                
                // 3. Studio Result Overlay
                if let overlay = activeResultOverlay {
                    ZStack {
                        switch overlay {
                        case .success:
                            ChallengeSuccessOverlay()
                        case .failure(let penalty):
                            ChallengeFailureOverlay(penaltySticker: penalty)
                        }
                        
                        // Control buttons below card
                        VStack {
                            Spacer()
                            HStack(spacing: 14) {
                                Button {
                                    resetGame()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                        Text("Ulangi")
                                            .font(.system(size: isPad ? 14 : 11, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, isPad ? 20 : 14)
                                    .padding(.vertical, isPad ? 9 : 6)
                                    .background(Color(hex: "1E293B"))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                }
                                
                                Button {
                                    nextGame()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Game Berikutnya")
                                            .font(.system(size: isPad ? 14 : 11, weight: .bold, design: .rounded))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, isPad ? 20 : 14)
                                    .padding(.vertical, isPad ? 9 : 6)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.white.opacity(0.2), radius: 6)
                                }
                            }
                            .padding(.bottom, isPad ? 36 : 22)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(20)
                }
                
                // 4. Top Header: Dismiss Button + Telemetry Sensors HUD
                VStack {
                    HStack(spacing: 10) {
                        // Dismiss / Exit button
                        Button {
                            cleanup()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: isPad ? 16 : 12, weight: .bold))
                                Text("Tutup")
                                    .font(.system(size: isPad ? 14 : 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, isPad ? 14 : 10)
                            .padding(.vertical, isPad ? 9 : 6)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                        }
                        
                        // Game selector trigger button
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isShowingPickerDrawer.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(gameNumberBadge(for: selectedGameID))
                                    .font(.system(size: isPad ? 12 : 9.5, weight: .black))
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.18))
                                    .clipShape(Capsule())
                                
                                Text(MiniGameCatalog.allGames[selectedGameID]?.title ?? "Pilih Game")
                                    .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Image(systemName: isShowingPickerDrawer ? "chevron.up" : "chevron.down")
                                    .font(.system(size: isPad ? 12 : 9.5, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, isPad ? 14 : 10)
                            .padding(.vertical, isPad ? 8 : 5)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Live Sensor Readouts
                        HStack(spacing: 8) {
                            // Audio Volume
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: isPad ? 11 : 9))
                                    .foregroundColor(audioMonitor.normalizedVolume > 0.12 ? .green : .white.opacity(0.7))
                                Text("\(Int(audioMonitor.normalizedVolume * 100))%")
                                    .font(.system(size: isPad ? 11 : 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(audioMonitor.normalizedVolume > 0.12 ? .green : .white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                            
                            // Motion
                            HStack(spacing: 4) {
                                Image(systemName: "figure.walk.motion")
                                    .font(.system(size: isPad ? 11 : 9))
                                    .foregroundColor(motionService.instantMotion > 0.025 ? .yellow : .white.opacity(0.7))
                                Text("\(Int(motionService.instantMotion * 100))%")
                                    .font(.system(size: isPad ? 11 : 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(motionService.instantMotion > 0.025 ? .yellow : .white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                            
                            // Hands
                            HStack(spacing: 4) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: isPad ? 11 : 9))
                                    .foregroundColor(!visionHandTracker.detectedHandPoints.isEmpty ? .cyan : .white.opacity(0.7))
                                Text("\(visionHandTracker.detectedHandPoints.count)")
                                    .font(.system(size: isPad ? 11 : 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(!visionHandTracker.detectedHandPoints.isEmpty ? .cyan : .white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                            
                            // Reset active game button
                            Button {
                                resetGame()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: isPad ? 13 : 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: isPad ? 32 : 26, height: isPad ? 32 : 26)
                                    .background(Color.black.opacity(0.65))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, isPad ? 24 : 14)
                    .padding(.top, isPad ? 18 : 10)
                    
                    // 5. Drawer / Quick Picker of all 19 Games
                    if isShowingPickerDrawer {
                        gamePickerDrawer(isPad: isPad)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            setupServices()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Game Picker Drawer
    private func gamePickerDrawer(isPad: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(allGamesList.enumerated()), id: \.element) { index, gameID in
                    let meta = MiniGameCatalog.allGames[gameID]
                    let isSelected = selectedGameID == gameID
                    
                    Button {
                        selectedGameID = gameID
                        resetGame()
                        withAnimation {
                            isShowingPickerDrawer = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(index + 1)")
                                .font(.system(size: isPad ? 11 : 9, weight: .black))
                                .foregroundColor(isSelected ? .black : .yellow)
                                .frame(width: isPad ? 18 : 15, height: isPad ? 18 : 15)
                                .background(isSelected ? Color.yellow : Color.white.opacity(0.15))
                                .clipShape(Circle())
                            
                            Image(systemName: meta?.sfSymbol ?? "gamecontroller.fill")
                                .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                .foregroundColor(isSelected ? .yellow : .white.opacity(0.85))
                            
                            Text(meta?.title ?? gameID.rawValue)
                                .font(.system(size: isPad ? 13 : 10.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, isPad ? 12 : 9)
                        .padding(.vertical, isPad ? 7 : 5)
                        .background(
                            isSelected ?
                                AnyShapeStyle(Color.blue.opacity(0.85)) :
                                AnyShapeStyle(Color.black.opacity(0.70))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.yellow : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, isPad ? 24 : 14)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, isPad ? 20 : 12)
        .padding(.top, 4)
    }
    
    // MARK: - Active Game Overlay
    @ViewBuilder
    private var activeGameView: some View {
        switch selectedGameID {
        case .handClap:
            HandClapChallengeView(
                audioMonitor: audioMonitor,
                visionHandTracker: visionHandTracker,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .fastTap:
            FastTapChallengeView(
                visionHandTracker: visionHandTracker,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .fastMove:
            FastMoveChallengeView(
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .sayILoveYou:
            SayILoveYouChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .fanSmoke:
            FanSmokeChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .waveHello:
            WaveHelloChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .doubleThumbsUp:
            DoubleThumbsUpChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .batteryHug:
            BatteryHugChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .gentleHeadPat:
            GentleHeadPatChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .fishLips:
            FishLipsChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .mouthOpen:
            MouthOpenChallengeView(
                visionHandTracker: visionHandTracker,
                audioMonitor: audioMonitor,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .blowCandle:
            BlowCandleChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .laughOutLoud:
            LaughOutLoudChallengeView(
                audioMonitor: audioMonitor,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .sleepyPose:
            SleepyPoseChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
            
        case .gentleHighFive:
            GentleHighFiveChallengeView(
                visionHandTracker: visionHandTracker,
                motionService: motionService,
                onSuccess: { handleSuccess() },
                onFailure: { handleFailure() }
            )
        }
    }
    
    // MARK: - Game Control Helpers
    private func gameNumberBadge(for id: MiniGameID) -> String {
        if let idx = allGamesList.firstIndex(of: id) {
            return "Game \(idx + 1)/\(allGamesList.count)"
        }
        return "Game"
    }
    
    private func resetGame() {
        activeResultOverlay = nil
        lastResult = nil
        gameSessionKey = UUID()
    }
    
    private func nextGame() {
        if let idx = allGamesList.firstIndex(of: selectedGameID) {
            let nextIdx = (idx + 1) % allGamesList.count
            selectedGameID = allGamesList[nextIdx]
            resetGame()
        }
    }
    
    private func handleSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            activeResultOverlay = .success
            lastResult = "TANTANGAN BERHASIL"
        }
    }
    
    private func handleFailure() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let penalty = PenaltyStickerType.allCases.randomElement() ?? .clown
            activeResultOverlay = .failure(penalty)
            lastResult = "TANTANGAN GAGAL"
        }
    }
    
    // MARK: - Lifecycle Pipeline Setup
    private func setupServices() {
        cameraService.startSession()
        audioMonitor.requestPermissionAndStart()
        motionService.reset()
        motionService.isTrackingActive = true
        visionHandTracker.isTrackingActive = true
        
        cameraService.onPixelBufferAvailable = { [weak motionService, weak visionHandTracker] buffer in
            if visionHandTracker?.isTrackingActive == true {
                visionHandTracker?.processPixelBuffer(buffer)
            }
            if motionService?.isTrackingActive == true {
                motionService?.processPixelBuffer(buffer)
            }
        }
    }
    
    private func cleanup() {
        cameraService.stopSession()
        audioMonitor.stopMonitoring()
        motionService.reset()
        visionHandTracker.isTrackingActive = false
    }
}
