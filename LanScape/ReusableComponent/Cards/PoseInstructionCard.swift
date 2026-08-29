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
        VStack(spacing: 6) {
            Text(mainTitle)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.top, 4)
            
            Text(subTitle)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "707C91"))
                .padding(.bottom, 8)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 48)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "EEF5FF"))
                .shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 10)
        )
        .frame(maxWidth: 720)
    }
}

/// Mini thumbnail badge positioned at the top-right corner during gameplay/tutorial.
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
        ZStack {
            // Translucent rounded container matching reference design
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "E2E8F0").opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 5)
            
            // Mannequin pose image
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(10)
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
