import SwiftUI

struct MusicCarouselCard: View {
    let music: MusicData
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(music.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 290, height: 260)
                .clipShape(.rect(cornerRadius: 18))
            
            Spacer()
            
            Text(music.title)
                .fontWeight(.medium)
                .font(.system(size: 30))
                .foregroundColor(.black)
            
            Spacer()
            
            HStack {
                HStack {
                    Image(systemName: "stopwatch")
                    Text("\(music.duration) detik")
                }
                Spacer()
                HStack {
                    Image(systemName: "figure.dance")
                    Text("\(music.moves) gerakan")
                }
            }
            .fontWeight(.medium)
            .font(.system(size: 20))
            .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 330, height: 390)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                // Ubah Color.blue jadi Color.darkBlue jika error warnamu sudah diperbaiki
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 8)
        }
        .shadow(
            color: .black.opacity(isSelected ? 0.25 : 0.12),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: isSelected ? 6 : 4
        )
    }
}

#Preview("Music Carousel Card") {
    HStack {
        MusicCarouselCard(music: MusicData.sample[0], isSelected: true)
        MusicCarouselCard(music: MusicData.sample[0], isSelected: false)
    }
    .padding()
}
