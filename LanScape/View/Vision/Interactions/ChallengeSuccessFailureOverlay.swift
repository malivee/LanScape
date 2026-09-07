//
//  ChallengeSuccessFailureOverlay.swift
//  LanScape
//
//  Designed in Photobooth Dark Studio Keepsake aesthetic matching CompletionView.swift.
//  Provides identical card geometry, typography, and layout for both Win and Loss states.
//

import SwiftUI

// MARK: - Challenge Success Overlay
struct ChallengeSuccessOverlay: View {
    var onDismiss: (() -> Void)? = nil
    
    @State private var cardScale: CGFloat = 0.88
    @State private var cardOpacity: Double = 0.0
    @State private var haloScale: CGFloat = 1.0
    @State private var progressWidth: CGFloat = 0.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let cardWidth: CGFloat = isPad ? 540 : 400
        let cardHeight: CGFloat = isPad ? 320 : 240
        
        ZStack {
            // Dark studio translucent camera backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            // Centered Studio Result Card
            ZStack {
                // Background canvas (matching CompletionView dark studio canvas)
                RoundedRectangle(cornerRadius: isPad ? 24 : 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0B0F19").opacity(0.97),
                                Color(hex: "111827").opacity(0.98),
                                Color(hex: "0F172A").opacity(0.97)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 24 : 18)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "10B981").opacity(0.7),
                                        Color(hex: "34D399").opacity(0.35),
                                        Color(hex: "059669").opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.65), radius: 28, y: 12)
                
                VStack(spacing: isPad ? 12 : 7) {
                    // 1. Studio Header Capsule (matching CompletionView)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                        Text("LANSCAPE STUDIO • HASIL TANTANGAN")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .black))
                            .tracking(1.4)
                            .foregroundColor(Color(hex: "34D399"))
                    }
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 5 : 3.5)
                    .background(Color(hex: "1E293B").opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                    )
                    
                    // 2. Center Studio Seal Graphic
                    ZStack {
                        // Ambient Radial Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "10B981").opacity(0.35),
                                        Color(hex: "10B981").opacity(0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: isPad ? 56 : 38
                                )
                            )
                            .frame(width: isPad ? 110 : 76, height: isPad ? 110 : 76)
                            .scaleEffect(haloScale)
                        
                        Circle()
                            .fill(Color(hex: "1E293B"))
                            .frame(width: isPad ? 64 : 46, height: isPad ? 64 : 46)
                            .overlay(
                                Circle().stroke(Color(hex: "10B981"), lineWidth: 2)
                            )
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: isPad ? 34 : 23, weight: .bold))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    // 3. Main Title
                    Text("Tantangan Berhasil!")
                        .font(.system(size: isPad ? 22 : 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.3)
                    
                    // 4. Pill Badge
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        Text("Luar Biasa Kompak!")
                            .font(.system(size: isPad ? 12 : 9.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 16 : 12)
                    .padding(.vertical, isPad ? 5 : 3.5)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "10B981"), Color(hex: "059669")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    
                    // 5. Subtitle
                    Text("Hebat sekali! Kalian berhasil menyelesaikan tantangan bersama tanpa hukuman.")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .medium))
                        .foregroundColor(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isPad ? 28 : 16)
                        .lineLimit(2)
                    
                    // 6. Auto-Advance Indicator (matches camera workflow)
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Color(hex: "34D399"))
                            .frame(width: 6, height: 6)
                            .scaleEffect(haloScale)
                        Text("Melanjutkan sesi foto...")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .medium))
                            .foregroundColor(Color(hex: "64748B"))
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, isPad ? 18 : 12)
                .frame(width: cardWidth, height: cardHeight)
            }
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                haloScale = 1.15
            }
        }
    }
}

// MARK: - Challenge Failure Overlay
struct ChallengeFailureOverlay: View {
    let penaltySticker: PenaltyStickerType
    var onDismiss: (() -> Void)? = nil
    
    @State private var cardScale: CGFloat = 0.88
    @State private var cardOpacity: Double = 0.0
    @State private var haloScale: CGFloat = 1.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let cardWidth: CGFloat = isPad ? 540 : 400
        let cardHeight: CGFloat = isPad ? 320 : 240
        
        ZStack {
            // Dark studio translucent camera backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            // Centered Studio Result Card (Identical Geometry to Success)
            ZStack {
                // Background canvas (matching CompletionView dark studio canvas)
                RoundedRectangle(cornerRadius: isPad ? 24 : 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0B0F19").opacity(0.97),
                                Color(hex: "111827").opacity(0.98),
                                Color(hex: "0F172A").opacity(0.97)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 24 : 18)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "EF4444").opacity(0.7),
                                        Color(hex: "F87171").opacity(0.35),
                                        Color(hex: "DC2626").opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.65), radius: 28, y: 12)
                
                VStack(spacing: isPad ? 12 : 7) {
                    // 1. Studio Header Capsule (matching CompletionView)
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                        Text("LANSCAPE STUDIO • HASIL TANTANGAN")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .black))
                            .tracking(1.4)
                            .foregroundColor(Color(hex: "F87171"))
                    }
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 5 : 3.5)
                    .background(Color(hex: "1E293B").opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color(hex: "EF4444").opacity(0.3), lineWidth: 1)
                    )
                    
                    // 2. Center Studio Seal Graphic
                    ZStack {
                        // Ambient Warm Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "EF4444").opacity(0.35),
                                        Color(hex: "EF4444").opacity(0.05),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: isPad ? 56 : 38
                                )
                            )
                            .frame(width: isPad ? 110 : 76, height: isPad ? 110 : 76)
                            .scaleEffect(haloScale)
                        
                        Circle()
                            .fill(Color(hex: "1E293B"))
                            .frame(width: isPad ? 64 : 46, height: isPad ? 64 : 46)
                            .overlay(
                                Circle().stroke(Color(hex: "EF4444"), lineWidth: 2)
                            )
                        
                        Image(systemName: penaltySfSymbol)
                            .font(.system(size: isPad ? 32 : 22, weight: .bold))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                    
                    // 3. Main Title
                    Text("Hukuman Aktif: \(penaltySticker.title)")
                        .font(.system(size: isPad ? 22 : 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.3)
                    
                    // 4. Pill Badge
                    HStack(spacing: 5) {
                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        Text("Stiker Wajah Diterapkan")
                            .font(.system(size: isPad ? 12 : 9.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 16 : 12)
                    .padding(.vertical, isPad ? 5 : 3.5)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EF4444"), Color(hex: "B91C1C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    
                    // 5. Subtitle
                    Text("Sayang sekali waktu habis! Stiker lucu akan menghiasi foto ini. Tetap kompak ya!")
                        .font(.system(size: isPad ? 13 : 9.5, weight: .medium))
                        .foregroundColor(Color(hex: "94A3B8"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isPad ? 28 : 16)
                        .lineLimit(2)
                    
                    // 6. Auto-Advance Indicator (matches camera workflow)
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Color(hex: "F87171"))
                            .frame(width: 6, height: 6)
                            .scaleEffect(haloScale)
                        Text("Melanjutkan sesi foto...")
                            .font(.system(size: isPad ? 11 : 8.5, weight: .medium))
                            .foregroundColor(Color(hex: "64748B"))
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, isPad ? 18 : 12)
                .frame(width: cardWidth, height: cardHeight)
            }
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                haloScale = 1.15
            }
        }
    }
    
    private var penaltySfSymbol: String {
        switch penaltySticker {
        case .clown:
            return "face.smiling.inverse"
        case .banana:
            return "leaf.fill"
        case .slippingGlasses, .snorkelGoggles, .donutGlasses:
            return "eyeglasses"
        case .frogEyes, .spiralEyes:
            return "eyes"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview("Challenge Success Overlay - Studio Card", traits: .landscapeLeft) {
    ChallengeSuccessOverlay()
}

#Preview("Challenge Failure Overlay - Studio Card", traits: .landscapeLeft) {
    ChallengeFailureOverlay(penaltySticker: .clown)
}
