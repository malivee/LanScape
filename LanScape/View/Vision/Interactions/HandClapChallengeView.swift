//
//  HandClapChallengeView.swift
//  LanScape
//
//  Photobooth Studio Aesthetic HUD for Hand Clapping Cooperative Mini-Game.
//

import SwiftUI

struct HandClapChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    var visionHandTracker: VisionHandTrackingService? = nil
    let targetClaps: Int = 10
    let timeLimit: Int = 20
    
    var onClapTriggered: (() -> Void)? = nil
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentClaps: Int = 0
    @State private var secondsRemaining: Int = 20
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var bounceScale: CGFloat = 1.0
    
    @State private var lastRegisteredClap: Date = .distantPast
    
    private var progress: CGFloat {
        CGFloat(currentClaps) / CGFloat(targetClaps)
    }
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 200 : 124
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 14 : 7) {
                Spacer()
                
                // 1. Clean White Frosted Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(secondsRemaining <= 3 ? Color(red: 0.85, green: 0.15, blue: 0.2) : Color(red: 0.15, green: 0.35, blue: 0.8))
                    Text("\(secondsRemaining)s")
                        .font(.system(size: isPad ? 17 : 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)
                
                // 2. Action Prompt
                Text("AYO TEPUK TANGAN BERSAMA!")
                    .font(.system(size: isPad ? 26 : 16.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                
                // 3. Central Clapping Display (Clean White Photobooth Orb)
                ZStack {
                    // Outer progress track
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: isPad ? 7 : 5)
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.1, green: 0.8, blue: 0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: isPad ? 7 : 5, lineCap: .round)
                        )
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.15), value: progress)
                    
                    // Center clean white orb
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 5)
                    
                    VStack(spacing: isPad ? 6 : 4) {
                        Image(systemName: "hands.clap.fill")
                            .font(.system(size: isPad ? 46 : 28))
                            .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.8))
                            .scaleEffect(bounceScale)
                        
                        Text("\(currentClaps)/\(targetClaps)")
                            .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .tracking(0.6)
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(currentClaps >= targetClaps ? "TEPUK TANGAN LENGKAP 10x!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.7), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.35))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.1, green: 0.8, blue: 0.5)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Clean White Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: isPad ? 13 : 10, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.8))
                    Text("Tepuk tangan di depan kamera 10 kali (\(currentClaps)/\(targetClaps))")
                        .font(.system(size: isPad ? 13 : 10, weight: .semibold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 7 : 4.5)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                .padding(.top, isPad ? 3 : 1)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            audioMonitor.requestPermissionAndStart()
            audioMonitor.onClapDetected = {
                registerClap()
            }
            startTimer()
        }
        .onDisappear {
            audioMonitor.stopMonitoring()
            audioMonitor.onClapDetected = nil
            timerTask?.cancel()
        }
    }
    
    func registerClap() {
        guard !isFinished else { return }
        let now = Date()
        guard now.timeIntervalSince(lastRegisteredClap) >= 0.12 else { return }
        lastRegisteredClap = now
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        currentClaps += 1
        onClapTriggered?()
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                bounceScale = 1.0
            }
        }
        
        if currentClaps >= targetClaps {
            isFinished = true
            timerTask?.cancel()
            
            let successGen = UINotificationFeedbackGenerator()
            successGen.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSuccess()
            }
        }
    }
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while secondsRemaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                
                guard !Task.isCancelled else { return }
                secondsRemaining -= 1
            }
            
            guard !Task.isCancelled else { return }
            if currentClaps < targetClaps {
                isFinished = true
                onFailure()
            }
        }
    }
}

#Preview("Hand Clap Challenge - Studio Card", traits: .landscapeLeft) {
    HandClapChallengeView(
        audioMonitor: AudioLevelMonitor(),
        onSuccess: {},
        onFailure: {}
    )
}
