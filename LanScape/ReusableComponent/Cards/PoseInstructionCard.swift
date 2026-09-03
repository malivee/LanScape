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
        VStack(spacing: 8) {
            // Cheerful pill tag
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color.orange)
                    .font(.system(size: 13, weight: .bold))
                Text("IKUTI GAYA POSE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(Color.darkBlue)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 4)
            .padding(.top, 4)
            
            Text(mainTitle)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Text(subTitle)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "5A6E85"))
                .padding(.bottom, 6)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 44)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFFFFF"), Color(hex: "F0F6FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.9), lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 8)
        )
        .frame(maxWidth: 680)
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
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.35), lineWidth: 2.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(8)
            
            Text("Target")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue)
                .clipShape(Capsule())
                .padding(8)
        }
        .frame(width: width, height: height)
    }
}

#Preview("Pose Instruction & Mini Badge") {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        
        VStack(spacing: 30) {
            PoseInstructionView(
                mainTitle: "Pose Pertama",
                subTitle: "Pose Fusion",
                imageName: "pose 1"
            )
            
            MiniPoseThumbnailBadge(imageName: "pose 1", size: 175)
        }
    }
}
