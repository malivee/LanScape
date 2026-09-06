//
//  FanSmokeChallengeView.swift
//  LanScape
//

import SwiftUI

struct FanSmokeChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 12
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var smokeWobble: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Interactive Smoke Layers that dissipate as progress increases
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(max(0.0, (1.0 - progress) * 0.18)))
                        .frame(width: isPad ? 260 : 160, height: isPad ? 260 : 160)
                        .offset(
                            x: CGFloat((i - 2) * 90) + (smokeWobble ? 15 : -15),
                            y: CGFloat((i % 2 == 0 ? -40 : 40)) + (smokeWobble ? -10 : 10)
                        )
                        .animation(.easeInOut(duration: 1.2 + Double(i) * 0.2).repeatForever(autoreverses: true), value: smokeWobble)
                }
            }
            .allowsHitTesting(false)
            
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
                Text("AYO KIPAS TANGAN NAIK TURUN!")
                    .font(.system(size: isPad ? 26 : 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Circular Button with Satay Graphic
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    registerBoost(0.25)
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "F59E0B"), lineWidth: isPad ? 6 : 4)
                            .scaleEffect(smokeWobble ? 1.08 : 0.98)
                            .opacity(smokeWobble ? 0.9 : 0.4)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: smokeWobble)
                        
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .shadow(color: Color(hex: "F59E0B").opacity(0.5), radius: isPad ? 24 : 16)
                        
                        VStack(spacing: 4) {
                            Text("🍢")
                                .font(.system(size: isPad ? 72 : 48))
                                .rotationEffect(.degrees(smokeWobble ? 10 : -10))
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: smokeWobble)
                            
                            Text("Kipas Asap")
                                .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "FEF3C7"))
                        }
                    }
                    .frame(width: isPad ? 190 : 135, height: isPad ? 190 : 135)
                }
                .buttonStyle(ScaleBounceButtonStyle())
                .padding(.vertical, isPad ? 6 : 2)
                
                // 4. Progress Feedback & Cheer Banner
                VStack(spacing: isPad ? 8 : 5) {
                    Text(progress > 0.6 ? "ASAPNYA SUDAH HILANG!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 22 : 14, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "FCD34D"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "111827").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 12 : 8)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.system(size: isPad ? 13 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "FCD34D"))
                    Text("Gerakkan tangan naik turun seperti mengipasi sate")
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
            smokeWobble = true
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
                if !visionHandTracker.detectedHandPoints.isEmpty {
                    registerBoost(0.04)
                }
                let motion = motionService.instantMotion
                if motion > 0.01 {
                    registerBoost(motion * 0.40)
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
        visionHandTracker.isTrackingActive = false
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
