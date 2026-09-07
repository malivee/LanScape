//
//  BlowCandleChallengeView.swift
//  LanScape
//

import SwiftUI

struct BlowCandleChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var timeRemaining: Int = 10
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var flameFlicker: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // 3 Birthday Candles at Top Center that blow out sequentially
            HStack(spacing: isPad ? 24 : 14) {
                ForEach(0..<3, id: \.self) { index in
                    let isExtinguished = progress > CGFloat(index + 1) / 3.0
                    VStack(spacing: 2) {
                        Text(isExtinguished ? "💨" : "🔥")
                            .font(.system(size: isPad ? 32 : 22))
                            .scaleEffect(flameFlicker ? 1.15 : 0.85)
                            .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: flameFlicker)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == 0 ? Color.pink : (index == 1 ? Color.yellow : Color.cyan))
                            .frame(width: isPad ? 14 : 9, height: isPad ? 40 : 26)
                    }
                }
            }
            .position(x: UIScreen.main.bounds.width / 2, y: isPad ? 95 : 65)
            
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
                Text("TIUP LILIN BERSAMA-SAMA!")
                    .font(.system(size: isPad ? 24 : 15.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                
                // 3. Hero Visual Display (Clean White Photobooth Orb)
                ZStack {
                    Circle()
                        .stroke(progress >= 1.0 ? Color.green : Color(red: 0.95, green: 0.55, blue: 0.05), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(flameFlicker ? 1.08 : 0.98)
                        .opacity(flameFlicker ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: flameFlicker)
                    
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 5)
                    
                    VStack(spacing: 8) {
                        Image(systemName: progress >= 1.0 ? "sparkles" : (audioMonitor.normalizedVolume > 0.18 ? "wind" : "flame.fill"))
                            .font(.system(size: isPad ? 52 : 34))
                            .foregroundColor(progress >= 1.0 ? .green : (audioMonitor.normalizedVolume > 0.18 ? Color(red: 0.15, green: 0.35, blue: 0.8) : Color(red: 0.95, green: 0.55, blue: 0.05)))
                            .scaleEffect(flameFlicker ? 1.10 : 0.95)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6).repeatForever(autoreverses: true), value: flameFlicker)
                        
                        Text(audioMonitor.normalizedVolume > 0.18 ? "Meniup..." : "Tiup Lilin")
                            .font(.system(size: isPad ? 13 : 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(progress >= 1.0 ? Color(hex: "059669") : Color(hex: "1E293B"))
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress > 0.6 ? "HUUFFF... LILIN PADAM!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.6)
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
                    Image(systemName: "wind")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.05))
                    Text("Tiup santai ke arah mikrofon sampai 3 lilin padam (\(Int(progress * 100))%)")
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
            flameFlicker = true
            startChallenge()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startChallenge() {
        audioMonitor.requestPermissionAndStart()
        
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                let vol = audioMonitor.normalizedVolume
                // Blowing creates turbulent acoustic energy on the mic
                if vol > 0.18 {
                    registerBoost(min(0.045, (vol - 0.14) * 0.28))
                } else if progress > 0 {
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
        audioMonitor.stopMonitoring()
    }
}
