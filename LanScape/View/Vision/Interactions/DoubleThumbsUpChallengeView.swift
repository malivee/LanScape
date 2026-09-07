//
//  DoubleThumbsUpChallengeView.swift
//  LanScape
//

import SwiftUI

struct DoubleThumbsUpChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var bounceThumbs: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Gold fireworks effect
            ForEach(0..<6, id: \.self) { i in
                Text("🌟")
                    .font(.system(size: isPad ? 38 : 24))
                    .position(
                        x: CGFloat(90 + (i * 130)).truncatingRemainder(dividingBy: 700) + 30,
                        y: CGFloat(80 + (i * 65))
                    )
                    .scaleEffect(bounceThumbs ? 1.25 : 0.75)
                    .opacity(progress > 0.15 ? 0.85 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.7 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: bounceThumbs
                    )
            }
            
            VStack(spacing: isPad ? 16 : 8) {
                Spacer()
                
                // 1. Clean White Frosted Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(timeRemaining <= 3 ? Color(red: 0.85, green: 0.15, blue: 0.2) : Color(red: 0.15, green: 0.35, blue: 0.8))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 16 : 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isPad ? 16 : 11)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                
                // 2. Action Prompt
                Text("ACUNGKAN JEMPOL MANTAP!")
                    .font(.system(size: isPad ? 24 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                
                // 3. Hero Visual Display (Clean White Photobooth Orb)
                ZStack {
                    Circle()
                        .stroke(visionHandTracker.isThumbsUpDetected ? Color(hex: "10B981") : Color(red: 0.15, green: 0.45, blue: 0.95).opacity(0.5), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(bounceThumbs ? 1.08 : 0.98)
                        .opacity(bounceThumbs ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bounceThumbs)
                    
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 5)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: isPad ? 54 : 36))
                            .foregroundColor(visionHandTracker.isThumbsUpDetected ? Color(hex: "10B981") : Color(red: 0.15, green: 0.35, blue: 0.8))
                            .scaleEffect(bounceThumbs ? 1.15 : 0.95)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true), value: bounceThumbs)
                        
                        Text(visionHandTracker.isThumbsUpDetected ? "Jempol Terdeteksi!" : "Acungkan Jempol")
                            .font(.system(size: isPad ? 13 : 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(visionHandTracker.isThumbsUpDetected ? Color(hex: "059669") : Color(hex: "1E293B"))
                    }
                }
                .frame(width: isPad ? 190 : 135, height: isPad ? 190 : 135)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "MANTAP SEKALI!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                        .shadow(color: .black.opacity(0.7), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.35))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Clean White Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.8))
                    Text("Acungkan jempol ke depan kamera bersama-sama (\(Int(progress * 100))%)")
                        .font(.system(size: isPad ? 12 : 9.5, weight: .semibold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                .padding(.top, isPad ? 4 : 2)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            bounceThumbs = true
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
                if visionHandTracker.isThumbsUpDetected {
                    registerBoost(0.038)
                } else if progress > 0 {
                    progress = max(0, progress - 0.01)
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
