//
//  MouthOpenChallengeView.swift
//  LanScape
//

import SwiftUI

struct MouthOpenChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    @ObservedObject var audioMonitor: AudioLevelMonitor
    @ObservedObject var motionService: MotionDetectionService
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var fireworkGlow: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Fireworks popping in background
            ForEach(0..<6, id: \.self) { i in
                Text("🎆")
                    .font(.system(size: isPad ? 44 : 28))
                    .position(
                        x: CGFloat(80 + (i * 125)).truncatingRemainder(dividingBy: 700) + 30,
                        y: CGFloat(85 + (i * 55))
                    )
                    .scaleEffect(fireworkGlow ? 1.3 : 0.7)
                    .opacity(progress > 0.15 ? 0.85 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.7 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: fireworkGlow
                    )
            }
            
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
                Text("BUKA MULUT 'WAAAH' SEKARANG!")
                    .font(.system(size: isPad ? 24 : 15.5, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Visual Indicator (Pure Vision + Vocalization, Non-Touch)
                ZStack {
                    Circle()
                        .stroke(visionHandTracker.isMouthOpenWide ? Color.green : Color(hex: "A855F7"), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(fireworkGlow ? 1.08 : 0.98)
                        .opacity(fireworkGlow ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: fireworkGlow)
                    
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
                            Circle().stroke(Color(hex: "A855F7").opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: (visionHandTracker.isMouthOpenWide ? Color.green : Color(hex: "A855F7")).opacity(0.5), radius: isPad ? 20 : 14)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: isPad ? 52 : 34))
                            .foregroundColor(Color(hex: "C084FC"))
                            .scaleEffect(fireworkGlow ? 1.12 : 0.95)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true), value: fireworkGlow)
                        
                        Text(visionHandTracker.isMouthOpenWide ? "Mulut 'O' Terdeteksi!" : "Buka Mulut")
                            .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                            .foregroundColor(visionHandTracker.isMouthOpenWide ? .green : Color(hex: "F3E8FF"))
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "KEMBANG API MELETUP!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "C084FC"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "0B0F19").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "A855F7"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 5. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "C084FC"))
                    Text("Buka mulut membentuk huruf 'O' / ucapkan 'Waaah' (\(Int(progress * 100))%)")
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
            fireworkGlow = true
            startChallenge()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startChallenge() {
        visionHandTracker.isTrackingActive = true
        audioMonitor.requestPermissionAndStart()
        motionService.reset()
        
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                // Strict detection: vision must detect mouth open 'O'
                if visionHandTracker.isMouthOpenWide {
                    let vol = audioMonitor.normalizedVolume
                    let audioBonus = vol > 0.20 ? min(0.015, (vol - 0.18) * 0.15) : 0.0
                    registerBoost(0.038 + audioBonus)
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
        audioMonitor.stopMonitoring()
    }
}
