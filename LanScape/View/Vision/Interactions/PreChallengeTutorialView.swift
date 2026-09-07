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
            
            // Centered Clean Photobooth Tutorial Card
            ZStack {
                // Card Background: Clean White Card
                RoundedRectangle(cornerRadius: isPad ? 26 : 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: 24, y: 10)
                
                VStack(spacing: isPad ? 12 : 7) {
                    // 1. Top Countdown Capsule Badge (Soft Pastel Blue)
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(red: 0.12, green: 0.35, blue: 0.85))
                        Text("MULAI DALAM \(remainingSeconds) DETIK")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Color(red: 0.12, green: 0.35, blue: 0.85))
                    }
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color(red: 0.88, green: 0.94, blue: 1.00))
                    .clipShape(Capsule())
                    
                    // 2. Animated SF Symbol Icon Badge
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.90, green: 0.94, blue: 1.00))
                            .frame(width: isPad ? 64 : 46, height: isPad ? 64 : 46)
                        
                        Image(systemName: metadata.sfSymbol)
                            .font(.system(size: isPad ? 30 : 21, weight: .bold))
                            .foregroundColor(Color(red: 0.10, green: 0.28, blue: 0.75))
                    }
                    .scaleEffect(iconScale)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: iconScale)
                    
                    // 3. Main Title (Crisp Black Bold)
                    Text(metadata.title)
                        .font(.system(size: isPad ? 22 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    // 4. Instructions Container
                    VStack(spacing: isPad ? 6 : 4) {
                        Text(metadata.tutorialInstruction)
                            .font(.system(size: isPad ? 14 : 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.20, blue: 0.30))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: isPad ? 11 : 8.5))
                                .foregroundColor(Color(red: 0.92, green: 0.65, blue: 0.05))
                            Text(metadata.tutorialTip)
                                .font(.system(size: isPad ? 12 : 9, weight: .medium))
                                .foregroundColor(Color(red: 0.45, green: 0.50, blue: 0.60))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, isPad ? 20 : 12)
                    .padding(.vertical, isPad ? 8 : 5)
                    .background(Color(red: 0.96, green: 0.97, blue: 0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 5. 3-Second Linear Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 0.90, green: 0.92, blue: 0.96))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.1, green: 0.8, blue: 0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(remainingSeconds) / 3.0))
                                .animation(.linear(duration: 1.0), value: remainingSeconds)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, isPad ? 24 : 16)
                    
                    // 6. Action Button: "Mulai Sekarang ▶" (Deep Royal Navy Pill matching reference)
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
                        .foregroundColor(.white)
                        .padding(.horizontal, isPad ? 20 : 14)
                        .padding(.vertical, isPad ? 8 : 5.5)
                        .background(Color(red: 0.04, green: 0.11, blue: 0.38))
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.04, green: 0.11, blue: 0.38).opacity(0.3), radius: 6, y: 3)
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
