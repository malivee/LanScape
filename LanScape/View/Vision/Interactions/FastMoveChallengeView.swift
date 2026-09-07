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
                            .foregroundColor(secondsRemaining <= 3 ? Color(red: 0.85, green: 0.15, blue: 0.2) : Color(red: 0.15, green: 0.35, blue: 0.8))
                        Text("\(secondsRemaining)s")
                            .font(.system(size: isPad ? 14 : 11, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
                    
                    Text("GERAK SECEPAT MUNGKIN")
                        .font(.system(size: isPad ? 26 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                    
                    Text("Goyangkan tubuh santai atau lambaikan tangan bersama")
                        .font(.system(size: isPad ? 14 : 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.7), radius: 4)
                }
                .padding(.top, isPad ? 24 : 10)
                
                Spacer()
                
                // Central Motion Meter (Clean White Photobooth Orb)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: isPad ? 7 : 5)
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(hex: "10B981")], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: isPad ? 7 : 5, lineCap: .round)
                        )
                        .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.15), value: progress)
                    
                    Circle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 5)
                    
                    VStack(spacing: isPad ? 6 : 4) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: isPad ? 44 : 28))
                            .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.8))
                            .scaleEffect(bounceScale)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: isPad ? 17 : 11, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .tracking(0.5)
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                
                Spacer()
                
                // Bottom: Cheer + Helper Pill
                VStack(spacing: isPad ? 7 : 4) {
                    Text("LETSGOOO...!!!")
                        .font(.system(size: isPad ? 19 : 13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.4)
                        .shadow(color: .black.opacity(0.7), radius: 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: isPad ? 12 : 9, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.8))
                        Text("Goyang badan bersama di depan kamera (\(Int(progress * 100))%)")
                            .font(.system(size: isPad ? 12 : 9, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, isPad ? 18 : 12)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
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
