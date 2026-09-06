//
//  HandClapChallengeView.swift
//  LanScape
//

import SwiftUI

struct HandClapChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    var visionHandTracker: VisionHandTrackingService? = nil
    let targetClaps: Int = 5
    let timeLimit: Int = 10
    
    var onClapTriggered: (() -> Void)? = nil
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentClaps: Int = 0
    @State private var secondsRemaining: Int = 10
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
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
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
                    .background(Color(hex: "111827").opacity(0.85))
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
                        .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                    
                    // Subtitle
                    Text("Tepuk tangan kalian bersama di depan kamera (\(currentClaps)/\(targetClaps))")
                        .font(.system(size: isPad ? 14 : 10, weight: .medium))
                        .foregroundColor(Color(hex: "E2E8F0"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                }
                .padding(.top, isPad ? 24 : 10)
                
                Spacer()
                
                // Central Interactive Circle
                Button {
                    registerClap()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "3B82F6").opacity(0.35), lineWidth: isPad ? 7 : 5)
                            .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: isPad ? 4 : 3)
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                Color(hex: "60A5FA"),
                                style: StrokeStyle(lineWidth: isPad ? 6 : 4, lineCap: .round)
                            )
                            .frame(width: circleSize, height: circleSize)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.15), value: progress)
                        
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                            .shadow(color: Color(hex: "155DFC").opacity(0.6), radius: isPad ? 20 : 12)
                        
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
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    Text("Arahkan tangan langsung atau sentuh layar (\(currentClaps)/\(targetClaps))")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, isPad ? 20 : 13)
                        .padding(.vertical, isPad ? 7 : 4.5)
                        .background(Color(hex: "111827").opacity(0.85))
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
