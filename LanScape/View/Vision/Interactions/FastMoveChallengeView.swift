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
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 170 : 100
        let shockwaveSize: CGFloat = isPad ? 220 : 130
        let barWidth: CGFloat = isPad ? 440 : 280
        
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
                    
                    Text("GERAK SECEPAT MUNGKIN!")
                        .font(.system(size: isPad ? 38 : 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 6)
                    
                    Text("Goyangkan tubuh, tangan, atau lompat bebas bersama!")
                        .font(.system(size: isPad ? 20 : 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, isPad ? 24 : 8)
                
                Spacer()
                
                // Speed Energy / Motion Graphic
                ZStack {
                    // Shockwave circle
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: isPad ? 4 : 2.5)
                        .frame(width: shockwaveSize, height: shockwaveSize)
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
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: Color.green.opacity(0.7), radius: isPad ? 20 : 10)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "figure.run.square.stack.fill")
                            .font(.system(size: isPad ? 64 : 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(Int(motionService.accumulatedProgress * 100))%")
                            .font(.system(size: isPad ? 24 : 15, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Motion Meter & Progress
                VStack(spacing: isPad ? 12 : 6) {
                    Text(motionService.instantMotion > 0.3 ? "⚡️ GERAKAN TERDETEKSI!" : "AYO TERUS BERGERAK!")
                        .font(.system(size: isPad ? 22 : 14, weight: .bold, design: .rounded))
                        .foregroundColor(motionService.instantMotion > 0.3 ? .green : .white)
                    
                    // Progress Bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: barWidth, height: isPad ? 16 : 10)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, barWidth * motionService.accumulatedProgress), height: isPad ? 16 : 10)
                            .animation(.easeOut(duration: 0.15), value: motionService.accumulatedProgress)
                    }
                    .frame(width: barWidth, height: isPad ? 16 : 10)
                    
                    // Simulator & Touch Helper
                    Button {
                        motionService.addManualMotion(amount: 0.18)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text("Bantuan: Tekan untuk tambah gerak")
                        }
                        .font(.system(size: isPad ? 15 : 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, isPad ? 16 : 10)
                        .padding(.vertical, isPad ? 8 : 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, isPad ? 28 : 10)
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

#Preview("Fast Move Challenge", traits: .landscapeLeft) {
    FastMoveChallengeView(
        motionService: MotionDetectionService(),
        onSuccess: {
            print("Fast Move Success")
        },
        onFailure: {
            print("Fast Move Failure")
        }
    )
}

