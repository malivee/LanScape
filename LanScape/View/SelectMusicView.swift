import SwiftUI

struct SelectMusicView: View {
    @State private var selectedMusic: MusicData?
    @State private var selectedIndex: Int? = 1
    
    private let musicItems = MusicData.sample
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        GeometryReader {geometry in
            HStack(spacing: 0) {
                
                musicSelectionView
                    .frame(
                        width: selectionWidth(
                            for: geometry.size.width
                        )
                    )
                
                if let music = selectedMusic {
                    MovementSequenceView(
                        music: music,
                        onDismiss: {
                            withAnimation(.easeInOut) {
                                selectedMusic = nil
                            }
                        }
                    )
                    .frame(
                        width: geometry.size.width * 0.28
                    )
                    .transition(
                        .move(edge: .trailing)
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private var musicSelectionView: some View {
        GeometryReader {geometry in
            ZStack {
                Color.white
                
                VStack(spacing: 40) {
                    
                    Spacer()
                    
                    VStack (spacing: 20){
                        Text("Yuk, pilih lagu!")
                            .font(.system(size: 40,weight: .bold))
                            .foregroundStyle(.black)
                        
                        Text("Temukan musik yang ingin kalian nikmati sambil bergerak bersama.")
                            .font(.system(size: 20,weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 40)
                    
                    musicCarousel(
                        availableWidth: geometry.size.width
                    )
                    
                    pageIndicator
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func musicCarousel(
        availableWidth: CGFloat
    ) -> some View {
        
        ScrollViewReader {proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(
                        Array(musicItems.enumerated()),
                        id: \.element.id
                    ) { index, music in
                        
                        carouselCard(
                            music: music,
                            index: index
                        )
                    }
                }
                .scrollTargetLayout()
                .padding(
                    .horizontal,
                    horizontalPadding(
                        availableWidth: availableWidth
                    )
                )
            }
            .scrollPosition(
                id: $selectedIndex,
                anchor: .center
            )
            .scrollTargetBehavior(
                .viewAligned(
                    anchor: .center
                )
            )
            .frame(height: 420)
            .onChange(
                of: selectedIndex
            ) { _, newIndex in
                
                guard let newIndex else {
                    return
                }
                
                selectMusic(at: newIndex)
            }
            .onAppear {
                guard let index = selectedIndex else {
                    return
                }
                
                DispatchQueue.main.async {
                    proxy.scrollTo(
                        index,
                        anchor: .center
                    )
                    
                    selectMusic(at: index)
                }
            }
        }
    }
    
    private func carouselCard(
        music: MusicData,
        index: Int
    ) -> some View {
        let isSelected = selectedIndex == index
        
        return MusicCardView(
            music: music,
            isSelected: isSelected
        )
        .id(index)
        .scaleEffect(
            isSelected ? 1.0 : 0.8
        )
        .frame(
            width: isSelected ? 330 : 264,
            height: 390
        )
        .zIndex(
            cardZIndex(
                for: index,
                isSelected: isSelected
            )
        )
        .offset(
            y: isSelected ? 0 : 25
        )
        .animation(
            .easeInOut(duration: 0.25),
            value: isSelected
        )
        .contentShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedIndex = index
            }
        }
    }
    
    private func cardZIndex(
        for index: Int,
        isSelected: Bool
    ) -> Double {
        
        guard !isSelected else {
            return 100
        }
        
        let currentIndex = selectedIndex ?? 0
        let distance = abs(
            index - currentIndex
        )
        
        return Double(-distance)
    }
    
    private func cardScale(
        isSelected: Bool
    ) -> CGFloat {isSelected ? 1.0 : 0.80}
    
    private func cardYOffset(
        isSelected: Bool
    ) -> CGFloat {isSelected ? 0 : 25}
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(
                musicItems.indices,
                id: \.self
            ) { index in
                
                Circle()
                    .fill(
                        selectedIndex == index
                        ? Color.darkBlue
                        : Color.gray.opacity(0.3)
                    )
                    .frame(
                        width: selectedIndex == index
                        ? 10
                        : 7,
                        height: selectedIndex == index
                        ? 10
                        : 7
                    )
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: selectedIndex
                    )
            }
        }
    }
    
    private func selectMusic(
        at index: Int
    ) {
        guard musicItems.indices.contains(index) else {
            return
        }
        
        withAnimation(.easeInOut) {
            selectedMusic = musicItems[index]
        }
    }
    
    private func selectionWidth(
        for totalWidth: CGFloat
    ) -> CGFloat {
        selectedMusic == nil
        ? totalWidth
        : totalWidth * 0.72
    }
    
    private func horizontalPadding(
        availableWidth: CGFloat
    ) -> CGFloat {
        max(
            0,
            (availableWidth - 330) / 2
        )
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
        .frame(width: 330,height: 390)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 18))
        
        .overlay {RoundedRectangle(cornerRadius: 18)
            .stroke(isSelected ? Color.darkBlue : Color.clear,lineWidth: 8)
        }
        
        .shadow(color: .black.opacity(isSelected ? 0.25 : 0.12),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: isSelected ? 6 : 4
        )
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
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        ),
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        ),
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        ),
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        ),
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        ),
        .init(
            image: .jarangPulang,
            title: "Jarang Pulang",
            duration: "30",
            moves: "5"
        )
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
                    imageName: "Mountain Pose",
                    title: "Mountain Pose"
                )
                
                MovementCard(
                    imageName: "Tree Pose",
                    title: "Tree Pose"
                )
                
                MovementCard(
                    imageName: "Warrior 2",
                    title: "Warrior 2"
                )
                
                MovementCard(
                    imageName: "Warrior 3",
                    title: "Warrior 3"
                )
            }
            
            Spacer()
            
            Button {
                // mulai movement
            } label: {
                Text("Mulai")
                    .font(
                        .system(
                            size: 22,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                .gradient1,
                                .gradient2,
                                .gradient3
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(
                        color: .black.opacity(0.5),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
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
                .frame(height: 85)
            
            Text(title)
                .font(
                    .system(
                        size: 18,
                        weight: .medium
                    )
                )
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(
            .rect(cornerRadius: 14)
        )
    }
}


#Preview {
    SelectMusicView()
}
