//
//  PreChallengeTutorialView.swift
//  LanScape
//
//  Clean 3-second rapid tutorial card designed in Photobooth Dark Studio aesthetic.
//

import SwiftUI

struct PreChallengeTutorialView: View {
    let metadata: MiniGameMetadata
    let onStart: () -> Void
    var onExit: (() -> Void)? = nil
    
    @State private var remainingSeconds: Int = 3
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var iconScale: CGFloat = 0.92
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let cardWidth: CGFloat = isPad ? 560 : 420
        let cardHeight: CGFloat = isPad ? 340 : 255
        
        ZStack {
            // Dark studio translucent backdrop
            Color.black.opacity(0.55)
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
                                    .fill(Color.white.opacity(0.92))
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
            
            // Centered Studio Proofing Tutorial Card
            ZStack {
                // Card Background: Dark slate/navy studio glass
                RoundedRectangle(cornerRadius: isPad ? 26 : 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0B0F19").opacity(0.96),
                                Color(hex: "111827").opacity(0.98),
                                Color(hex: "0F172A").opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 26 : 18)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "38BDF8").opacity(0.6),
                                        Color(hex: "818CF8").opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 28, y: 12)
                
                VStack(spacing: isPad ? 12 : 7) {
                    // 1. Top Countdown Capsule Badge
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(hex: "38BDF8"))
                        Text("MULAI DALAM \(remainingSeconds) DETIK")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .black))
                            .tracking(1.4)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1)
                    )
                    
                    // 2. Animated SF Symbol Icon Badge
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1E293B").opacity(0.85))
                            .frame(width: isPad ? 64 : 46, height: isPad ? 64 : 46)
                        
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "38BDF8"), Color(hex: "3B82F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: isPad ? 64 : 46, height: isPad ? 64 : 46)
                        
                        Image(systemName: metadata.sfSymbol)
                            .font(.system(size: isPad ? 32 : 23, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(iconScale)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: iconScale)
                    
                    // 3. Main Title
                    Text(metadata.title)
                        .font(.system(size: isPad ? 22 : 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    // 4. Instructions Container
                    VStack(spacing: isPad ? 6 : 4) {
                        Text(metadata.tutorialInstruction)
                            .font(.system(size: isPad ? 14 : 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: isPad ? 11 : 8.5))
                                .foregroundColor(Color(hex: "FBBF24"))
                            Text(metadata.tutorialTip)
                                .font(.system(size: isPad ? 12 : 9, weight: .medium))
                                .foregroundColor(Color(hex: "94A3B8"))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, isPad ? 20 : 12)
                    .padding(.vertical, isPad ? 8 : 5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 5. 3-Second Linear Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "38BDF8"), Color(hex: "10B981")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(remainingSeconds) / 3.0))
                                .animation(.linear(duration: 1.0), value: remainingSeconds)
                        }
                    }
                    .frame(height: 3.5)
                    .padding(.horizontal, isPad ? 24 : 16)
                    
                    // 6. Action Button: "Mulai Sekarang ➔"
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        timerTask?.cancel()
                        onStart()
                    }) {
                        HStack(spacing: 6) {
                            Text("Mulai Sekarang")
                                .font(.system(size: isPad ? 13 : 10, weight: .bold, design: .rounded))
                            Image(systemName: "play.fill")
                                .font(.system(size: isPad ? 10 : 8, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, isPad ? 20 : 14)
                        .padding(.vertical, isPad ? 8 : 5.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .white.opacity(0.2), radius: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(isPad ? 20 : 14)
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .onAppear {
            iconScale = 1.08
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
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
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
