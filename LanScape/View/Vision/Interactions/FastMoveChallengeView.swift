//
//  FastMoveChallengeView.swift
//  LanScape
//

import SwiftUI

struct FastMoveChallengeView: View {
    @ObservedObject var motionService: MotionDetectionService
    let timeLimit: Int = 8
    
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var secondsRemaining: Int = 8
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var pulseWave: Bool = false
    
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
                    
                    Text("GERAK SECEPAT MUNGKIN!")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Goyangkan tubuh, tangan, atau lompat bebas bersama!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Speed Energy / Motion Graphic
                ZStack {
                    // Shockwave circle
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 4)
                        .frame(width: 220, height: 220)
                        .scaleEffect(pulseWave ? 1.4 : 1.0)
                        .opacity(pulseWave ? 0.2 : 0.8)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseWave)
                    
                    // Central Circle Icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "11998E"), Color(hex: "38EF7D")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 170, height: 170)
                        .shadow(color: Color.green.opacity(0.7), radius: 20)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "figure.run.square.stack.fill")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(Int(motionService.accumulatedProgress * 100))%")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Motion Meter & Progress
                VStack(spacing: 12) {
                    Text(motionService.instantMotion > 0.3 ? "⚡️ GERAKAN TERDETEKSI!" : "AYO TERUS BERGERAK!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(motionService.instantMotion > 0.3 ? .green : .white)
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.mint, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * motionService.accumulatedProgress), height: 16)
                                .animation(.easeOut(duration: 0.15), value: motionService.accumulatedProgress)
                        }
                    }
                    .frame(width: 440, height: 16)
                    
                    // Simulator & Touch Helper
                    Button {
                        motionService.addManualMotion(amount: 0.18)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                            Text("Bantuan: Tekan untuk tambah gerak")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            motionService.reset()
            motionService.isTrackingActive = true
            motionService.onTargetReached = {
                finishSuccess()
            }
            pulseWave = true
            startTimer()
        }
        .onDisappear {
            motionService.isTrackingActive = false
            timerTask?.cancel()
            motionService.onTargetReached = nil
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
