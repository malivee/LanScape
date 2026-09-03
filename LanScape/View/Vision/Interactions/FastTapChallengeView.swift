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
    @State private var tapPoints: [TapEffectPoint] = []
    @State private var lastHandHitTime: Date = .distantPast
    
    struct TapEffectPoint: Identifiable {
        let id = UUID()
        let point: CGPoint
    }
    
    // Circle starts at size 320 and shrinks with every tap
    private var circleScale: CGFloat {
        let remainingRatio = CGFloat(targetTaps - currentTaps) / CGFloat(targetTaps)
        return max(0.12, remainingRatio)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let circleCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let currentRadius = (300.0 * circleScale) / 2.0
            
            ZStack {
                // Background dark overlay with interactive tap anywhere or directly on circle
                Color.black.opacity(0.50)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location)
                    }
                
                // Tracked Hand Cursors (Vision Hand Tracking!)
                ForEach(Array(visionHandTracker.detectedHandPoints.enumerated()), id: \.offset) { _, handPoint in
                    let handPos = handScreenPosition(handPoint, in: geometry.size)
                    
                    ZStack {
                        // Pulsing target ring
                        Circle()
                            .stroke(Color.yellow, lineWidth: 3)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        Text("✋")
                            .font(.system(size: 28))
                    }
                    .position(handPos)
                    .animation(.easeOut(duration: 0.1), value: handPoint)
                }
                
                // Tap particle sparks
                ForEach(tapPoints) { tap in
                    Circle()
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .position(tap.point)
                        .scaleEffect(1.8)
                        .opacity(0)
                        .animation(.easeOut(duration: 0.4), value: tap.id)
                }
                
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
                        
                        Text("SENTUH DENGAN TANGAN KALIAN!")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 6)
                        
                        Text("Arahkan tangan kalian di depan kamera untuk menyentuh lingkaran!")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // The Shrinking Circle Target
                    ZStack {
                        // Ambient glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.cyan.opacity(0.4), Color.clear],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 180
                                )
                            )
                            .frame(width: max(20, 360 * circleScale), height: max(20, 360 * circleScale))
                        
                        // Main shrinking circular disc
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00F2FE"), Color(hex: "4FACFE")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: max(20, 300 * circleScale), height: max(20, 300 * circleScale))
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: max(1, 6 * circleScale))
                            )
                            .shadow(color: Color.cyan.opacity(0.8), radius: 24)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: max(16, 72 * circleScale), weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if circleScale > 0.35 {
                                        Text("SENTUH!")
                                            .font(.system(size: max(12, 28 * circleScale), weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: circleScale)
                    
                    Spacer()
                    
                    // Bottom Counter, Status & Progress Bar
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Text("\(currentTaps) / \(targetTaps) Sentuhan")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Vision Hand Tracking Live Indicator Badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(visionHandTracker.detectedHandPoints.isEmpty ? Color.orange : Color.green)
                                    .frame(width: 10, height: 10)
                                Text(visionHandTracker.detectedHandPoints.isEmpty ? "Angkat Tanganmu ✋" : "Tangan Terdeteksi ✋")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                        }
                        
                        // Progress Bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 440, height: 16)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, 440 * (CGFloat(currentTaps) / CGFloat(targetTaps))), height: 16)
                                .animation(.spring(response: 0.2), value: currentTaps)
                        }
                    }
                    .padding(.bottom, 36)
                }
            }
            // Check vision hand collision against circle in real-time
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
        // Vision coordinates: (0,0) is bottom-left
        let x = visionPoint.x * size.width
        let y = (1.0 - visionPoint.y) * size.height
        return CGPoint(x: x, y: y)
    }
    
    private func checkVisionHandCollisions(points: [CGPoint], circleCenter: CGPoint, radius: CGFloat, in size: CGSize) {
        guard !isFinished else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastHandHitTime) > 0.18 else { return }
        
        for point in points {
            let directPos = handScreenPosition(point, in: size)
            let mirroredPos = CGPoint(x: (1.0 - point.x) * size.width, y: (1.0 - point.y) * size.height)
            
            let distDirect = hypot(directPos.x - circleCenter.x, directPos.y - circleCenter.y)
            let distMirrored = hypot(mirroredPos.x - circleCenter.x, mirroredPos.y - circleCenter.y)
            
            // If either direct or mirrored hand reaches the circle
            let hitRadius = radius + 35.0
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
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        currentTaps += 1
        
        // Add visual tap point
        let newTap = TapEffectPoint(point: point)
        tapPoints.append(newTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            tapPoints.removeAll { $0.id == newTap.id }
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
