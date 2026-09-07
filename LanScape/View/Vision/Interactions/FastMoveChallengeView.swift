//
//  FastMoveChallengeView.swift
//  LanScape
//

import SwiftUI

struct FastMoveChallengeView: View {
    @ObservedObject var motionService: MotionDetectionService
    let timeLimit: Int = 10
    
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var secondsRemaining: Int = 10
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var bounceScale: CGFloat = 1.0
    
    private var progress: CGFloat {
        min(1.0, max(0.0, motionService.accumulatedProgress))
    }
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let circleSize: CGFloat = isPad ? 210 : 124
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
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
                    .background(Color(hex: "111827").opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    
                    Text("GERAK SECEPAT MUNGKIN")
                        .font(.system(size: isPad ? 26 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                    
                    Text("Goyangkan tubuh santai atau lambaikan tangan bersama")
                        .font(.system(size: isPad ? 14 : 10, weight: .medium))
                        .foregroundColor(Color(hex: "E2E8F0"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                }
                .padding(.top, isPad ? 24 : 10)
                
                Spacer()
                
                // Central Motion Meter (Pure Vision Motion, Non-Touch)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: isPad ? 7 : 5)
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "10B981")], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: isPad ? 7 : 5, lineCap: .round)
                        )
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.15), value: progress)
                    
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
                        .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                        .overlay(
                            Circle().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 14, y: 6)
                    
                    VStack(spacing: isPad ? 6 : 4) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: isPad ? 44 : 28))
                            .foregroundColor(Color(hex: "38BDF8"))
                            .scaleEffect(bounceScale)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: isPad ? 17 : 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                
                Spacer()
                
                // Bottom: Cheer + Helper Pill
                VStack(spacing: isPad ? 7 : 4) {
                    Text("LETSGOOO...!!!")
                        .font(.system(size: isPad ? 19 : 13, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "38BDF8"))
                        .tracking(1.4)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: isPad ? 12 : 9, weight: .bold))
                            .foregroundColor(Color(hex: "38BDF8"))
                        Text("Goyang badan bersama di depan kamera (\(Int(progress * 100))%)")
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
                }
                .padding(.bottom, isPad ? 24 : 10)
            }
        }
        .onAppear {
            motionService.reset()
            motionService.isTrackingActive = true
            motionService.onTargetReached = {
                finishSuccess()
            }
            startTimer()
        }
        .onDisappear {
            motionService.isTrackingActive = false
            motionService.onTargetReached = nil
            timerTask?.cancel()
        }
        .onChange(of: motionService.accumulatedProgress) { _, newProgress in
            if newProgress >= 1.0 && !isFinished {
                finishSuccess()
            }
        }
    }
    
    private func boostMotion() {
        guard !isFinished else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                bounceScale = 1.0
            }
        }
        motionService.addManualMotion(amount: 0.25)
    }
    
    private func finishSuccess() {
        guard !isFinished else { return }
        isFinished = true
        timerTask?.cancel()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.2
        }
        
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
