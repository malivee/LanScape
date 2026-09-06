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
        let isPad = UIDevice.isIPad
        let baseHandDiameter: CGFloat = isPad ? 280 : 150
        let barWidth: CGFloat = isPad ? 440 : 280
        
        ZStack {
            // Darkened translucent backdrop for focus (tapping anywhere also triggers clap!)
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    registerClap()
                }
            
            VStack(spacing: isPad ? 20 : 6) {
                // Top Header with Timer and Instruction
                VStack(spacing: isPad ? 8 : 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 24 : 16, weight: .bold))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: isPad ? 32 : 20, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(secondsRemaining <= 3 ? .red : .yellow)
                    .padding(.horizontal, isPad ? 24 : 14)
                    .padding(.vertical, isPad ? 8 : 4)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    
                    Text("TEPUK TANGAN BERSAMA!")
                        .font(.system(size: isPad ? 38 : 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Tepuk tangan kalian secepat mungkin sampai tangannya mengecil!")
                        .font(.system(size: isPad ? 20 : 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, isPad ? 24 : 8)
                
                Spacer()
                
                // Giant Clapping Hand Interactive Target
                ZStack {
                    // Shockwave rings when clapped
                    ForEach(ripples, id: \.self) { _ in
                        Circle()
                            .stroke(Color.yellow.opacity(0.6), lineWidth: isPad ? 4 : 2.5)
                            .frame(width: isPad ? 320 : 180, height: isPad ? 320 : 180)
                            .scaleEffect(pulseEffect)
                            .opacity(2.0 - Double(pulseEffect))
                    }
                    
                    // Outer glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: isPad ? 40 : 20,
                                endRadius: isPad ? 180 : 90
                            )
                        )
                        .frame(width: max(20, (baseHandDiameter * 1.2) * handScale), height: max(20, (baseHandDiameter * 1.2) * handScale))
                    
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
                                .frame(width: max(20, baseHandDiameter * handScale), height: max(20, baseHandDiameter * handScale))
                                .shadow(color: Color.orange.opacity(0.6), radius: isPad ? 20 : 10)
                            
                            VStack(spacing: 2) {
                                Text("👏")
                                    .font(.system(size: max(16, (isPad ? 130 : 65) * handScale)))
                                
                                if handScale > 0.45 {
                                    Text("TEPUK!")
                                        .font(.system(size: max(10, (isPad ? 26 : 14) * handScale), weight: .black, design: .rounded))
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
                VStack(spacing: isPad ? 12 : 6) {
                    Text("\(currentClaps) / \(targetClaps) Tepukan")
                        .font(.system(size: isPad ? 26 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Progress Bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: barWidth, height: isPad ? 16 : 10)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, barWidth * (CGFloat(currentClaps) / CGFloat(targetClaps))), height: isPad ? 16 : 10)
                            .animation(.spring(response: 0.3), value: currentClaps)
                    }
                    
                    // Help Hint / Simulator trigger
                    Button {
                        registerClap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                            Text("Bisa tepuk tangan langsung atau sentuh layar")
                        }
                        .font(.system(size: isPad ? 16 : 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, isPad ? 16 : 10)
                        .padding(.vertical, isPad ? 8 : 4)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, isPad ? 28 : 10)
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

#Preview("Hand Clap Challenge", traits: .landscapeLeft) {
    HandClapChallengeView(
        audioMonitor: AudioLevelMonitor(),
        visionHandTracker: VisionHandTrackingService(),
        onSuccess: {
            print("Hand Clap Success")
        },
        onFailure: {
            print("Hand Clap Failure")
        }
    )
}

