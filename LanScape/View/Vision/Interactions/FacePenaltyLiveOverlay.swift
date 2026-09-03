//
//  FacePenaltyLiveOverlay.swift
//  LanScape
//

import SwiftUI

struct FacePenaltyLiveOverlay: View {
    @ObservedObject var penaltyService: FacePenaltyService
    let geometry: GeometryProxy
    
    @State private var wobble: Bool = false
    
    var body: some View {
        ZStack {
            if penaltyService.isPenaltyActive {
                // Render stickers over each detected or fallback face
                ForEach(penaltyService.detectedFaces) { face in
                    let rect = face.normalizedRect
                    let viewW = geometry.size.width
                    let viewH = geometry.size.height
                    
                    // Vision coordinates: (0,0) is bottom-left
                    let faceX = rect.origin.x * viewW
                    let faceY = (1.0 - rect.origin.y - rect.height) * viewH
                    let faceWidth = rect.width * viewW
                    let faceHeight = rect.height * viewH
                    
                    // Sticker container positioned on face
                    VStack(spacing: 2) {
                        Text(face.sticker.rawValue)
                            .font(.system(size: max(64, faceWidth * 0.95)))
                            .rotationEffect(.degrees(wobble ? 8 : -8))
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: wobble)
                    }
                    .position(
                        x: faceX + faceWidth / 2,
                        y: faceY + faceHeight * 0.35
                    )
                }
                
                // Funny status indicator badge at top-center under header
                VStack {
                    HStack(spacing: 8) {
                        Text(penaltyService.currentPenaltySticker.rawValue)
                        Text("HUKUMAN AKTIF: \(penaltyService.currentPenaltySticker.title)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 6)
                    .padding(.top, 74)
                    
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            wobble = true
        }
    }
}
