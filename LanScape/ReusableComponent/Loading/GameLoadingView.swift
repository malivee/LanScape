//
//  GameLoadingView.swift
//  LanScape
//

import SwiftUI

struct GameLoadingView: View {
    var title: String = "Menyiapkan Panggung..."
    var subtitle: String = "Pastikan seluruh tubuh kalian terlihat di kamera ya!"
    
    // Fixed reference time for continuous timeline animation
    @State private var startTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate - startTime
            let rotationAngle = (time * 260.0).truncatingRemainder(dividingBy: 360.0)
            let counterRotation = (-time * 180.0).truncatingRemainder(dividingBy: 360.0)
            let pulseScale = 1.0 + 0.04 * sin(time * 3.5)
            let progress = min(1.0, (time.truncatingRemainder(dividingBy: 2.2)) / 1.8)
            
            GeometryReader { geometry in
                let isPad = UIDevice.isIPad || geometry.size.height > 550
                let logoWidth: CGFloat = isPad ? 260 : min(150, geometry.size.width * 0.25)
                let spinnerSize: CGFloat = isPad ? 68 : 44
                let progressBarWidth: CGFloat = isPad ? 320 : min(220, geometry.size.width * 0.35)
                
                ZStack {
                    // Vibrant cohesive gradient background (LanScape style)
                    LinearGradient(
                        colors: [
                            Color(hex: "081530"),
                            Color(hex: "0D2350"),
                            Color(hex: "173E8A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Dynamic ambient glowing blobs with gentle motion
                    Circle()
                        .fill(Color(hex: "00D2FF").opacity(0.18 + 0.04 * sin(time * 2.0)))
                        .frame(width: isPad ? 520 : 280, height: isPad ? 520 : 280)
                        .blur(radius: isPad ? 90 : 50)
                        .offset(
                            x: -geometry.size.width * 0.22 + CGFloat(sin(time * 1.5)) * 15,
                            y: -geometry.size.height * 0.12 + CGFloat(cos(time * 1.5)) * 10
                        )
                    
                    Circle()
                        .fill(Color(hex: "96C93D").opacity(0.14 + 0.03 * cos(time * 2.2)))
                        .frame(width: isPad ? 420 : 240, height: isPad ? 420 : 240)
                        .blur(radius: isPad ? 80 : 45)
                        .offset(
                            x: geometry.size.width * 0.24 + CGFloat(cos(time * 1.3)) * 15,
                            y: geometry.size.height * 0.18 + CGFloat(sin(time * 1.3)) * 10
                        )
                    
                    // Centered Animated Layout
                    VStack(spacing: isPad ? 14 : 8) {
                        Spacer()
                        
                        // App Logo with smooth continuous breathing scale
                        Image("logoApp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: logoWidth)
                            .scaleEffect(pulseScale)
                            .shadow(color: Color(hex: "00D2FF").opacity(0.5), radius: isPad ? 20 : 12, y: 3)
                        
                        // Dual Concentric Rotating Neon Spinners (Hardware Driven)
                        ZStack {
                            // Outer rotating cyan ring
                            Circle()
                                .trim(from: 0.05, to: 0.75)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "00D2FF"), Color(hex: "1E4BA3"), Color.white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: isPad ? 4.5 : 3.2, lineCap: .round)
                                )
                                .frame(width: spinnerSize, height: spinnerSize)
                                .rotationEffect(.degrees(rotationAngle))
                            
                            // Inner counter-rotating lime ring
                            Circle()
                                .trim(from: 0.15, to: 0.65)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "96C93D"), Color(hex: "00B09B")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: isPad ? 3.5 : 2.5, lineCap: .round)
                                )
                                .frame(width: spinnerSize * 0.68, height: spinnerSize * 0.68)
                                .rotationEffect(.degrees(counterRotation))
                            
                            // Center pulsing glow dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: isPad ? 9 : 6, height: isPad ? 9 : 6)
                                .scaleEffect(0.8 + 0.4 * abs(sin(time * 4.0)))
                                .shadow(color: Color(hex: "00D2FF"), radius: 6)
                        }
                        .padding(.vertical, isPad ? 6 : 2)
                        
                        // Loading Status & Animated Bouncing Wave Dots
                        VStack(spacing: isPad ? 6 : 3) {
                            HStack(spacing: 4) {
                                Text(title)
                                    .font(.system(size: isPad ? 22 : 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                // 3 Animated bouncing dots
                                HStack(spacing: 3) {
                                    ForEach(0..<3) { index in
                                        let offset = sin((time * 5.0) - Double(index) * 0.8) * (isPad ? 4.0 : 3.0)
                                        Circle()
                                            .fill(Color(hex: "00D2FF"))
                                            .frame(width: isPad ? 6 : 4.5, height: isPad ? 6 : 4.5)
                                            .offset(y: CGFloat(offset))
                                    }
                                }
                                .frame(width: isPad ? 28 : 20)
                            }
                            
                            Text(subtitle)
                                .font(.system(size: isPad ? 15 : 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineLimit(1)
                        }
                        
                        // Active Animated Progress Bar
                        VStack(spacing: 4) {
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: progressBarWidth, height: isPad ? 7 : 5)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "00D2FF"), Color(hex: "96C93D")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(12, progressBarWidth * progress), height: isPad ? 7 : 5)
                                    .shadow(color: Color(hex: "00D2FF").opacity(0.6), radius: 4)
                            }
                        }
                        .padding(.top, isPad ? 4 : 1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

#Preview("Loading - Phone Landscape", traits: .landscapeLeft) {
    GameLoadingView()
}

#Preview("Loading - iPad Landscape", traits: .landscapeRight) {
    GameLoadingView()
}
