//
//  PoseCardView.swift
//  LanScape
//

import SwiftUI

struct PoseCardView: View {
    var title: String = "Pose Pertama"
    var subtitle: String = "Pose Fusion"
    var imageName: String = "pose 1"
    var isCompact: Bool = false
    
    var body: some View {
        if isCompact {
            // Compact thumbnail for top-right corner
            MiniPoseThumbnailBadge(imageName: imageName, size: 175)
        } else {
            // Full preview card before game/movement
            PoseInstructionView(
                mainTitle: title,
                subTitle: subtitle,
                imageName: imageName
            )
        }
    }
}

#Preview("Pose Card View - Full") {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        PoseCardView(title: "Pose Pertama", subtitle: "Pose Fusion", imageName: "pose 1")
    }
}

#Preview("Pose Card View - Compact") {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        PoseCardView(title: "Pose 1", imageName: "pose 1", isCompact: true)
    }
}
