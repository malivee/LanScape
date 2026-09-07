//
//  GentleHighFiveChallengeView.swift
//  LanScape
//

import SwiftUI

struct GentleHighFiveChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var palmBounce: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Dual High-Five Hands reaching in
            HStack(spacing: isPad ? 120 : 60) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: isPad ? 54 : 34))
                    .foregroundColor(Color(hex: "34D399"))
                    .scaleEffect(palmBounce ? 1.15 : 0.85)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: palmBounce)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: isPad ? 54 : 34))
                    .foregroundColor(Color(hex: "34D399"))
                    .scaleEffect(palmBounce ? 1.15 : 0.85)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: palmBounce)
            }
            .position(x: UIScreen.main.bounds.width / 2, y: isPad ? 95 : 65)
            .opacity(progress > 0.1 ? 0.85 : 0.0)
            
            VStack(spacing: isPad ? 16 : 8) {
                Spacer()
                
                // 1. Clean White Frosted Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(timeRemaining <= 3 ? Color(red: 0.85, green: 0.15, blue: 0.2) : Color(red: 0.15, green: 0.35, blue: 0.8))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 17 : 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                
                // 2. Action Prompt
                Text("ANGKAT TANGAN BERSAMA BUAT TOSS!")
                    .font(.system(size: isPad ? 24 : 15.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                
                // 3. Hero Visual Display (Clean White Photobooth Orb)
                ZStack {
                    Circle()
                        .stroke(visionHandTracker.isHighFiveDetected ? Color.green : Color(hex: "10B981"), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(palmBounce ? 1.08 : 0.98)
                        .opacity(palmBounce ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: palmBounce)
                    
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 5)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: isPad ? 52 : 34))
                            .foregroundColor(Color(hex: "10B981"))
                            .scaleEffect(palmBounce ? 1.12 : 0.95)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6).repeatForever(autoreverses: true), value: palmBounce)
                        
                        Text(visionHandTracker.isHighFiveDetected ? "Tosss Terdeteksi!" : "Angkat Telapak")
                            .font(.system(size: isPad ? 13 : 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(visionHandTracker.isHighFiveDetected ? Color(hex: "059669") : Color(hex: "1E293B"))
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "TOSSS BERHASIL!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.7), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.35))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "34D399")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Clean White Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "10B981"))
                    Text("Angkat telapak tangan terbuka ke arah kamera (\(Int(progress * 100))%)")
                        .font(.system(size: isPad ? 12 : 9, weight: .semibold))
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
            palmBounce = true
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
                if visionHandTracker.isHighFiveDetected {
                    registerBoost(0.042)
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
