//
//  ChallengeSuccessFailureOverlay.swift
//  LanScape
//

import SwiftUI

struct ChallengeSuccessOverlay: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Confetti / Celebration Icon
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                
                Text("HORE, KALIAN BERHASIL!")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.green.opacity(0.8), radius: 16)
                
                Text("Tantangan selesai dengan hebat! Bersiap untuk foto selanjutnya...")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [Color(hex: "00B09B").opacity(0.95), Color(hex: "96C93D").opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: Color.green.opacity(0.6), radius: 30)
            .scaleEffect(scale)
            .opacity(opacity)
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
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Penalty Sticker Graphic
                Text(penaltySticker.rawValue)
                    .font(.system(size: 84))
                    .scaleEffect(scale)
                
                Text("WAKTU HABIS!")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.red.opacity(0.8), radius: 16)
                
                Text("Yah, kalian belum berhasil! Muka kalian terkena hukuman:")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text("\(penaltySticker.rawValue) \(penaltySticker.title)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                
                Text("Stiker ini akan menempel di wajah kalian pada foto berikutnya! 😜")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [Color(hex: "EB3349").opacity(0.95), Color(hex: "F45C43").opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: Color.red.opacity(0.6), radius: 30)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
