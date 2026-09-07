//
//  BatteryHugChallengeView.swift
//  LanScape
//

import SwiftUI

struct BatteryHugChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var pulseGlow: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Big Battery Progress Indicator at Top Center
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                            .frame(width: isPad ? 140 : 90, height: isPad ? 50 : 34)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: progress < 0.3 ? [Color.red] : (progress < 0.7 ? [Color.yellow] : [Color.green, Color.mint]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, (isPad ? 134 : 84) * min(1.0, progress)), height: isPad ? 44 : 28)
                            .padding(.leading, 3)
                    }
                    
                    // Battery tip
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: isPad ? 6 : 4, height: isPad ? 22 : 14)
                }
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: isPad ? 16 : 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4)
            }
            .position(x: UIScreen.main.bounds.width / 2, y: isPad ? 95 : 65)
            
            VStack(spacing: isPad ? 16 : 8) {
                Spacer()
                
                // 1. Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 17 : 12.5, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0B0F19").opacity(0.88))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
                
                // 2. Action Prompt
                Text("RANGKUL BAHU SEKARANG!")
                    .font(.system(size: isPad ? 24 : 15.5, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Visual Display (Pure Vision, Non-Touch)
                ZStack {
                    Circle()
                        .stroke(visionHandTracker.isFacesCloseTogether ? Color.green : Color(hex: "10B981"), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(pulseGlow ? 1.08 : 0.98)
                        .opacity(pulseGlow ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseGlow)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1E293B").opacity(0.92),
                                    Color(hex: "0F172A").opacity(0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle().stroke(Color(hex: "10B981").opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: (visionHandTracker.isFacesCloseTogether ? Color.green : Color(hex: "10B981")).opacity(0.5), radius: isPad ? 20 : 14)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "battery.100.bolt")
                            .font(.system(size: isPad ? 52 : 34))
                            .foregroundColor(Color(hex: "10B981"))
                            .scaleEffect(pulseGlow ? 1.12 : 0.95)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true), value: pulseGlow)
                        
                        Text(visionHandTracker.isFacesCloseTogether ? "Terhubung!" : "Cas Baterai")
                            .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                            .foregroundColor(visionHandTracker.isFacesCloseTogether ? .green : Color(hex: "D1FAE5"))
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "BATERAI PENUH 100%!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "34D399"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "0B0F19").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "34D399")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "bolt.batteryblock.fill")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "34D399"))
                    Text("Saling merangkul bahu kompak di depan kamera (\(Int(progress * 100))%)")
                        .font(.system(size: isPad ? 12 : 9, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0B0F19").opacity(0.88))
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
            pulseGlow = true
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
                if visionHandTracker.isFacesCloseTogether {
                    registerBoost(0.038)
                } else {
                    let motion = motionService.instantMotion
                    if motion > 0.035 {
                        registerBoost(min(0.025, motion * 0.18))
                    } else if progress > 0 {
                        progress = max(0, progress - 0.008)
                    }
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
