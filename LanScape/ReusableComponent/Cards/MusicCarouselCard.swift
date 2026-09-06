import SwiftUI

struct MusicCarouselCard: View {
    let music: MusicData
    let isSelected: Bool
    var cardWidth: CGFloat = 330
    var cardHeight: CGFloat = 390
    
    @State private var wavePhase: Bool = false
    
    private var artworkWidth: CGFloat {
        max(120, cardWidth - 28)
    }
    
    private var artworkHeight: CGFloat {
        max(90, cardHeight * 0.60)
    }
    
    var body: some View {
        let isCompact = cardHeight < 300
        
        VStack(alignment: .center, spacing: 0) {
            // Album Artwork Container
            ZStack(alignment: .bottomTrailing) {
                if let imageName = music.coverImageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artworkWidth, height: artworkHeight)
                        .clipped()
                } else {
                    // Stylized vibrant cover
                    ZStack {
                        LinearGradient(
                            colors: music.coverColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Decorative ambient circles
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: artworkWidth * 0.55, height: artworkWidth * 0.55)
                            .offset(x: -artworkWidth * 0.18, y: -artworkHeight * 0.15)
                        
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: artworkWidth * 0.45, height: artworkWidth * 0.45)
                            .offset(x: artworkWidth * 0.2, y: artworkHeight * 0.2)
                        
                        VStack(spacing: isCompact ? 4 : 8) {
                            Image(systemName: music.coverIcon)
                                .font(.system(size: isCompact ? 36 : 68, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 8)
                            
                            if !music.artist.isEmpty {
                                Text(music.artist)
                                    .font(.system(size: isCompact ? 12 : 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(width: artworkWidth, height: artworkHeight)
                }
                
                // Currently Playing Preview Badge
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: isCompact ? 10 : 13, weight: .bold))
                        Text("Preview")
                            .font(.system(size: isCompact ? 10 : 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isCompact ? 7 : 10)
                    .padding(.vertical, isCompact ? 3 : 5)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(isCompact ? 6 : 10)
                }
            }
            .frame(width: artworkWidth, height: artworkHeight)
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 12 : 18))
            .shadow(color: isSelected ? music.coverColors.first?.opacity(0.4) ?? .clear : .clear, radius: 10)
            
            Spacer(minLength: isCompact ? 4 : 10)
            
            Text(music.title)
                .fontWeight(.bold)
                .font(.system(size: isCompact ? 17 : 26, design: .rounded))
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer(minLength: isCompact ? 2 : 4)
            
            HStack(spacing: isCompact ? 8 : 12) {
                HStack(spacing: 3) {
                    Image(systemName: "figure.dance")
                        .font(.system(size: isCompact ? 11 : 14))
                    Text("\(music.moves) gerakan")
                }
                
                Text("•")
                
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: isCompact ? 11 : 14))
                    Text(music.duration)
                }
            }
            .fontWeight(.medium)
            .font(.system(size: isCompact ? 12 : 18, design: .rounded))
            .foregroundColor(.secondary)
        }
        .padding(isCompact ? 10 : 16)
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 16 : 22))
        .overlay {
            RoundedRectangle(cornerRadius: isCompact ? 16 : 22)
                .stroke(isSelected ? Color.darkBlue : Color.clear, lineWidth: isCompact ? 3.5 : 6)
        }
        .shadow(
            color: .black.opacity(isSelected ? 0.22 : 0.08),
            radius: isSelected ? (isCompact ? 10 : 16) : 6,
            x: 0,
            y: isSelected ? (isCompact ? 4 : 8) : 3
        )
    }
}

