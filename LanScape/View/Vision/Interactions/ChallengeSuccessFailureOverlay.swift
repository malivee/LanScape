//
//  ChallengeSuccessFailureOverlay.swift
//  LanScape
//

import SwiftUI

struct ChallengeSuccessOverlay: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 14 : 8) {
                Spacer()
                
                // 1. Top Header
                Text("TANTANGAN BERHASIL!")
                    .font(.system(size: isPad ? 26 : 17, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                    .tracking(0.8)
                
                // 2. Center Graphic
                Text("🎉")
                    .font(.system(size: isPad ? 80 : 48))
                    .scaleEffect(scale)
                
                // 3. Pill Badge
                Text("Luar Biasa Kompak!")
                    .font(.system(size: isPad ? 15 : 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 22 : 14)
                    .padding(.vertical, isPad ? 7 : 4.5)
                    .background(Color(hex: "10B981"))
                    .clipShape(Capsule())
                
                // 4. Subtitle
                Text("Hebat sekali! Kalian berhasil menyelesaikan tantangan ini bersama-sama!")
                    .font(.system(size: isPad ? 14 : 10, weight: .regular))
                    .foregroundColor(Color(hex: "CBD5E1"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct ChallengeFailureOverlay: View {
    let penaltySticker: PenaltyStickerType
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 14 : 8) {
                Spacer()
                
                // 1. Top Header (Reference Match: "HUKUMAN AKTIF")
                Text("HUKUMAN AKTIF")
                    .font(.system(size: isPad ? 26 : 17, weight: .bold))
                    .foregroundColor(Color(hex: "EF4444"))
                    .tracking(0.8)
                
                // 2. Center Graphic (Reference Match: Big Emoji)
                Text(penaltySticker.rawValue)
                    .font(.system(size: isPad ? 80 : 48))
                    .scaleEffect(scale)
                
                // 3. Pill Badge (Reference Match: Red Pill with Sticker Title)
                Text(penaltySticker.title)
                    .font(.system(size: isPad ? 15 : 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, isPad ? 22 : 14)
                    .padding(.vertical, isPad ? 7 : 4.5)
                    .background(Color(hex: "EF4444"))
                    .clipShape(Capsule())
                
                // 4. Subtitle (Reference Match: Family Friendly Comforting Copy)
                Text("Sayang sekali kamu harus mendapatkan hukuman ini, next harus lebih kompak yaa")
                    .font(.system(size: isPad ? 14 : 10, weight: .regular))
                    .foregroundColor(Color(hex: "CBD5E1"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview("Challenge Success Overlay - Phone", traits: .landscapeLeft) {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        ChallengeSuccessOverlay()
    }
}

#Preview("Challenge Failure Overlay - Phone", traits: .landscapeLeft) {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        ChallengeFailureOverlay(penaltySticker: .clown)
    }
}
