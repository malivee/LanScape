//
//  PoseInstructionCard.swift
//  LanScape
//

import SwiftUI

/// Large centered pose preview card shown before starting gameplay / in tutorial.
struct PoseInstructionView: View {
    var mainTitle: String = "Pose Pertama"
    var subTitle: String = "Pose Fusion"
    var imageName: String = "pose 1"
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        VStack(spacing: isPad ? 8 : 4) {
            // Cheerful pill tag
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color.orange)
                    .font(.system(size: isPad ? 13 : 10, weight: .bold))
                Text("IKUTI GAYA POSE")
                    .font(.system(size: isPad ? 14 : 11, weight: .black, design: .rounded))
                    .foregroundColor(Color.darkBlue)
            }
            .padding(.horizontal, isPad ? 14 : 10)
            .padding(.vertical, isPad ? 6 : 4)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 4)
            .padding(.top, isPad ? 4 : 2)
            
            Text(mainTitle)
                .font(.system(size: isPad ? 36 : 22, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Text(subTitle)
                .font(.system(size: isPad ? 20 : 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "5A6E85"))
                .padding(.bottom, isPad ? 6 : 2)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: isPad ? 280 : 120)
                .padding(.horizontal, isPad ? 20 : 10)
                .padding(.bottom, isPad ? 6 : 2)
        }
        .padding(.vertical, isPad ? 24 : 10)
        .padding(.horizontal, isPad ? 44 : 24)
        .background(
            RoundedRectangle(cornerRadius: isPad ? 32 : 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFFFFF"), Color(hex: "F0F6FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPad ? 32 : 20)
                        .stroke(Color.white.opacity(0.9), lineWidth: isPad ? 3 : 2)
                )
                .shadow(color: Color.black.opacity(0.22), radius: isPad ? 24 : 12, x: 0, y: isPad ? 8 : 4)
        )
        .frame(maxWidth: isPad ? 680 : 420)
    }
}

/// Mini thumbnail badge positioned at the top-right corner during gameplay.
struct MiniPoseThumbnailBadge: View {
    var imageName: String = "pose 1"
    var width: CGFloat = 175
    var height: CGFloat = 135
    
    init(imageName: String = "pose 1", size: CGFloat = 175) {
        self.imageName = imageName
        self.width = size
        self.height = size * 0.77
    }
    
    init(imageName: String = "pose 1", width: CGFloat, height: CGFloat) {
        self.imageName = imageName
        self.width = width
        self.height = height
    }
    
    var body: some View {
        let isSmall = width < 120
        
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: isSmall ? 12 : 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: isSmall ? 12 : 20)
                        .stroke(Color.blue.opacity(0.35), lineWidth: isSmall ? 1.5 : 2.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: isSmall ? 5 : 10, x: 0, y: isSmall ? 2 : 4)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(isSmall ? 4 : 8)
            
            Text("Target")
                .font(.system(size: isSmall ? 8 : 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, isSmall ? 5 : 8)
                .padding(.vertical, isSmall ? 2 : 3)
                .background(Color.blue)
                .clipShape(Capsule())
                .padding(isSmall ? 4 : 8)
        }
        .frame(width: width, height: height)
    }
}

#Preview("Pose Instruction & Mini Badge - Phone", traits: .landscapeLeft) {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        
        VStack(spacing: 20) {
            PoseInstructionView(
                mainTitle: "Pose Pertama",
                subTitle: "Pose Fusion",
                imageName: "pose 1"
            )
            
            MiniPoseThumbnailBadge(imageName: "pose 1", size: 100)
        }
    }
}

