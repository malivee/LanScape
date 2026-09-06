//
//  ChallengeSuccessFailureOverlay.swift
//  LanScape
//

import SwiftUI

struct ChallengeSuccessOverlay: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 16 : 8) {
                // Confetti / Celebration Icon
                Text("🎉")
                    .font(.system(size: isPad ? 80 : 44))
                    .scaleEffect(scale)
                
                Text("HORE, KALIAN BERHASIL!")
                    .font(.system(size: isPad ? 42 : 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.green.opacity(0.8), radius: isPad ? 16 : 8)
                
                Text("Tantangan selesai dengan hebat! Bersiap untuk foto selanjutnya...")
                    .font(.system(size: isPad ? 20 : 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, isPad ? 48 : 24)
            .padding(.vertical, isPad ? 32 : 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "00B09B").opacity(0.95), Color(hex: "96C93D").opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 32 : 20))
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 32 : 20)
                    .stroke(Color.white, lineWidth: isPad ? 3 : 2)
            )
            .shadow(color: Color.green.opacity(0.6), radius: isPad ? 30 : 16)
            .scaleEffect(scale)
            .opacity(opacity)
            .padding(.horizontal, isPad ? 40 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct ChallengeFailureOverlay: View {
    let penaltySticker: PenaltyStickerType
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 14 : 6) {
                // Penalty Sticker Graphic
                Text(penaltySticker.rawValue)
                    .font(.system(size: isPad ? 84 : 44))
                    .scaleEffect(scale)
                
                Text("WAKTU HABIS!")
                    .font(.system(size: isPad ? 42 : 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.red.opacity(0.8), radius: isPad ? 16 : 8)
                
                Text("Yah, kalian belum berhasil! Muka kalian terkena hukuman:")
                    .font(.system(size: isPad ? 20 : 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text("\(penaltySticker.rawValue) \(penaltySticker.title)")
                    .font(.system(size: isPad ? 28 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, isPad ? 24 : 14)
                    .padding(.vertical, isPad ? 8 : 4)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                
                Text("Stiker ini akan menempel di wajah kalian pada foto berikutnya! 😜")
                    .font(.system(size: isPad ? 16 : 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, isPad ? 48 : 24)
            .padding(.vertical, isPad ? 32 : 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "EB3349").opacity(0.95), Color(hex: "F45C43").opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 32 : 20))
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 32 : 20)
                    .stroke(Color.white, lineWidth: isPad ? 3 : 2)
            )
            .shadow(color: Color.red.opacity(0.6), radius: isPad ? 30 : 16)
            .scaleEffect(scale)
            .opacity(opacity)
            .padding(.horizontal, isPad ? 40 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
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


