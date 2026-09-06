//
//  HandClapChallengeView.swift
//  LanScape
//

import SwiftUI

struct HandClapChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    var visionHandTracker: VisionHandTrackingService? = nil
    let targetClaps: Int = 12
    let timeLimit: Int = 8
    
    var onClapTriggered: (() -> Void)? = nil
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentClaps: Int = 0
    @State private var secondsRemaining: Int = 8
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var bounceScale: CGFloat = 1.0
    
    private var progress: CGFloat {
        CGFloat(currentClaps) / CGFloat(targetClaps)
    }
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 210 : 124
        
        ZStack {
            // Clean dark slate backdrop with subtle blur
            Color(hex: "1F2024").opacity(0.85)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    registerClap()
                }
            
            VStack(spacing: 0) {
                // Top Header: Timer Pill, Title, Subtitle
                VStack(spacing: isPad ? 8 : 4) {
                    // Timer Capsule
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: isPad ? 14 : 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, isPad ? 12 : 9)
                    .padding(.vertical, isPad ? 5 : 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    
                    // Main Title
                    Text("TEPUK TANGAN BERSAMA")
                        .font(.system(size: isPad ? 26 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.6)
                    
                    // Subtitle
                    Text("Tepuk tangan kalian secepat mungkin sampai ikon tangan mengecil")
                        .font(.system(size: isPad ? 14 : 10, weight: .regular))
                        .foregroundColor(Color(hex: "CBD5E1"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, isPad ? 24 : 10)
                
                Spacer()
                
                // Central Interactive Circle (Figma Reference Style)
                Button {
                    registerClap()
                } label: {
                    ZStack {
                        // Soft subtle outer blue glow ring
                        Circle()
                            .stroke(Color(hex: "3B82F6").opacity(0.35), lineWidth: isPad ? 7 : 5)
                            .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        
                        // Circular track
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: isPad ? 4 : 3)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Circular Progress Stroke
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Color(hex: "60A5FA"),
                                style: StrokeStyle(lineWidth: isPad ? 4 : 3, lineCap: .round)
                            )
                            .frame(width: circleSize, height: circleSize)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.15), value: progress)
                        
                        // Solid Royal Blue Interior (Reference match)
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                        
                        // Center content: Clapping hand + Action label
                        VStack(spacing: isPad ? 4 : 2) {
                            Text("👏")
                                .font(.system(size: isPad ? 52 : 32))
                                .scaleEffect(bounceScale)
                            
                            Text("TEPUK!")
                                .font(.system(size: isPad ? 16 : 10.5, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(0.6)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Bottom: Cheer text + Helper Pill
                VStack(spacing: isPad ? 8 : 5) {
                    Text("LETSGOOO...!!!")
                        .font(.system(size: isPad ? 19 : 13, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.4)
                    
                    Text("Arahkan tangan langsung atau sentuh layar (\(currentClaps)/\(targetClaps))")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, isPad ? 20 : 13)
                        .padding(.vertical, isPad ? 7 : 4.5)
                        .background(Color(hex: "2563EB"))
                        .clipShape(Capsule())
                }
                .padding(.bottom, isPad ? 24 : 10)
            }
        }
        .onAppear {
            visionHandTracker?.isTrackingActive = true
            audioMonitor.requestPermissionAndStart()
            audioMonitor.onClapDetected = {
                registerClap()
            }
            visionHandTracker?.onVisionClapDetected = {
                registerClap()
            }
            startTimer()
        }
        .onDisappear {
            visionHandTracker?.isTrackingActive = false
            audioMonitor.stopMonitoring()
            audioMonitor.onClapDetected = nil
            visionHandTracker?.onVisionClapDetected = nil
            timerTask?.cancel()
        }
    }
    
    func registerClap() {
        guard !isFinished else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        currentClaps += 1
        onClapTriggered?()
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                bounceScale = 1.0
            }
        }
        
        if currentClaps >= targetClaps {
            isFinished = true
            timerTask?.cancel()
            onSuccess()
        }
    }
    
    private func startTimer() {
        secondsRemaining = timeLimit
        timerTask = Task { @MainActor in
            while secondsRemaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                guard !Task.isCancelled, !isFinished else { return }
                secondsRemaining -= 1
            }
            
            if !isFinished {
                isFinished = true
                onFailure()
            }
        }
    }
}

#Preview("Hand Clap Challenge", traits: .landscapeLeft) {
    HandClapChallengeView(
        audioMonitor: AudioLevelMonitor(),
        visionHandTracker: VisionHandTrackingService(),
        onSuccess: {},
        onFailure: {}
    )
}
