import SwiftUI

struct SelectMusicView: View {
    @State private var selectedMusic: MusicData?
    
    private let musicItems = MusicData.sample
    private let itemsPerPage = 3
    
    private var pageCount: Int {
        Int(ceil(Double(musicItems.count) / Double(itemsPerPage)))
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                musicSelectionView
                    .frame(width: selectionWidth(for: geometry.size.width))
                
                if let music = selectedMusic {
                    MovementSequenceView(
                        music: music,
                        onDismiss: {
                            selectedMusic = nil
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private var musicSelectionView: some View {
        ZStack {
            Color.white
            
            VStack {
                Text("Yuk, pilih lagu!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                
                TabView {
                    ForEach(0..<pageCount, id: \.self) { pageIndex in
                        musicPageView(pageIndex: pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
    
    private func musicPageView(pageIndex: Int) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<itemsPerPage, id: \.self) { cardIndex in
                let index = pageIndex * itemsPerPage + cardIndex
                
                if index < musicItems.count {
                    let music = musicItems[index]
                    
                    MusicCardView(
                        music: music,
                        isSelected: selectedMusic?.id == music.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedMusic = music
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func selectionWidth(for totalWidth: CGFloat) -> CGFloat {
        selectedMusic == nil ? totalWidth : totalWidth * 0.72
    }
}

struct MusicCardView: View {
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
                .stroke(isSelected ? Color.darkBlue : Color.clear, lineWidth: 8)
        }
        .shadow(radius: isSelected ? 10 : 5)
    }
}

struct MusicData: Identifiable {
    let id = UUID()
    var image: ImageResource
    var title: String
    var duration: String
    var moves: String
}

extension MusicData {
    static let sample: [MusicData] = [
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5")
    ]
}

struct MovementSequenceView: View {
    let music: MusicData
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("List Gerakan")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut) {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(10)
            }
            
            VStack(spacing: 12) {
                MovementCard(
                    imageName: "movement1",
                    title: "Gerakan 1"
                )
                
                MovementCard(
                    imageName: "movement2",
                    title: "Gerakan 2"
                )
                
                MovementCard(
                    imageName: "movement3",
                    title: "Gerakan 3"
                )
            }
            
            Spacer()
            
            Button {
                // mulai movement
            } label: {
                Text("Mulai")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.gradient1, .gradient2, .gradient3],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            Color.blue.opacity(0.25)
        )
        .clipShape(
            .rect(cornerRadius: 20)
        )
        .padding(.vertical, 10)
        .padding(.trailing, 10)
    }
}

struct MovementCard: View {
    let imageName: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            Color.white
        )
        .clipShape(
            .rect(cornerRadius: 14)
        )
    }
}

#Preview {
    SelectMusicView()
}
