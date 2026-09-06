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
        let isPad = UIDevice.isIPad
        let containerWidth: CGFloat = isPad ? 520 : 340
        let containerHeight: CGFloat = isPad ? 160 : 96
        let barHeight: CGFloat = isPad ? 38 : 22
        
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 20 : 6) {
                // Header
                VStack(spacing: isPad ? 8 : 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 24 : 16, weight: .bold))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: isPad ? 32 : 20, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(secondsRemaining <= 3 ? .red : .yellow)
                    .padding(.horizontal, isPad ? 24 : 14)
                    .padding(.vertical, isPad ? 8 : 4)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    
                    Text("TERIAK SEKERAS-KERASNYA!")
                        .font(.system(size: isPad ? 38 : 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Ayo teriak bersama sampai meteran di tengah penuh!")
                        .font(.system(size: isPad ? 20 : 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, isPad ? 24 : 8)
                
                Spacer()
                
                // Centered Energy Scream Meter
                ZStack {
                    // Outer glow container
                    RoundedRectangle(cornerRadius: isPad ? 32 : 18)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: containerWidth, height: containerHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: isPad ? 32 : 18)
                                .stroke(Color.white.opacity(0.3), lineWidth: isPad ? 3 : 2)
                        )
                        .shadow(color: meterProgress > 0.7 ? Color.red.opacity(0.6) : Color.orange.opacity(0.4), radius: isPad ? 24 : 12)
                    
                    VStack(spacing: isPad ? 12 : 6) {
                        // Flame icon and percentage
                        HStack {
                            Text(meterProgress > 0.8 ? "🔥" : "📢")
                                .font(.system(size: isPad ? 36 : 22))
                                .scaleEffect(pulseFlame ? 1.25 : 1.0)
                            
                            Text("\(Int(meterProgress * 100))%")
                                .font(.system(size: isPad ? 40 : 22, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(meterProgress > 0.7 ? "HAMPIR PENUH!" : "TERIAK LEBIH KERAS!")
                                .font(.system(size: isPad ? 20 : 12, weight: .heavy, design: .rounded))
                                .foregroundColor(meterProgress > 0.7 ? .yellow : .white.opacity(0.8))
                        }
                        .padding(.horizontal, isPad ? 36 : 18)
                        
                        // Meter Bar in the middle
                        GeometryReader { meterGeo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: isPad ? 16 : 10)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: barHeight)
                                
                                RoundedRectangle(cornerRadius: isPad ? 16 : 10)
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
                                    .frame(width: max(0, meterGeo.size.width * meterProgress), height: barHeight)
                                    .animation(.easeOut(duration: 0.1), value: meterProgress)
                            }
                        }
                        .frame(height: barHeight)
                        .padding(.horizontal, isPad ? 36 : 18)
                    }
                }
                
                Spacer()
                
                // Bottom Button for Tap/Hold Boost (accessibility + simulator testing)
                VStack(spacing: isPad ? 12 : 6) {
                    Button {
                        boostVolume()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: isPad ? 20 : 14, weight: .bold))
                            Text("Bantuan: Tekan untuk isi meteran")
                                .font(.system(size: isPad ? 16 : 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, isPad ? 20 : 12)
                        .padding(.vertical, isPad ? 10 : 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, isPad ? 28 : 10)
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

#Preview("Scream Meter Challenge", traits: .landscapeLeft) {
    ScreamMeterChallengeView(
        audioMonitor: AudioLevelMonitor(),
        onSuccess: {
            print("Scream Meter Success")
        },
        onFailure: {
            print("Scream Meter Failure")
        }
    )
}

