//
//  BatteryHugChallengeView.swift
//  LanScape
//

import SwiftUI

struct BatteryHugChallengeView: View {
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
                        .font(.system(size: isPad ? 16 : 12, weight: .bold))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 18 : 13, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 22 : 14)
                .padding(.vertical, isPad ? 7 : 4.5)
                .background(Color(hex: "2563EB"))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "2563EB").opacity(0.4), radius: 8)
                
                // 2. Action Prompt
                Text("RANGKUL BAHU SEKARANG!")
                    .font(.system(size: isPad ? 26 : 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Circular Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    registerBoost(0.25)
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "10B981"), lineWidth: isPad ? 6 : 4)
                            .scaleEffect(pulseGlow ? 1.08 : 0.98)
                            .opacity(pulseGlow ? 0.9 : 0.4)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseGlow)
                        
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .shadow(color: Color(hex: "10B981").opacity(0.5), radius: isPad ? 24 : 16)
                        
                        VStack(spacing: 4) {
                            Text("🔋")
                                .font(.system(size: isPad ? 72 : 48))
                                .scaleEffect(pulseGlow ? 1.12 : 0.95)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true), value: pulseGlow)
                            
                            Text("Cas Baterai")
                                .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "D1FAE5"))
                        }
                    }
                    .frame(width: isPad ? 190 : 135, height: isPad ? 190 : 135)
                }
                .buttonStyle(ScaleBounceButtonStyle())
                .padding(.vertical, isPad ? 6 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 8 : 5) {
                    Text(progress > 0.6 ? "BATERAI PENUH 100%!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 22 : 14, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "34D399"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "111827").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "34D399")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 12 : 8)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "bolt.batteryblock.fill")
                        .font(.system(size: isPad ? 13 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "34D399"))
                    Text("Saling merangkul bahu menghadap kamera")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 20 : 14)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "111827").opacity(0.85))
                .clipShape(Capsule())
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
        motionService.reset()
        motionService.isTrackingActive = true
        
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                let motion = motionService.instantMotion
                if motion > 0.01 {
                    registerBoost(motion * 0.30)
                }
                // Holding the embrace in camera view reliably charges the battery
                registerBoost(0.035)
                
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
