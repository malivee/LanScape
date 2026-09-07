//
//  PhotoStripView.swift
//  stamppal
//
//

import SwiftUI
import UIKit

struct PhotoStripView: View {
    
    let image: UIImage?
    let images: [UIImage]?
    
    /// Convenience initializer for passing a single composite image (e.g. postcard strip)
    init(image: UIImage?) {
        self.image = image
        self.images = nil
    }
    
    /// Convenience initializer for passing individual photos to render vertically
    init(images: [UIImage]) {
        self.images = images
        self.image = nil
    }

    var body: some View {
        ZStack {
            Color.white

            if let image {
                // Pre-rendered composite strip image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else if let images, !images.isEmpty {
                // Dynamic vertical stack layout for array of photos
                GeometryReader { geo in
                    let availableHeight = geo.size.height - 24 // Padding buffer
                    let spacing: CGFloat = 8
                    let totalSpacing = spacing * CGFloat(images.count - 1)
                    let imageHeight = (availableHeight - totalSpacing) / CGFloat(images.count)

                    VStack(spacing: spacing) {
                        ForEach(Array(images.prefix(5).enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: max(30, imageHeight))
                                .clipped()
                        }
                    }
                    .padding(12)
                }
            } else {
                // Fallback placeholder state
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32, weight: .light))

                    Text("Foto Strip")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(
            color: .black.opacity(0.14),
            radius: 7,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Previews

#Preview("Single Strip Image") {
    PhotoStripView(image: nil)
        .frame(width: 180, height: 450)
        .padding()
        .background(Color.gray.opacity(0.2))
}

#Preview("Multiple Images Array") {
    PhotoStripView(images: [
        UIImage(systemName: "star.fill")!,
        UIImage(systemName: "heart.fill")!,
        UIImage(systemName: "bolt.fill")!
    ])
    .frame(width: 180, height: 450)
    .padding()
    .background(Color.blue.opacity(0.1))
}
