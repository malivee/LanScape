//
//  ChallengeSuccessFailureOverlay.swift
//  LanScape
//
//  Designed in Clean White Photobooth Card aesthetic matching the light pastel theme.
//  Provides clean, human-designed, friendly cards for both Win and Loss states.
//

import SwiftUI

// MARK: - Challenge Success Overlay
struct ChallengeSuccessOverlay: View {
    var onDismiss: (() -> Void)? = nil
    
    @State private var cardScale: CGFloat = 0.88
    @State private var cardOpacity: Double = 0.0
    @State private var iconBounce: CGFloat = 0.92
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let cardWidth: CGFloat = isPad ? 520 : 380
        let cardHeight: CGFloat = isPad ? 310 : 230
        
        ZStack {
            // Soft translucent backdrop over live camera
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            // Clean White Photobooth Card
            ZStack {
                RoundedRectangle(cornerRadius: isPad ? 26 : 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: 20, y: 8)
                
                VStack(spacing: isPad ? 14 : 8) {
                    // 1. Soft Mint Status Pill
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(red: 0.08, green: 0.65, blue: 0.38))
                        Text("TANTANGAN BERHASIL")
                            .font(.system(size: isPad ? 11.5 : 9, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(Color(red: 0.08, green: 0.65, blue: 0.38))
                    }
                    .padding(.horizontal, isPad ? 16 : 12)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color(red: 0.88, green: 0.98, blue: 0.92))
                    .clipShape(Capsule())
                    
                    // 2. Friendly Center Graphic
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.88, green: 0.98, blue: 0.92))
                            .frame(width: isPad ? 72 : 52, height: isPad ? 72 : 52)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: isPad ? 36 : 26, weight: .bold))
                            .foregroundColor(Color(red: 0.08, green: 0.65, blue: 0.38))
                            .scaleEffect(iconBounce)
                    }
                    
                    // 3. Main Title (Crisp Black Bold)
                    Text("Luar Biasa Kompak!")
                        .font(.system(size: isPad ? 24 : 17, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    // 4. Subtitle (Readable Slate Gray)
                    Text("Kalian berhasil menyelesaikan tantangan bersama tanpa hukuman!")
                        .font(.system(size: isPad ? 14 : 10, weight: .regular))
                        .foregroundColor(Color(red: 0.35, green: 0.40, blue: 0.50))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isPad ? 32 : 18)
                        .lineLimit(2)
                    
                    // 5. Bottom Navigation Indicator (Matching CompletionButton Navy Tone)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.08, green: 0.65, blue: 0.38))
                            .frame(width: 6, height: 6)
                        Text("Melanjutkan sesi foto...")
                            .font(.system(size: isPad ? 12 : 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.20, green: 0.39, blue: 0.70))
                    }
                    .padding(.top, 2)
                }
                .padding(isPad ? 22 : 14)
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                iconBounce = 1.12
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
    @State private var iconBounce: CGFloat = 0.92
    
    var body: some View {
        let isPad = UIDevice.isIPad
        let cardWidth: CGFloat = isPad ? 520 : 380
        let cardHeight: CGFloat = isPad ? 310 : 230
        
        ZStack {
            // Soft translucent backdrop over live camera
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            // Clean White Photobooth Card (Identical Geometry to Success)
            ZStack {
                RoundedRectangle(cornerRadius: isPad ? 26 : 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: 20, y: 8)
                
                VStack(spacing: isPad ? 14 : 8) {
                    // 1. Soft Rose Status Pill
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: isPad ? 13 : 10, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                        Text("WAKTU HABIS")
                            .font(.system(size: isPad ? 11.5 : 9, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                    }
                    .padding(.horizontal, isPad ? 16 : 12)
                    .padding(.vertical, isPad ? 6 : 4)
                    .background(Color(red: 1.0, green: 0.92, blue: 0.92))
                    .clipShape(Capsule())
                    
                    // 2. Friendly Center Graphic
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.92, blue: 0.92))
                            .frame(width: isPad ? 72 : 52, height: isPad ? 72 : 52)
                        
                        Image(systemName: penaltySfSymbol)
                            .font(.system(size: isPad ? 34 : 24, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                            .scaleEffect(iconBounce)
                    }
                    
                    // 3. Main Title (Crisp Black Bold)
                    Text("Hukuman: \(penaltySticker.title)")
                        .font(.system(size: isPad ? 24 : 17, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    // 4. Subtitle (Readable Slate Gray)
                    Text("Sayang sekali waktu habis! Stiker lucu akan terpasang di foto ini. Tetap semangat ya!")
                        .font(.system(size: isPad ? 14 : 10, weight: .regular))
                        .foregroundColor(Color(red: 0.35, green: 0.40, blue: 0.50))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isPad ? 32 : 18)
                        .lineLimit(2)
                    
                    // 5. Bottom Navigation Indicator (Matching CompletionButton Navy Tone)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.25, blue: 0.25))
                            .frame(width: 6, height: 6)
                        Text("Melanjutkan sesi foto...")
                            .font(.system(size: isPad ? 12 : 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.20, green: 0.39, blue: 0.70))
                    }
                    .padding(.top, 2)
                }
                .padding(isPad ? 22 : 14)
            }
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                iconBounce = 1.12
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
            return "theatermasks.fill"
        }
    }
}

#Preview("Challenge Success Overlay - Clean White Card", traits: .landscapeLeft) {
    ChallengeSuccessOverlay()
}

#Preview("Challenge Failure Overlay - Clean White Card", traits: .landscapeLeft) {
    ChallengeFailureOverlay(penaltySticker: .clown)
}
