//
//  FastTapChallengeView.swift
//  LanScape
//

import SwiftUI

struct FastTapChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    let targetTaps: Int = 10
    let timeLimit: Int = 8
    
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentTaps: Int = 0
    @State private var secondsRemaining: Int = 8
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var lastHandHitTime: Date = .distantPast
    @State private var bounceScale: CGFloat = 1.0
    
    private var progress: CGFloat {
        CGFloat(currentTaps) / CGFloat(targetTaps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad
            let circleSize: CGFloat = isPad ? 210 : 124
            let circleCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let currentRadius = circleSize / 2.0
            
            ZStack {
                // Clean dark slate backdrop
                Color(hex: "1F2024").opacity(0.85)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location)
                    }
                
                // Tracked Hand Cursors (Clean subtle indicator)
                ForEach(Array(visionHandTracker.detectedHandPoints.enumerated()), id: \.offset) { _, handPoint in
                    let handPos = handScreenPosition(handPoint, in: geometry.size)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "60A5FA"), lineWidth: 2)
                            .frame(width: isPad ? 50 : 36, height: isPad ? 50 : 36)
                        
                        Circle()
                            .fill(Color(hex: "60A5FA").opacity(0.2))
                            .frame(width: isPad ? 36 : 26, height: isPad ? 36 : 26)
                        
                        Text("✋")
                            .font(.system(size: isPad ? 20 : 14))
                    }
                    .position(handPos)
                    .animation(.easeOut(duration: 0.1), value: handPoint)
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
                        
                        Text("SENTUH DENGAN TANGAN KALIAN")
                            .font(.system(size: isPad ? 26 : 16, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.6)
                        
                        Text("Arahkan tangan kalian di depan kamera untuk menyentuh lingkaran")
                            .font(.system(size: isPad ? 14 : 10, weight: .regular))
                            .foregroundColor(Color(hex: "CBD5E1"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, isPad ? 24 : 10)
                    
                    Spacer()
                    
                    // Central Interactive Circle (Figma Reference Style)
                    Button {
                        handleTap(at: circleCenter)
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "3B82F6").opacity(0.35), lineWidth: isPad ? 7 : 5)
                                .frame(width: circleSize + (isPad ? 12 : 8), height: circleSize + (isPad ? 12 : 8))
                            
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: isPad ? 4 : 3)
                                .frame(width: circleSize, height: circleSize)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    Color(hex: "60A5FA"),
                                    style: StrokeStyle(lineWidth: isPad ? 4 : 3, lineCap: .round)
                                )
                                .frame(width: circleSize, height: circleSize)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 0.15), value: progress)
                            
                            Circle()
                                .fill(Color(hex: "155DFC"))
                                .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                            
                            VStack(spacing: isPad ? 4 : 2) {
                                Text("✋")
                                    .font(.system(size: isPad ? 52 : 32))
                                    .scaleEffect(bounceScale)
                                
                                Text("SENTUH")
                                    .font(.system(size: isPad ? 16 : 10.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(0.6)
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
                        
                        Text("Arahkan tanganmu tepat pada lingkaran (\(currentTaps)/\(targetTaps))")
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
            .onChange(of: visionHandTracker.detectedHandPoints) { _, newPoints in
                checkVisionHandCollisions(points: newPoints, circleCenter: circleCenter, radius: currentRadius, in: geometry.size)
            }
        }
        .onAppear {
            visionHandTracker.isTrackingActive = true
            startTimer()
        }
        .onDisappear {
            visionHandTracker.isTrackingActive = false
            timerTask?.cancel()
        }
    }
    
    private func handScreenPosition(_ visionPoint: CGPoint, in size: CGSize) -> CGPoint {
        let x = visionPoint.x * size.width
        let y = (1.0 - visionPoint.y) * size.height
        return CGPoint(x: x, y: y)
    }
    
    private func checkVisionHandCollisions(points: [CGPoint], circleCenter: CGPoint, radius: CGFloat, in size: CGSize) {
        guard !isFinished else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastHandHitTime) > 0.16 else { return }
        
        for point in points {
            let directPos = handScreenPosition(point, in: size)
            let mirroredPos = CGPoint(x: (1.0 - point.x) * size.width, y: (1.0 - point.y) * size.height)
            
            let distDirect = hypot(directPos.x - circleCenter.x, directPos.y - circleCenter.y)
            let distMirrored = hypot(mirroredPos.x - circleCenter.x, mirroredPos.y - circleCenter.y)
            
            let hitRadius = radius + 30.0
            if distDirect <= hitRadius {
                lastHandHitTime = now
                handleTap(at: directPos)
                break
            } else if distMirrored <= hitRadius {
                lastHandHitTime = now
                handleTap(at: mirroredPos)
                break
            }
        }
    }
    
    private func handleTap(at point: CGPoint) {
        guard !isFinished else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        currentTaps += 1
        
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            bounceScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                bounceScale = 1.0
            }
        }
        
        if currentTaps >= targetTaps {
            isFinished = true
            timerTask?.cancel()
            onSuccess()
        }
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

#Preview("Fast Tap Challenge", traits: .landscapeLeft) {
    FastTapChallengeView(
        visionHandTracker: VisionHandTrackingService(),
        onSuccess: {},
        onFailure: {}
    )
}
