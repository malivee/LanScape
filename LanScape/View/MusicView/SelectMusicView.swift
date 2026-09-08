import SwiftUI

struct SelectMusicView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedMusic: MusicData? = nil

    // Controls carousel position only.
    // Does NOT open the movement panel.
    @State private var carouselIndex: Int? = 0

    @State private var navigateToPoseTracking = false
    @State private var isStartingSession = false
    @State private var previewPoseItem: (imageName: String, title: String)? = nil

    // Back button appears independently from the content.
    @State private var showBackButton = false

    @ObservedObject private var musicService = BackgroundMusicService.shared

    private let musicItems = MusicData.sample
    private let cardSpacing: CGFloat = 20

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad || geometry.size.height > 550

            let panelWidth = isPad
                ? geometry.size.width * 0.30
                : min(
                    CGFloat(340),
                    geometry.size.width * 0.38
                )

            let mainWidth = selectedMusic == nil
                ? geometry.size.width
                : geometry.size.width - panelWidth

            ZStack {
                // MARK: Main Content

                HStack(spacing: 0) {
                    musicSelectionView(
                        totalWidth: mainWidth,
                        totalHeight: geometry.size.height,
                        isPad: isPad
                    )
                    .frame(width: mainWidth)

                    // Movement panel ONLY appears
                    // after tapping a music card.
                    if let music = selectedMusic {
                        movementSequencePanel(
                            for: music,
                            isPad: isPad
                        )
                        .frame(width: panelWidth)
                        .transition(
                            .move(edge: .trailing)
                        )
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // MARK: Back Button
                //
                // This is outside musicSelectionView,
                // so it does not wait for the carousel
                // or movement panel.

                if showBackButton {
                    VStack {
                        HStack {
                            Button {
                                musicService.stop()
                                dismiss()
                            } label: {
                                Image(
                                    systemName: "chevron.left"
                                )
                                .font(
                                    .system(
                                        size: isPad ? 20 : 16,
                                        weight: .bold
                                    )
                                )
                                .foregroundColor(.darkBlue)
                                .frame(
                                    width: isPad ? 44 : 36,
                                    height: isPad ? 44 : 36
                                )
                                .background(
                                    Color.white.opacity(0.95)
                                )
                                .clipShape(Circle())
                                .shadow(
                                    color: .black.opacity(0.15),
                                    radius: 5,
                                    y: 2
                                )
                            }

                            Spacer()
                        }
                        .padding(
                            .horizontal,
                            isPad ? 32 : 20
                        )
                        .padding(
                            .top,
                            isPad ? 16 : 12
                        )

                        Spacer()
                    }
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.85)
                        )
                    )
                    .zIndex(50)
                }

                // MARK: Pose Preview

                if let item = previewPoseItem {
                    posePreviewModal(
                        item: item,
                        isPad: isPad
                    )
                }

                // MARK: Loading Overlay

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

        // MARK: Pose Tracking

        .fullScreenCover(
            isPresented: $navigateToPoseTracking
        ) {
            PoseTrackingView(
                selectedMusic: selectedMusic ?? musicItems.first
            )
        }

        // MARK: Navigation State

        .onChange(
            of: navigateToPoseTracking
        ) { _, isPresented in
            if !isPresented {
                isStartingSession = false
            }
        }

        // MARK: Page Start

        .onAppear {
            // Back button appears as soon as
            // this page starts.
            withAnimation(
                .easeOut(duration: 0.2)
            ) {
                showBackButton = true
            }

            CameraService.shared.warmUp()
        }

        // MARK: Page Disappear

        .onDisappear {
            if !navigateToPoseTracking {
                musicService.stop()
            }

            showBackButton = false
        }
    }

    // MARK: - Music Selection View

    private func musicSelectionView(
        totalWidth: CGFloat,
        totalHeight: CGFloat,
        isPad: Bool
    ) -> some View {
        let cardW: CGFloat = isPad ? 330 : 200
        let cardH: CGFloat = isPad ? 390 : 210
        let carouselH: CGFloat = isPad ? 420 : 230

        return ZStack {
            // MARK: Background

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
                .blur(
                    radius: isPad ? 150 : 80
                )
                .offset(
                    y: isPad ? 80 : 40
                )
                .allowsHitTesting(false)

            // MARK: Content

            VStack(
                spacing: isPad ? 30 : 8
            ) {
                // IMPORTANT:
                // No Spacer before the title.
                // This keeps the title at the top.

                VStack(
                    spacing: isPad ? 6 : 2
                ) {
                    Text("Yuk, pilih lagu!")
                        .font(
                            .system(
                                size: isPad ? 38 : 20,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)

                    Text(
                        "Pilih musik favoritmu dan dengarkan cuplikannya!"
                    )
                    .font(
                        .system(
                            size: isPad ? 18 : 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                // MARK: Music Carousel

                musicCarousel(
                    availableWidth: totalWidth,
                    cardW: cardW,
                    cardH: cardH,
                    carouselH: carouselH
                )

                // MARK: Page Indicator

                DotPageIndicator(
                    totalPages: musicItems.count,
                    currentPage: carouselIndex ?? 0
                )
                .scaleEffect(
                    isPad ? 1.0 : 0.85
                )

                Spacer()
            }

            // Push the whole content slightly below
            // the Back button without centering it.

            .padding(
                .top,
                isPad ? 80 : 50
            )

            .padding(
                .bottom,
                isPad ? 16 : 6
            )
        }
    }

    // MARK: - Music Carousel

    private func musicCarousel(
        availableWidth: CGFloat,
        cardW: CGFloat,
        cardH: CGFloat,
        carouselH: CGFloat
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                LazyHStack(
                    spacing: cardSpacing
                ) {
                    ForEach(
                        Array(
                            musicItems.enumerated()
                        ),
                        id: \.element.id
                    ) { index, music in
                        let isSelected =
                            carouselIndex == index

                        MusicCarouselCard(
                            music: music,
                            isSelected: isSelected,
                            cardWidth: isSelected
                                ? cardW
                                : cardW * 0.85,
                            cardHeight: cardH
                        )
                        .id(index)
                        .scaleEffect(
                            isSelected
                                ? 1.0
                                : 0.88
                        )
                        .frame(
                            width: isSelected
                                ? cardW
                                : cardW * 0.85,
                            height: cardH
                        )
                        .zIndex(
                            cardZIndex(
                                for: index,
                                isSelected: isSelected
                            )
                        )
                        .offset(
                            y: isSelected
                                ? 0
                                : (cardH < 300 ? 10 : 20)
                        )
                        .animation(
                            .easeInOut(
                                duration: 0.25
                            ),
                            value: isSelected
                        )
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: 18
                            )
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                carouselIndex = index
                                selectMusic(at: index)
                            }
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(
                    .horizontal,
                    horizontalPadding(
                        availableWidth: availableWidth,
                        cardWidth: cardW
                    )
                )
            }
            .scrollPosition(
                id: $carouselIndex,
                anchor: .center
            )
            .scrollTargetBehavior(
                .viewAligned(
                    anchor: .center
                )
            )
            .frame(height: carouselH)
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(
                        carouselIndex ?? 0,
                        anchor: .center
                    )
                }
            }
            // FIX: Re-center and update highlight layout when panel opens/closes
            .onChange(of: selectedMusic) { _, newValue in
                if newValue != nil, let index = carouselIndex {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Movement Sequence Panel

    @ViewBuilder
    private func movementSequencePanel(
        for music: MusicData,
        isPad: Bool
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: isPad ? 18 : 8
        ) {
            // MARK: Header

            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(music.title)
                        .font(
                            .system(
                                size: isPad ? 24 : 17,
                                weight: .bold
                            )
                        )
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("5 Gerakan Pose")
                        .font(
                            .system(
                                size: isPad ? 15 : 12,
                                weight: .medium
                            )
                        )
                        .foregroundColor(
                            .white.opacity(0.8)
                        )
                }

                Spacer()

                CloseIconButton {
                    withAnimation(
                        .easeInOut
                    ) {
                        selectedMusic = nil
                    }
                }
                .scaleEffect(
                    isPad ? 1.0 : 0.85
                )
            }

            // MARK: Movement List

            ZStack(alignment: .bottom) {
                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    VStack(
                        spacing: isPad ? 16 : 8
                    ) {
                        // Pose 1

                        MovementItemCard(
                            imageName: "pose 1",
                            title: "Pose Pertama",
                            imageHeight: isPad
                                ? 140
                                : 65,
                            titleFontSize: isPad
                                ? 22
                                : 13
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.75
                                )
                            ) {
                                previewPoseItem = (
                                    "pose 1",
                                    "Pose Pertama - Pose Fusion"
                                )
                            }
                        }

                        // Pose 2

                        MovementItemCard(
                            imageName: "pose2",
                            title: "Pose Kedua",
                            imageHeight: isPad
                                ? 140
                                : 65,
                            titleFontSize: isPad
                                ? 22
                                : 13
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.75
                                )
                            ) {
                                previewPoseItem = (
                                    "pose2",
                                    "Pose Kedua"
                                )
                            }
                        }

                        // Pose 3

                        MovementItemCard(
                            imageName: "pose3",
                            title: "Pose Ketiga",
                            imageHeight: isPad
                                ? 140
                                : 65,
                            titleFontSize: isPad
                                ? 22
                                : 13
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.75
                                )
                            ) {
                                previewPoseItem = (
                                    "pose3",
                                    "Pose Ketiga"
                                )
                            }
                        }

                        // Pose 4

                        MovementItemCard(
                            imageName: "pose4",
                            title: "Pose Keempat",
                            imageHeight: isPad
                                ? 140
                                : 65,
                            titleFontSize: isPad
                                ? 22
                                : 13
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.75
                                )
                            ) {
                                previewPoseItem = (
                                    "pose4",
                                    "Pose Keempat"
                                )
                            }
                        }

                        // Pose 5

                        MovementItemCard(
                            imageName: "pose5",
                            title: "Pose Kelima",
                            imageHeight: isPad
                                ? 140
                                : 65,
                            titleFontSize: isPad
                                ? 22
                                : 13
                        ) {
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.75
                                )
                            ) {
                                previewPoseItem = (
                                    "pose5",
                                    "Pose Kelima"
                                )
                            }
                        }

                        Spacer()
                            .frame(
                                height: isPad
                                    ? 70
                                    : 54
                            )
                    }
                }

                // MARK: Start Button

                GradientStartButton(
                    title: "Mulai Bergerak",
                    fontSize: isPad
                        ? 20
                        : 15,
                    fontWeight: .bold
                ) {
                    withAnimation(
                        .easeInOut(
                            duration: 0.15
                        )
                    ) {
                        isStartingSession = true
                    }

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.12
                    ) {
                        navigateToPoseTracking = true
                    }
                }
                .padding(.bottom, 6)
                .frame(
                    maxWidth: isPad
                        ? 260
                        : .infinity
                )
                .frame(
                    height: isPad
                        ? 56
                        : 44
                )
            }
            .frame(maxHeight: .infinity)
        }

        .padding(
            isPad ? 16 : 10
        )

        .background(
            Color.darkBlue
        )

        .clipShape(
            .rect(
                cornerRadius: isPad
                    ? 20
                    : 16
            )
        )

        .padding(
            .vertical,
            isPad ? 10 : 6
        )

        .padding(
            .trailing,
            isPad ? 10 : 6
        )
    }

    // MARK: - Select Music

    private func selectMusic(at index: Int) {
        guard musicItems.indices.contains(index) else {
            return
        }

        let music = musicItems[index]

        withAnimation(
            .easeInOut
        ) {
            selectedMusic = music
        }

        // Start music preview.

        musicService.play(
            assetName: music.assetName,
            isLooping: true,
            volume: 0.85
        )
    }

    // MARK: - Card Z Index

    private func cardZIndex(
        for index: Int,
        isSelected: Bool
    ) -> Double {
        guard !isSelected else {
            return 100
        }

        let currentIndex =
            carouselIndex ?? 0

        let distance = abs(
            index - currentIndex
        )

        return Double(-distance)
    }

    // MARK: - Horizontal Padding

    private func horizontalPadding(
        availableWidth: CGFloat,
        cardWidth: CGFloat
    ) -> CGFloat {
        max(
            0,
            (availableWidth - cardWidth) / 2
        )
    }

    // MARK: - Pose Preview Modal

    @ViewBuilder
    private func posePreviewModal(
        item: (
            imageName: String,
            title: String
        ),
        isPad: Bool
    ) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        previewPoseItem = nil
                    }
                }

            VStack(
                spacing: isPad
                    ? 14
                    : 8
            ) {
                // MARK: Modal Header

                HStack {
                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text(
                            "CONTOH GAYA POSE"
                        )
                        .font(
                            .system(
                                size: isPad
                                    ? 14
                                    : 10,
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundColor(
                            Color.orange
                        )

                        Text(item.title)
                            .font(
                                .system(
                                    size: isPad
                                        ? 24
                                        : 16,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundColor(
                                Color.darkBlue
                            )
                    }

                    Spacer()

                    CloseIconButton {
                        withAnimation {
                            previewPoseItem = nil
                        }
                    }
                    .scaleEffect(
                        isPad
                            ? 1.0
                            : 0.8
                    )
                }

                .padding(
                    .horizontal,
                    isPad ? 20 : 12
                )

                .padding(
                    .top,
                    isPad ? 16 : 10
                )

                // MARK: Pose Image

                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxHeight: isPad
                            ? 380
                            : 190
                    )
                    .padding(
                        .horizontal,
                        isPad ? 24 : 12
                    )
                    .padding(
                        .bottom,
                        isPad ? 16 : 10
                    )
            }

            .frame(
                maxWidth: isPad
                    ? 520
                    : 340
            )

            .background(
                RoundedRectangle(
                    cornerRadius: isPad
                        ? 24
                        : 16
                )
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 16,
                    x: 0,
                    y: 8
                )
            )

            .padding(
                .horizontal,
                20
            )
        }

        .zIndex(100)

        .transition(
            .opacity.combined(
                with: .scale(
                    scale: 0.92
                )
            )
        )
    }
}

// MARK: - Preview

#Preview(
    "Main Music Selection - Phone",
    traits: .landscapeLeft
) {
    SelectMusicView()
}

#Preview(
    "Main Music Selection - iPad",
    traits: .landscapeRight
) {
    SelectMusicView()
}
