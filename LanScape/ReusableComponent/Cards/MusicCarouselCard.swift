import SwiftUI

struct MusicCarouselCard: View {
    let music: MusicData
    let isSelected: Bool
    
    @State private var wavePhase: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Album Artwork Container
            ZStack(alignment: .bottomTrailing) {
                if let imageName = music.coverImageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 290, height: 250)
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
                            .frame(width: 170, height: 170)
                            .offset(x: -50, y: -40)
                        
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 140, height: 140)
                            .offset(x: 60, y: 50)
                        
                        VStack(spacing: 8) {
                            Image(systemName: music.coverIcon)
                                .font(.system(size: 68, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 8)
                            
                            if !music.artist.isEmpty {
                                Text(music.artist)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(width: 290, height: 250)
                }
                
                // Currently Playing Preview Badge
                if isSelected {
                    HStack(spacing: 5) {
                        Image(systemName: "waveform")
                            .font(.system(size: 13, weight: .bold))
                        Text("Preview")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(10)
                }
            }
            .frame(width: 290, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: isSelected ? music.coverColors.first?.opacity(0.4) ?? .clear : .clear, radius: 10)
            
            Spacer(minLength: 10)
            
            Text(music.title)
                .fontWeight(.bold)
                .font(.system(size: 26, design: .rounded))
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.dance")
                    Text("\(music.moves) pose")
                }
                
                Text("•")
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(music.duration)
                }
            }
            .fontWeight(.medium)
            .font(.system(size: 18, design: .rounded))
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 330, height: 390)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isSelected ? Color.darkBlue : Color.clear, lineWidth: 6)
        }
        .shadow(
            color: .black.opacity(isSelected ? 0.22 : 0.08),
            radius: isSelected ? 16 : 6,
            x: 0,
            y: isSelected ? 8 : 3
        )
    }
}
