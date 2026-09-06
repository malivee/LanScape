//
//  GameLoadingView.swift
//  LanScape
//

import SwiftUI
import Combine

struct GameLoadingView: View {
    var title: String = "Menyiapkan Panggung..."
    var subtitle: String = "Pastikan seluruh tubuh kalian terlihat di kamera ya!"
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0.0
    @State private var dotCount: Int = 0
    
    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad || geometry.size.height > 550
            let logoWidth: CGFloat = isPad ? 280 : min(160, geometry.size.width * 0.26)
            let spinnerSize: CGFloat = isPad ? 64 : 42
            
            ZStack {
                // Vibrant cohesive gradient background (LanScape style)
                LinearGradient(
                    colors: [
                        Color(hex: "0B1B3D"),
                        Color(hex: "102D66"),
                        Color(hex: "1E4BA3")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Ambient glowing background circles
                Circle()
                    .fill(Color(hex: "00D2FF").opacity(0.18))
                    .frame(width: isPad ? 500 : 260, height: isPad ? 500 : 260)
                    .blur(radius: isPad ? 90 : 50)
                    .offset(x: -geometry.size.width * 0.25, y: -geometry.size.height * 0.15)
                
                Circle()
                    .fill(Color(hex: "96C93D").opacity(0.12))
                    .frame(width: isPad ? 400 : 220, height: isPad ? 400 : 220)
                    .blur(radius: isPad ? 80 : 45)
                    .offset(x: geometry.size.width * 0.25, y: geometry.size.height * 0.2)
                
                // Centered Content
                VStack(spacing: isPad ? 18 : 10) {
                    Spacer()
                    
                    // App Logo with subtle breathing animation
                    Image("logoApp")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoWidth)
                        .scaleEffect(pulseScale)
                        .shadow(color: Color(hex: "00D2FF").opacity(0.45), radius: isPad ? 20 : 12, y: 4)
                    
                    // Custom Glowing Spinner
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: isPad ? 4.5 : 3.5)
                            .frame(width: spinnerSize, height: spinnerSize)
                        
                        Circle()
                            .trim(from: 0.0, to: 0.72)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "00D2FF"), Color(hex: "96C93D"), Color.white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: isPad ? 4.5 : 3.5, lineCap: .round)
                            )
                            .frame(width: spinnerSize, height: spinnerSize)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    .padding(.vertical, isPad ? 8 : 4)
                    
                    // Loading Status & Animated Dots
                    VStack(spacing: isPad ? 6 : 3) {
                        HStack(spacing: 2) {
                            Text(title)
                                .font(.system(size: isPad ? 24 : 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(String(repeating: ".", count: (dotCount % 3) + 1))
                                .font(.system(size: isPad ? 24 : 16, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: "00D2FF"))
                                .frame(width: 24, alignment: .leading)
                        }
                        
                        Text(subtitle)
                            .font(.system(size: isPad ? 16 : 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            // Smooth continuous spinner rotation
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            // Gentle breathing pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
        .onReceive(timer) { _ in
            dotCount += 1
        }
    }
}

#Preview("Loading - Phone Landscape", traits: .landscapeLeft) {
    GameLoadingView()
}

#Preview("Loading - iPad Landscape", traits: .landscapeRight) {
    GameLoadingView()
}
