//
//  PreChallengeTutorialView.swift
//  LanScape
//

import SwiftUI

struct PreChallengeTutorialView: View {
    let metadata: MiniGameMetadata
    let onStart: () -> Void
    var onExit: (() -> Void)? = nil
    
    @State private var remainingSeconds: Int = 8
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var iconScale: CGFloat = 0.85
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Translucent backdrop allowing camera preview to remain visible
            Color.black.opacity(0.40)
                .ignoresSafeArea()
            
            // Top Exit Button
            if let onExit = onExit {
                VStack {
                    HStack {
                        Button(action: {
                            timerTask?.cancel()
                            onExit()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.90))
                                    .frame(width: isPad ? 44 : 34, height: isPad ? 44 : 34)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                                Image(systemName: "xmark")
                                    .font(.system(size: isPad ? 18 : 13, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, isPad ? 32 : 18)
                        .padding(.top, isPad ? 22 : 12)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(10)
            }
            
            VStack(spacing: isPad ? 22 : 12) {
                Spacer()
                
                // 1. Top Preparation Badge
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: isPad ? 18 : 13, weight: .bold))
                    Text("PERSIAPAN TANTANGAN (\(remainingSeconds)s)")
                        .font(.system(size: isPad ? 16 : 12, weight: .bold))
                        .tracking(1.0)
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 22 : 14)
                .padding(.vertical, isPad ? 8 : 5)
                .background(Color(hex: "2563EB"))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "2563EB").opacity(0.4), radius: 8)
                
                // 2. Animated Big Icon
                Text(metadata.icon)
                    .font(.system(size: isPad ? 90 : 54))
                    .scaleEffect(iconScale)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: iconScale)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                
                // 3. Main Title (High Contrast & Visible from 2-3 meters)
                Text(metadata.title)
                    .font(.system(size: isPad ? 34 : 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                    .padding(.horizontal, 24)
                
                // 4. Instruction Card (Ultra-legible, High-Contrast)
                VStack(spacing: isPad ? 10 : 6) {
                    Text(metadata.tutorialInstruction)
                        .font(.system(size: isPad ? 24 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, isPad ? 24 : 16)
                    
                    Text(metadata.tutorialTip)
                        .font(.system(size: isPad ? 17 : 12, weight: .medium))
                        .foregroundColor(Color(hex: "93C5FD")) // Soft bright blue
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isPad ? 24 : 16)
                    
                    // Smooth countdown progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(hex: "374151").opacity(0.8))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(remainingSeconds) / 8.0))
                                .animation(.linear(duration: 1.0), value: remainingSeconds)
                        }
                    }
                    .frame(height: isPad ? 8 : 5)
                    .padding(.horizontal, isPad ? 24 : 16)
                    .padding(.top, isPad ? 8 : 4)
                }
                .padding(.vertical, isPad ? 20 : 12)
                .padding(.horizontal, isPad ? 28 : 16)
                .background(
                    RoundedRectangle(cornerRadius: isPad ? 22 : 16)
                        .fill(Color(hex: "111827").opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: isPad ? 22 : 16)
                                .stroke(Color(hex: "3B82F6").opacity(0.6), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, isPad ? 60 : 30)
                .shadow(color: Color(hex: "1D4ED8").opacity(0.2), radius: 12)
                
                // 5. Single Hero Ready Button ("MULAI SEKARANG ➔")
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    timerTask?.cancel()
                    onStart()
                }) {
                    HStack(spacing: isPad ? 12 : 8) {
                        Text("MULAI SEKARANG")
                            .font(.system(size: isPad ? 20 : 15, weight: .black, design: .rounded))
                        Image(systemName: "play.fill")
                            .font(.system(size: isPad ? 16 : 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 44 : 26)
                    .padding(.vertical, isPad ? 15 : 10)
                    .background(Color(hex: "155DFC"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "3B82F6"), lineWidth: 2)
                    )
                    .shadow(color: Color(hex: "155DFC").opacity(0.6), radius: 14, y: 4)
                }
                .padding(.top, isPad ? 10 : 4)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            iconScale = 1.15
            startCountdown()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }
    
    private func startCountdown() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while remainingSeconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                
                guard !Task.isCancelled else { return }
                remainingSeconds -= 1
                
                // Light haptic tick on 3, 2, 1
                if remainingSeconds <= 3 && remainingSeconds > 0 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
            
            guard !Task.isCancelled else { return }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onStart()
        }
    }
}

#Preview("PreChallengeTutorialView - Phone", traits: .landscapeLeft) {
    if let sample = MiniGameCatalog.allGames[.fanSmoke] {
        PreChallengeTutorialView(
            metadata: sample,
            onStart: {}
        )
    }
}
