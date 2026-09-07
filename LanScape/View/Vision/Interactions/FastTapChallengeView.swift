//
//  FastTapChallengeView.swift
//  LanScape
//

import SwiftUI

struct FastTapChallengeView: View {
    @ObservedObject var visionHandTracker: VisionHandTrackingService
    let targetTaps: Int = 15
    let timeLimit: Int = 18
    
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @State private var currentTaps: Int = 0
    @State private var secondsRemaining: Int = 18
    @State private var isFinished: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var lastHandHitTime: Date = .distantPast
    @State private var bounceScale: CGFloat = 1.0
    @State private var impactShockwave: Bool = false
    @State private var hitParticles: [ShatterParticle] = []
    
    struct ShatterParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var opacity: Double = 1.0
        var color: Color
        var size: CGFloat
    }
    
    private var progress: CGFloat {
        CGFloat(currentTaps) / CGFloat(targetTaps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad
            let circleSize: CGFloat = isPad ? 220 : 130
            let circleCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let currentRadius = circleSize / 2.0
            
            ZStack {
                // Transparent background so camera preview remains crystal clear
                Color.clear
                    .ignoresSafeArea()
                
                // Active Hand Joint Tracking (Shows ONE single glowing joint reticle cursor)
                if let primaryJoint = visionHandTracker.detectedHandPoints.first {
                    let handPos = CGPoint(x: (1.0 - primaryJoint.x) * geometry.size.width, y: (1.0 - primaryJoint.y) * geometry.size.height)
                    
                    ZStack {
                        // Outer rotating dashed target ring
                        Circle()
                            .stroke(
                                Color(hex: "38BDF8"),
                                style: StrokeStyle(lineWidth: 2.5, dash: [4, 4])
                            )
                            .frame(width: isPad ? 68 : 48, height: isPad ? 68 : 48)
                        
                        // Inner pulsing core
                        Circle()
                            .fill(Color(hex: "06B6D4").opacity(0.45))
                            .frame(width: isPad ? 44 : 30, height: isPad ? 44 : 30)
                        
                        // Center laser joint dot
                        Circle()
                            .fill(Color.white)
                            .frame(width: isPad ? 16 : 12, height: isPad ? 16 : 12)
                            .shadow(color: Color(hex: "38BDF8"), radius: 8)
                        
                        // Crosshairs
                        Path { p in
                            p.move(to: CGPoint(x: -14, y: 0))
                            p.addLine(to: CGPoint(x: 14, y: 0))
                            p.move(to: CGPoint(x: 0, y: -14))
                            p.addLine(to: CGPoint(x: 0, y: 14))
                        }
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    }
                    .position(handPos)
                    .animation(.easeOut(duration: 0.05), value: primaryJoint)
                }
                
                // Exploding Shatter Particles when ball is hit
                ForEach(hitParticles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
                
                VStack(spacing: 0) {
                    // Top Header: Timer Pill, Title, Subtitle
                    VStack(spacing: isPad ? 8 : 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                .foregroundColor(Color(hex: "EF4444"))
                            Text("\(secondsRemaining)s")
                                .font(.system(size: isPad ? 16 : 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, isPad ? 14 : 10)
                        .padding(.vertical, isPad ? 6 : 4)
                        .background(Color(hex: "111827").opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        
                        Text("HANCURKAN BOLA DENGAN TANGAN!")
                            .font(.system(size: isPad ? 26 : 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.6)
                            .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                        
                        Text("Arahkan tanganmu tepat mengenai bola di tengah (\(currentTaps)/\(targetTaps))")
                            .font(.system(size: isPad ? 14 : 10, weight: .medium))
                            .foregroundColor(Color(hex: "E2E8F0"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .shadow(color: .black.opacity(0.8), radius: 4)
                    }
                    .padding(.top, isPad ? 24 : 10)
                    
                    Spacer()
                    
                    // Central Target Ball with Shatter & Collision Reactions
                    ZStack {
                        // Impact shockwave ring
                        if impactShockwave {
                            Circle()
                                .stroke(Color(hex: "F59E0B"), lineWidth: 4)
                                .frame(width: circleSize * 1.45, height: circleSize * 1.45)
                                .opacity(0.8)
                                .scaleEffect(1.2)
                                .animation(.easeOut(duration: 0.3), value: impactShockwave)
                        }
                        
                        // Outer glowing pulse ring
                        Circle()
                            .stroke(
                                (visionHandTracker.isHandAtCenter || impactShockwave) ? Color.green : Color(hex: "3B82F6").opacity(0.4),
                                lineWidth: isPad ? 8 : 5
                            )
                            .frame(width: circleSize + (isPad ? 16 : 10), height: circleSize + (isPad ? 16 : 10))
                            .scaleEffect(visionHandTracker.isHandAtCenter ? 1.15 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: visionHandTracker.isHandAtCenter)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: isPad ? 4 : 3)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Progress ring around ball
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(colors: [Color(hex: "38BDF8"), Color(hex: "10B981")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: isPad ? 7 : 5, lineCap: .round)
                            )
                            .frame(width: circleSize, height: circleSize)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.15), value: progress)
                        
                        // Core Target Ball
                        Circle()
                            .fill(
                                impactShockwave ?
                                LinearGradient(colors: [Color(hex: "EF4444"), Color(hex: "F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                (visionHandTracker.isHandAtCenter ?
                                 LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "059669")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                 LinearGradient(colors: [Color(hex: "1E293B").opacity(0.95), Color(hex: "0F172A").opacity(0.98)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                            .frame(width: circleSize - (isPad ? 8 : 6), height: circleSize - (isPad ? 8 : 6))
                            .scaleEffect(bounceScale)
                            .overlay(
                                Circle().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1.5)
                            )
                            .shadow(color: (impactShockwave ? Color.red : (visionHandTracker.isHandAtCenter ? Color.green : Color(hex: "38BDF8"))).opacity(0.5), radius: isPad ? 20 : 12)
                        
                        VStack(spacing: isPad ? 6 : 3) {
                            Image(systemName: impactShockwave ? "sparkles" : (visionHandTracker.isHandAtCenter ? "target" : "target"))
                                .font(.system(size: isPad ? 52 : 34, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(bounceScale)
                            
                            Text("\(currentTaps)/\(targetTaps)")
                                .font(.system(size: isPad ? 22 : 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.6)
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom: Cheer + Helper Pill
                    VStack(spacing: isPad ? 8 : 5) {
                        Text(currentTaps >= targetTaps ? "BOLA BERHASIL DIHANCURKAN!" : "LETSGOOO...!!!")
                            .font(.system(size: isPad ? 20 : 13, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "60A5FA"))
                            .tracking(1.4)
                            .shadow(color: .black.opacity(0.8), radius: 4)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .font(.system(size: isPad ? 13 : 9, weight: .bold))
                                .foregroundColor(Color(hex: "38BDF8"))
                            Text("Arahkan tangan langsung ke target di tengah (\(currentTaps)/\(targetTaps))")
                                .font(.system(size: isPad ? 13 : 9.5, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isPad ? 20 : 14)
                        .padding(.vertical, isPad ? 6 : 4)
                        .background(Color(hex: "111827").opacity(0.85))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, isPad ? 24 : 10)
                }
            }
            .onChange(of: visionHandTracker.detectedHandPoints) { _, newPoints in
                checkVisionHandCollisions(points: newPoints, circleCenter: circleCenter, radius: currentRadius, in: geometry.size)
            }
            .onChange(of: visionHandTracker.isHandAtCenter) { _, isCenter in
                if isCenter {
                    triggerHandHit(at: circleCenter)
                }
            }
        }
        .onAppear {
            visionHandTracker.isTrackingActive = true
            startTimer()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }
    
    private func handScreenPosition(_ visionPoint: CGPoint, in size: CGSize) -> CGPoint {
        let x = visionPoint.x * size.width
        let y = (1.0 - visionPoint.y) * size.height
        return CGPoint(x: x, y: y)
    }
    
    private func triggerHandHit(at center: CGPoint) {
        guard !isFinished else { return }
        let now = Date()
        guard now.timeIntervalSince(lastHandHitTime) > 0.35 else { return }
        lastHandHitTime = now
        handleHit(at: center)
    }
    
    private func checkVisionHandCollisions(points: [CGPoint], circleCenter: CGPoint, radius: CGFloat, in size: CGSize) {
        guard !isFinished else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastHandHitTime) > 0.26 else { return }
        
        let hitRadius = radius + 55.0
        
        for point in points {
            let directPos = handScreenPosition(point, in: size)
            let mirroredPos = CGPoint(x: (1.0 - point.x) * size.width, y: (1.0 - point.y) * size.height)
            
            let distDirect = hypot(directPos.x - circleCenter.x, directPos.y - circleCenter.y)
            let distMirrored = hypot(mirroredPos.x - circleCenter.x, mirroredPos.y - circleCenter.y)
            
            if distDirect <= hitRadius || distMirrored <= hitRadius {
                lastHandHitTime = now
                handleHit(at: circleCenter)
                break
            }
        }
    }
    
    private func handleHit(at center: CGPoint) {
        guard !isFinished else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        currentTaps += 1
        
        // Visual shockwave & compression physics
        impactShockwave = true
        withAnimation(.spring(response: 0.12, dampingFraction: 0.4)) {
            bounceScale = 0.78
        }
        
        // Spawn shatter particles
        spawnShatterParticles(at: center)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                bounceScale = 1.0
                impactShockwave = false
            }
        }
        
        if currentTaps >= targetTaps {
            isFinished = true
            timerTask?.cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSuccess()
            }
        }
    }
    
    private func spawnShatterParticles(at center: CGPoint) {
        let colors: [Color] = [Color(hex: "F59E0B"), Color(hex: "EF4444"), Color(hex: "38BDF8"), Color.white, Color(hex: "10B981")]
        var newParticles: [ShatterParticle] = []
        for _ in 0..<14 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...140)
            let p = ShatterParticle(
                x: center.x,
                y: center.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...14)
            )
            newParticles.append(p)
        }
        hitParticles.append(contentsOf: newParticles)
        
        // Animate outward and fade
        withAnimation(.easeOut(duration: 0.45)) {
            for i in hitParticles.indices {
                hitParticles[i].x += hitParticles[i].vx
                hitParticles[i].y += hitParticles[i].vy
                hitParticles[i].opacity = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            hitParticles.removeAll()
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
