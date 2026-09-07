//
//  WaveHelloChallengeView.swift
//  LanScape
//

import SwiftUI

struct WaveHelloChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var waveHand: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Sparkling Stars effect
            ForEach(0..<6, id: \.self) { i in
                Text("✨")
                    .font(.system(size: isPad ? 36 : 24))
                    .position(
                        x: CGFloat(80 + (i * 130)).truncatingRemainder(dividingBy: 700) + 30,
                        y: CGFloat(90 + (i * 60))
                    )
                    .scaleEffect(waveHand ? 1.3 : 0.7)
                    .opacity(progress > 0.15 ? 0.8 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.6 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: waveHand
                    )
            }
            
            VStack(spacing: isPad ? 16 : 8) {
                Spacer()
                
                // 1. Sleek Frosted Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(Color(hex: "EF4444"))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 16 : 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isPad ? 16 : 11)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0F172A").opacity(0.85))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                
                // 2. Action Prompt
                Text("LAMBAIKAN TANGAN KE KAMERA!")
                    .font(.system(size: isPad ? 24 : 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Visual Display with Waving Hand (Dark Studio Proof Ring, Non-Touch)
                ZStack {
                    Circle()
                        .stroke(visionHandTracker.isWavingDetected ? Color(hex: "10B981") : Color(hex: "38BDF8").opacity(0.5), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(waveHand ? 1.08 : 0.98)
                        .opacity(waveHand ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: waveHand)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E293B").opacity(0.92), Color(hex: "0F172A").opacity(0.96)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.5)
                        )
                        .shadow(color: (visionHandTracker.isWavingDetected ? Color(hex: "10B981") : Color(hex: "38BDF8")).opacity(0.4), radius: isPad ? 22 : 14)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: isPad ? 56 : 38))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(waveHand ? 18 : -18))
                            .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: waveHand)
                            .shadow(color: (visionHandTracker.isWavingDetected ? Color(hex: "10B981") : Color(hex: "38BDF8")).opacity(0.5), radius: 6)
                        
                        Text(visionHandTracker.isWavingDetected ? "Lambaian Terdeteksi!" : "Lambaikan Tangan")
                            .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                            .foregroundColor(visionHandTracker.isWavingDetected ? Color(hex: "D1FAE5") : Color(hex: "BAE6FD"))
                    }
                }
                .frame(width: isPad ? 190 : 135, height: isPad ? 190 : 135)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "HALOO SEMUANYA!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "38BDF8"))
                        .tracking(1.0)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "0F172A").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text("Lambaikan tangan bersama menyapa kamera 'Halo!' (\(Int(progress * 100))%)")
                        .font(.system(size: isPad ? 12 : 9.5, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0B0F19").opacity(0.85))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.top, isPad ? 4 : 2)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            waveHand = true
            startChallenge()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startChallenge() {
        visionHandTracker.isTrackingActive = true
        motionService.reset()
        motionService.isTrackingActive = true
        
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                var gainedProgress = false
                if visionHandTracker.isWavingDetected {
                    registerBoost(0.038)
                    gainedProgress = true
                }
                let motion = motionService.instantMotion
                if motion > 0.03 && !visionHandTracker.detectedHandPoints.isEmpty {
                    registerBoost(min(0.025, motion * 0.18))
                    gainedProgress = true
                }
                if !gainedProgress && progress > 0 {
                    progress = max(0, progress - 0.008)
                }
                
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                } catch { return }
                
                guard !Task.isCancelled, !isFinished else { return }
            }
            
            guard !Task.isCancelled, !isFinished else { return }
            finishChallenge(success: progress >= 1.0)
        }
        
        Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                
                guard !Task.isCancelled, !isFinished else { return }
                timeRemaining -= 1
            }
            
            guard !Task.isCancelled, !isFinished else { return }
            finishChallenge(success: progress >= 1.0)
        }
    }
    
    private func registerBoost(_ amount: CGFloat) {
        guard !isFinished else { return }
        progress = min(1.0, progress + amount)
        if progress >= 1.0 {
            finishChallenge(success: true)
        }
    }
    
    private func finishChallenge(success: Bool) {
        guard !isFinished else { return }
        isFinished = true
        cleanup()
        if success {
            onSuccess()
        } else {
            onFailure()
        }
    }
    
    private func cleanup() {
        timerTask?.cancel()
        motionService.reset()
    }
}

private struct ScaleBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
