//
//  GentleHeadPatChallengeView.swift
//  LanScape
//

import SwiftUI

struct GentleHeadPatChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var flowerBloom: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Blooming Flowers Floating Effect
            ForEach(0..<6, id: \.self) { i in
                Text("🌸")
                    .font(.system(size: isPad ? 38 : 26))
                    .position(
                        x: CGFloat(70 + (i * 135)).truncatingRemainder(dividingBy: 700) + 30,
                        y: CGFloat(75 + (i * 65))
                    )
                    .scaleEffect(flowerBloom ? 1.3 : 0.7)
                    .opacity(progress > 0.15 ? 0.85 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.8 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: flowerBloom
                    )
            }
            
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
                Text("ELUS KEPALA DENGAN LEMBUT!")
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
                            .stroke(Color(hex: "F472B6"), lineWidth: isPad ? 6 : 4)
                            .scaleEffect(flowerBloom ? 1.08 : 0.98)
                            .opacity(flowerBloom ? 0.9 : 0.4)
                            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: flowerBloom)
                        
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .shadow(color: Color(hex: "F472B6").opacity(0.5), radius: isPad ? 24 : 16)
                        
                        VStack(spacing: 4) {
                            Text("👧")
                                .font(.system(size: isPad ? 72 : 48))
                                .scaleEffect(flowerBloom ? 1.12 : 0.95)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true), value: flowerBloom)
                            
                            Text("Elus Kepala")
                                .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "FCE7F3"))
                        }
                    }
                    .frame(width: isPad ? 190 : 135, height: isPad ? 190 : 135)
                }
                .buttonStyle(ScaleBounceButtonStyle())
                .padding(.vertical, isPad ? 6 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 8 : 5) {
                    Text(progress > 0.6 ? "BUNGA BERMEKARAN!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 22 : 14, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "F472B6"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "111827").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "F472B6"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 12 : 8)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: isPad ? 13 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "F472B6"))
                    Text("Kakek/Nenek letakkan tangan di atas kepala cucu dengan santai")
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
            flowerBloom = true
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
                    registerBoost(motion * 0.35)
                }
                // Gentle continuous progress while interacting
                registerBoost(0.02)
                
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
