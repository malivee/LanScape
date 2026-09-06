import SwiftUI

struct SelectMusicView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMusic: MusicData?
    @State private var selectedIndex: Int? = 0
    @State private var navigateToPoseTracking = false
    @State private var isStartingSession = false
    @State private var previewPoseItem: (imageName: String, title: String)? = nil
    
    @ObservedObject private var musicService = BackgroundMusicService.shared
    
    private let musicItems = MusicData.sample
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad || geometry.size.height > 550
            let panelWidth = isPad ? geometry.size.width * 0.30 : min(CGFloat(340), geometry.size.width * 0.38)
            let mainWidth = selectedMusic == nil ? geometry.size.width : (geometry.size.width - panelWidth)
            
            ZStack {
                HStack(spacing: 0) {
                    musicSelectionView(totalWidth: mainWidth, totalHeight: geometry.size.height, isPad: isPad)
                        .frame(width: mainWidth)
                    
                    if let music = selectedMusic {
                        movementSequencePanel(for: music, isPad: isPad)
                            .frame(width: panelWidth)
                            .transition(.move(edge: .trailing))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                if let item = previewPoseItem {
                    posePreviewModal(item: item, isPad: isPad)
                }
                
                if isStartingSession {
                    GameLoadingView(
                        title: "Menyiapkan Panggung...",
                        subtitle: "Pastikan seluruh tubuh kalian terlihat di kamera ya!"
                    )
                    .transition(.opacity)
                    .zIndex(200)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $navigateToPoseTracking) {
            PoseTrackingView(selectedMusic: selectedMusic ?? musicItems.first)
        }
        .onChange(of: navigateToPoseTracking) { _, isPresented in
            if !isPresented {
                isStartingSession = false
            }
        }
        .onAppear {
            CameraService.shared.warmUp()
        }
        .onDisappear {
            // Stop preview when popping back to main menu
            if !navigateToPoseTracking {
                musicService.stop()
            }
        }
    }
    
    private func musicSelectionView(totalWidth: CGFloat, totalHeight: CGFloat, isPad: Bool) -> some View {
        let cardW: CGFloat = isPad ? 330 : 200
        let cardH: CGFloat = isPad ? 390 : 210
        let carouselH: CGFloat = isPad ? 420 : 230
        
        return ZStack {
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
                        endRadius: isPad ? 700 : 350
                    )
                )
                .frame(
                    width: totalWidth * 1.3,
                    height: isPad ? 400 : 250
                )
                .blur(radius: isPad ? 150 : 80)
                .offset(y: isPad ? 80 : 40)
                .allowsHitTesting(false)
            
            VStack(spacing: isPad ? 30 : 8) {
                HStack {
                    Button {
                        musicService.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: isPad ? 20 : 16, weight: .bold))
                            .foregroundColor(.darkBlue)
                            .frame(width: isPad ? 44 : 36, height: isPad ? 44 : 36)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, isPad ? 32 : 20)
                .padding(.top, isPad ? 16 : 8)

                if isPad {
                    Spacer()
                }
                
                VStack(spacing: isPad ? 6 : 2) {
                    Text("Yuk, pilih lagu!")
                        .font(.system(size: isPad ? 38 : 20, weight: .bold))
                        .foregroundStyle(.black)
                    
                    Text("Pilih musik favoritmu dan dengarkan cuplikannya!")
                        .font(.system(size: isPad ? 18 : 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                musicCarousel(availableWidth: totalWidth, cardW: cardW, cardH: cardH, carouselH: carouselH)
                
                DotPageIndicator(
                    totalPages: musicItems.count,
                    currentPage: selectedIndex ?? 0
                )
                .scaleEffect(isPad ? 1.0 : 0.85)
                
                Spacer()
            }
            .padding(.bottom, isPad ? 16 : 6)
        }
    }
    
    private func musicCarousel(availableWidth: CGFloat, cardW: CGFloat, cardH: CGFloat, carouselH: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(Array(musicItems.enumerated()), id: \.element.id) { index, music in
                        let isSelected = selectedIndex == index
                        
                        MusicCarouselCard(
                            music: music,
                            isSelected: isSelected,
                            cardWidth: isSelected ? cardW : cardW * 0.85,
                            cardHeight: cardH
                        )
                        .id(index)
                        .scaleEffect(isSelected ? 1.0 : 0.88)
                        .frame(width: isSelected ? cardW : cardW * 0.85, height: cardH)
                        .zIndex(cardZIndex(for: index, isSelected: isSelected))
                        .offset(y: isSelected ? 0 : (cardH < 300 ? 10 : 20))
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
                .padding(.horizontal, horizontalPadding(availableWidth: availableWidth, cardWidth: cardW))
            }
            .scrollPosition(id: $selectedIndex, anchor: .center)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .frame(height: carouselH)
            .onChange(of: selectedIndex) { _, newIndex in
                guard let newIndex else { return }
                selectMusic(at: newIndex)
            }
            .onAppear {
                let index = selectedIndex ?? 0
                DispatchQueue.main.async {
                    proxy.scrollTo(index, anchor: .center)
                    selectMusic(at: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func movementSequencePanel(for music: MusicData, isPad: Bool) -> some View {
        VStack(alignment: .leading, spacing: isPad ? 18 : 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(music.title)
                        .font(.system(size: isPad ? 24 : 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("5 Gerakan Pose")
                        .font(.system(size: isPad ? 15 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                CloseIconButton {
                    withAnimation(.easeInOut) {
                        selectedMusic = nil
                    }
                }
                .scaleEffect(isPad ? 1.0 : 0.85)
            }
            
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isPad ? 16 : 8) {
                        MovementItemCard(imageName: "pose 1", title: "Pose Pertama", imageHeight: isPad ? 140 : 65, titleFontSize: isPad ? 22 : 13) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                previewPoseItem = ("pose 1", "Pose Pertama - Pose Fusion")
                            }
                        }
                        MovementItemCard(imageName: "pose2", title: "Pose Kedua", imageHeight: isPad ? 140 : 65, titleFontSize: isPad ? 22 : 13) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                previewPoseItem = ("pose2", "Pose Kedua")
                            }
                        }
                        MovementItemCard(imageName: "pose3", title: "Pose Ketiga", imageHeight: isPad ? 140 : 65, titleFontSize: isPad ? 22 : 13) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                previewPoseItem = ("pose3", "Pose Ketiga")
                            }
                        }
                        MovementItemCard(imageName: "pose4", title: "Pose Keempat", imageHeight: isPad ? 140 : 65, titleFontSize: isPad ? 22 : 13) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                previewPoseItem = ("pose4", "Pose Keempat")
                            }
                        }
                        MovementItemCard(imageName: "pose5", title: "Pose Kelima", imageHeight: isPad ? 140 : 65, titleFontSize: isPad ? 22 : 13) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                previewPoseItem = ("pose5", "Pose Kelima")
                            }
                        }
                        
                        Spacer()
                            .frame(height: isPad ? 70 : 54)
                    }
                }
                
                GradientStartButton(title: "Mulai Bergerak", fontSize: isPad ? 20 : 15, fontWeight: .bold) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isStartingSession = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        navigateToPoseTracking = true
                    }
                }
                .padding(.bottom, 6)
                .frame(maxWidth: isPad ? 260 : .infinity)
                .frame(height: isPad ? 56 : 44)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(isPad ? 16 : 10)
        .background(Color.darkBlue)
        .clipShape(.rect(cornerRadius: isPad ? 20 : 16))
        .padding(.vertical, isPad ? 10 : 6)
        .padding(.trailing, isPad ? 10 : 6)
    }
    
    private func selectMusic(at index: Int) {
        guard musicItems.indices.contains(index) else { return }
        let music = musicItems[index]
        withAnimation(.easeInOut) {
            selectedMusic = music
        }
        // Preview the newly selected song immediately
        musicService.play(assetName: music.assetName, isLooping: true, volume: 0.85)
    }
    
    private func cardZIndex(for index: Int, isSelected: Bool) -> Double {
        guard !isSelected else { return 100 }
        let currentIndex = selectedIndex ?? 0
        let distance = abs(index - currentIndex)
        return Double(-distance)
    }
    
    private func horizontalPadding(availableWidth: CGFloat, cardWidth: CGFloat) -> CGFloat {
        max(0, (availableWidth - cardWidth) / 2)
    }
    
    // MARK: - Pose Preview Modal
    @ViewBuilder
    private func posePreviewModal(item: (imageName: String, title: String), isPad: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { previewPoseItem = nil }
                }
            
            VStack(spacing: isPad ? 14 : 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CONTOH GAYA POSE")
                            .font(.system(size: isPad ? 14 : 10, weight: .black, design: .rounded))
                            .foregroundColor(Color.orange)
                        Text(item.title)
                            .font(.system(size: isPad ? 24 : 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.darkBlue)
                    }
                    
                    Spacer()
                    
                    CloseIconButton {
                        withAnimation { previewPoseItem = nil }
                    }
                    .scaleEffect(isPad ? 1.0 : 0.8)
                }
                .padding(.horizontal, isPad ? 20 : 12)
                .padding(.top, isPad ? 16 : 10)
                
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: isPad ? 380 : 190)
                    .padding(.horizontal, isPad ? 24 : 12)
                    .padding(.bottom, isPad ? 16 : 10)
            }
            .frame(maxWidth: isPad ? 520 : 340)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 24 : 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 20)
        }
        .zIndex(100)
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }
}

#Preview("Main Music Selection - Phone", traits: .landscapeLeft) {
    SelectMusicView()
}

#Preview("Main Music Selection - iPad", traits: .landscapeRight) {
    SelectMusicView()
}

