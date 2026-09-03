//
//  ScreamMeterChallengeView.swift
//  LanScape
//

import SwiftUI

struct ScreamMeterChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    let timeLimit: Int = 8
    
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var meterProgress: CGFloat = 0.0 // 0.0 to 1.0
    @State private var secondsRemaining: Int = 8
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var pulseFlame: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 24, weight: .bold))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(secondsRemaining <= 3 ? .red : .yellow)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    
                    Text("TERIAK SEKERAS-KERASNYA!")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Ayo teriak bersama sampai meteran di tengah penuh!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Centered Energy Scream Meter
                ZStack {
                    // Outer glow container
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 520, height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        )
                        .shadow(color: meterProgress > 0.7 ? Color.red.opacity(0.6) : Color.orange.opacity(0.4), radius: 24)
                    
                    VStack(spacing: 12) {
                        // Flame icon and percentage
                        HStack {
                            Text(meterProgress > 0.8 ? "🔥" : "📢")
                                .font(.system(size: 36))
                                .scaleEffect(pulseFlame ? 1.25 : 1.0)
                            
                            Text("\(Int(meterProgress * 100))%")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(meterProgress > 0.7 ? "HAMPIR PENUH!" : "TERIAK LEBIH KERAS!")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(meterProgress > 0.7 ? .yellow : .white.opacity(0.8))
                        }
                        .padding(.horizontal, 36)
                        
                        // Meter Bar in the middle
                        GeometryReader { meterGeo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 38)
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "00F2FE"),
                                                Color(hex: "FEE140"),
                                                Color(hex: "FA709A"),
                                                Color(hex: "FF0844")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, meterGeo.size.width * meterProgress), height: 38)
                                    .animation(.easeOut(duration: 0.1), value: meterProgress)
                            }
                        }
                        .frame(height: 38)
                        .padding(.horizontal, 36)
                    }
                }
                
                Spacer()
                
                // Bottom Button for Tap/Hold Boost (accessibility + simulator testing)
                VStack(spacing: 12) {
                    Button {
                        boostVolume()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "waveform")
                                .font(.system(size: 20, weight: .bold))
                            Text("Bantuan: Tekan untuk isi meteran")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            audioMonitor.requestPermissionAndStart()
            startTimer()
            startMeterLoop()
        }
        .onDisappear {
            audioMonitor.stopMonitoring()
            meterLoopTask?.cancel()
            timerTask?.cancel()
        }
    }
    
    private func boostVolume() {
        guard !isFinished else { return }
        meterProgress = min(1.0, meterProgress + 0.18)
        if meterProgress >= 1.0 {
            finishSuccess()
        }
    }
    
    @State private var meterLoopTask: Task<Void, Never>? = nil

    private func startMeterLoop() {
        meterLoopTask?.cancel()
        meterLoopTask = Task { @MainActor in
            while !isFinished {
                do {
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch { return }
                guard !Task.isCancelled, !isFinished else { return }
                
                let vol = audioMonitor.normalizedVolume
                if vol > 0.20 {
                    // Fill meter proportionally to volume
                    let increment = (vol - 0.15) * 0.07
                    meterProgress = min(1.0, meterProgress + increment)
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pulseFlame = true
                    }
                } else {
                    // Slow decay if quiet
                    meterProgress = max(0.0, meterProgress - 0.008)
                    pulseFlame = false
                }
                
                if meterProgress >= 1.0 {
                    finishSuccess()
                    return
                }
            }
        }
    }
    
    private func finishSuccess() {
        guard !isFinished else { return }
        isFinished = true
        timerTask?.cancel()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        onSuccess()
    }
    
    private func startTimer() {
        secondsRemaining = timeLimit
        timerTask = Task { @MainActor in
            while secondsRemaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                guard !Task.isCancelled, !isFinished else { return }
                secondsRemaining -= 1
            }
            
            if !isFinished {
                isFinished = true
                onFailure()
            }
        }
    }
}
