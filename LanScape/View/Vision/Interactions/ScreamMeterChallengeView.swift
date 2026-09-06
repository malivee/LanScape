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
    @State private var meterLoopTask: Task<Void, Never>? = nil
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 210 : 124
        
        ZStack {
            Color(hex: "1F2024").opacity(0.85)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    boostVolume()
                }
            
            VStack(spacing: 0) {
                // Top Header: Timer Pill, Title, Subtitle
                VStack(spacing: isPad ? 8 : 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: isPad ? 14 : 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, isPad ? 12 : 9)
                    .padding(.vertical, isPad ? 5 : 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    
                    Text("TERIAK SEKERAS-KERASNYA")
                        .font(.system(size: isPad ? 26 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.6)
                    
                    Text("Ayo teriak bersama sekeras mungkin sampai lingkaran penuh")
                        .font(.system(size: isPad ? 14 : 10, weight: .regular))
                        .foregroundColor(Color(hex: "CBD5E1"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, isPad ? 24 : 10)
                
                Spacer()
                
                // Central Interactive Circle (Figma Reference Style)
                Button {
                    boostVolume()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "3B82F6").opacity(0.35), lineWidth: isPad ? 7 : 5)
                            .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: isPad ? 4 : 3)
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: meterProgress)
                            .stroke(
                                meterProgress > 0.75 ? Color(hex: "F87171") : Color(hex: "60A5FA"),
                                style: StrokeStyle(lineWidth: isPad ? 4 : 3, lineCap: .round)
                            )
                            .frame(width: circleSize, height: circleSize)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.15), value: meterProgress)
                        
                        Circle()
                            .fill(Color(hex: "155DFC"))
                            .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                        
                        VStack(spacing: isPad ? 4 : 2) {
                            Text(meterProgress > 0.75 ? "🔥" : "📢")
                                .font(.system(size: isPad ? 52 : 32))
                                .scaleEffect(bounceScale)
                            
                            Text("\(Int(meterProgress * 100))%")
                                .font(.system(size: isPad ? 16 : 10.5, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(0.5)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Bottom: Cheer + Helper Pill
                VStack(spacing: isPad ? 8 : 5) {
                    Text("LETSGOOO...!!!")
                        .font(.system(size: isPad ? 19 : 13, weight: .heavy))
                        .foregroundColor(.white)
                        .tracking(1.4)
                    
                    Text(meterProgress > 0.7 ? "SEDIKIT LAGI PENUH!" : "Teriak bersama atau buat suara yang lantang")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, isPad ? 20 : 13)
                        .padding(.vertical, isPad ? 7 : 4.5)
                        .background(Color(hex: "2563EB"))
                        .clipShape(Capsule())
                }
                .padding(.bottom, isPad ? 24 : 10)
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        meterProgress = min(1.0, meterProgress + 0.16)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                bounceScale = 1.0
            }
        }
        
        if meterProgress >= 1.0 {
            finishSuccess()
        }
    }
    
    private func startMeterLoop() {
        meterLoopTask?.cancel()
        meterLoopTask = Task { @MainActor in
            while !isFinished {
                do {
                    try await Task.sleep(nanoseconds: 45_000_000)
                } catch { return }
                guard !Task.isCancelled, !isFinished else { return }
                
                let vol = audioMonitor.normalizedVolume
                if vol > 0.20 {
                    let increment = (vol - 0.16) * 0.08
                    meterProgress = min(1.0, meterProgress + increment)
                    bounceScale = 1.08
                } else {
                    meterProgress = max(0.0, meterProgress - 0.005)
                    bounceScale = 1.0
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
        meterLoopTask?.cancel()
        
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
                meterLoopTask?.cancel()
                onFailure()
            }
        }
    }
}

#Preview("Scream Meter Challenge", traits: .landscapeLeft) {
    ScreamMeterChallengeView(
        audioMonitor: AudioLevelMonitor(),
        onSuccess: {},
        onFailure: {}
    )
}
