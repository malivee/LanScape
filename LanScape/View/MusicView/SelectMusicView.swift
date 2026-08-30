import SwiftUI

struct SelectMusicView: View {
    @State private var selectedMusic: MusicData?
    @State private var selectedIndex: Int? = 1
    
    private let musicItems = MusicData.sample
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                musicSelectionView
                    .frame(width: selectionWidth(for: geometry.size.width))
                
                
                if let music = selectedMusic {
                    movementSequencePanel(for: music)
                        .frame(width: geometry.size.width * 0.28)
                        .transition(.move(edge: .trailing))
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    
    
    private var musicSelectionView: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.gradientSelectMusic1,
                                Color.gradientSelectMusic2,
                                Color.gradientSelectMusic3
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 700
                        )
                    )
                    .frame(
                        width: geometry.size.width * 1.4,
                        height: 400
                    )
                    .blur(radius: 150)
                    .offset(y: 80)
                    .allowsHitTesting(false)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("Yuk, pilih lagu!")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.black)
                        
                        Text("Pilih musik favoritmu dan bergerak bersama")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    musicCarousel(availableWidth: geometry.size.width)
                    
                    DotPageIndicator(
                        totalPages: musicItems.count,
                        currentPage: selectedIndex ?? 0
                    )
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func musicCarousel(availableWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(Array(musicItems.enumerated()), id: \.element.id) { index, music in
                        
                        let isSelected = selectedIndex == index
                        
                        
                        MusicCarouselCard(music: music, isSelected: isSelected)
                            .id(index)
                            .scaleEffect(isSelected ? 1.0 : 0.8)
                            .frame(width: isSelected ? 330 : 264, height: 390)
                            .zIndex(cardZIndex(for: index, isSelected: isSelected))
                            .offset(y: isSelected ? 0 : 25)
                            .animation(.easeInOut(duration: 0.25), value: isSelected)
                            .contentShape(RoundedRectangle(cornerRadius: 18))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    selectedIndex = index
                                }
                            }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalPadding(availableWidth: availableWidth))
            }
            .scrollPosition(id: $selectedIndex, anchor: .center)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .frame(height: 420)
            .onChange(of: selectedIndex) { _, newIndex in
                guard let newIndex else { return }
                selectMusic(at: newIndex)
            }
            .onAppear {
                guard let index = selectedIndex else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(index, anchor: .center)
                    selectMusic(at: index)
                }
            }
        }
    }
    
   
    
    @ViewBuilder
    private func movementSequencePanel(for music: MusicData) -> some View {
        VStack(alignment: .leading, spacing: 30) {
            
            HStack {
                Text("List Gerakan")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                
                CloseIconButton {
                    withAnimation(.easeInOut) {
                        selectedMusic = nil
                    }
                } 
            }
            
            ZStack (alignment:.bottom){
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        MovementItemCard(imageName: "Fusion", title: "Pose Fusion")
                        MovementItemCard(imageName: "Fusion", title: "Pose Fusion")
                        MovementItemCard(imageName: "Fusion", title: "Pose Fusion")
                        MovementItemCard(imageName: "Fusion", title: "Pose Fusion")
                        Spacer()
                            .frame(height: 60)
                    }
                }
                
                GradientStartButton(title: "Mulai", fontSize: 22, fontWeight: .bold) {
                    // mulai movement
                }
                .padding(.bottom, 10)
                .frame(width: 280, height: 60)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(20)
      
        .background(Color.darkBlue)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.vertical, 10)
        .padding(.trailing, 10)
    }
    
    
    
    private func selectMusic(at index: Int) {
        guard musicItems.indices.contains(index) else { return }
        withAnimation(.easeInOut) {
            selectedMusic = musicItems[index]
        }
    }
    
    private func cardZIndex(for index: Int, isSelected: Bool) -> Double {
        guard !isSelected else { return 100 }
        let currentIndex = selectedIndex ?? 0
        let distance = abs(index - currentIndex)
        return Double(-distance)
    }
    
    private func selectionWidth(for totalWidth: CGFloat) -> CGFloat {
        selectedMusic == nil ? totalWidth : totalWidth * 0.72
    }
    
    private func horizontalPadding(availableWidth: CGFloat) -> CGFloat {
        max(0, (availableWidth - 330) / 2)
    }
}

#Preview("Main Music Selection") {
    SelectMusicView()
        .previewInterfaceOrientation(.landscapeRight)
}
