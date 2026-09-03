//
//  HandClapChallengeView.swift
//  LanScape
//

import SwiftUI

struct HandClapChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    var visionHandTracker: VisionHandTrackingService? = nil
    let targetClaps: Int = 6
    let timeLimit: Int = 8
    
    var onClapTriggered: (() -> Void)? = nil
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentClaps: Int = 0
    @State private var secondsRemaining: Int = 8
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var pulseEffect: CGFloat = 1.0
    @State private var ripples: [UUID] = []
    
    // Size starts at 320 and shrinks with each clap
    private var handScale: CGFloat {
        let remainingRatio = CGFloat(targetClaps - currentClaps) / CGFloat(targetClaps)
        return max(0.18, remainingRatio)
    }
    
    var body: some View {
        ZStack {
            // Darkened translucent backdrop for focus (tapping anywhere also triggers clap!)
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    registerClap()
                }
            
            VStack(spacing: 20) {
                // Top Header with Timer and Instruction
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 24, weight: .bold))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(secondsRemaining <= 3 ? .red : .yellow)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    
                    Text("TEPUK TANGAN BERSAMA!")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Tepuk tangan kalian secepat mungkin sampai tangannya mengecil!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Giant Clapping Hand Interactive Target
                ZStack {
                    // Shockwave rings when clapped
                    ForEach(ripples, id: \.self) { _ in
                        Circle()
                            .stroke(Color.yellow.opacity(0.6), lineWidth: 4)
                            .frame(width: 320, height: 320)
                            .scaleEffect(pulseEffect)
                            .opacity(2.0 - Double(pulseEffect))
                    }
                    
                    // Outer glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 180
                            )
                        )
                        .frame(width: max(20, 340 * handScale), height: max(20, 340 * handScale))
                    
                    // Giant Hand Icon / Graphic
                    Button {
                        registerClap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FFAE34"), Color(hex: "FF6B00")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: max(20, 280 * handScale), height: max(20, 280 * handScale))
                                .shadow(color: Color.orange.opacity(0.6), radius: 20)
                            
                            VStack(spacing: 4) {
                                Text("👏")
                                    .font(.system(size: max(16, 130 * handScale)))
                                
                                if handScale > 0.45 {
                                    Text("TEPUK!")
                                        .font(.system(size: max(12, 26 * handScale), weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.28, dampingFraction: 0.6), value: handScale)
                }
                
                Spacer()
                
                // Bottom Progress Bar & Clap Counter
                VStack(spacing: 12) {
                    Text("\(currentClaps) / \(targetClaps) Tepukan")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Progress Bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 440, height: 16)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, 440 * (CGFloat(currentClaps) / CGFloat(targetClaps))), height: 16)
                            .animation(.spring(response: 0.3), value: currentClaps)
                    }
                    
                    // Help Hint / Simulator trigger
                    Button {
                        registerClap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                            Text("Bisa tepuk tangan langsung atau sentuh layar")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
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
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        currentClaps += 1
        onClapTriggered?()
        
        // Ripple effect
        let newId = UUID()
        ripples.append(newId)
        withAnimation(.easeOut(duration: 0.6)) {
            pulseEffect = 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            pulseEffect = 1.0
            ripples.removeAll { $0 == newId }
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
