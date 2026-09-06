import SwiftUI

// MARK: - Data Model
struct GalleryItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let date: String
    let hasAudio: Bool
}

// MARK: - Tape Decor
enum TapeStyle {
    case topLeftYellow
    case topRightYellow
    case bottomRightBlue
}

// MARK: - Wave Shape Background
struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat = 20
    var wavelengthDivisor: CGFloat = 1.5

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midHeight = rect.height / 2
        let wavelength = width / wavelengthDivisor

        path.move(to: CGPoint(x: 0, y: midHeight))
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

// MARK: - Main View
struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var wavePhase: CGFloat = 0
    @State private var selectedPhoto: GalleryItem? = nil

    // Sample items using actual bundle image assets
    let sampleItems: [GalleryItem] = [
        GalleryItem(imageName: "markHaechan", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: true),
        GalleryItem(imageName: "pose 1", title: "Pose Pertama", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "pose2", title: "Pose Kedua", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "pose3", title: "Pose Ketiga", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "pose4", title: "Pose Keempat", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "pose5", title: "Pose Kelima", date: "21 Agustus 2026", hasAudio: false)
    ]

    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Background waves
            backgroundWaves
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed top bar: Always visible and never requires swiping/holding down
                topBar(isPad: isPad)

                // Photos scroll view
                ScrollView(.vertical, showsIndicators: false) {
                    photoGrid(isPad: isPad)
                        .padding(.horizontal, isPad ? 40 : 54)
                        .padding(.top, isPad ? 16 : 10)
                        .padding(.bottom, isPad ? 32 : 20)
                }
            }
            
            // Full Photo Preview Popup
            if let photo = selectedPhoto {
                photoDetailModal(item: photo, isPad: isPad)
            }
        }
        .background(Color(hex: "F7FAFD"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }

    // MARK: - Background Waves
    private var backgroundWaves: some View {
        GeometryReader { geo in
            VStack(spacing: geo.size.height * 0.35) {
                WaveShape(phase: wavePhase, amplitude: 25, wavelengthDivisor: 1.1)
                    .stroke(Color.blue.opacity(0.14), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .frame(height: 70)

                WaveShape(phase: wavePhase + .pi, amplitude: 25, wavelengthDivisor: 1.1)
                    .stroke(Color.blue.opacity(0.14), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .frame(height: 70)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Fixed Top Bar
    private func topBar(isPad: Bool) -> some View {
        HStack(alignment: .center) {
            // Home button
            Button {
                dismiss()
                NotificationCenter.default.post(name: NSNotification.Name("PopToRoot"), object: nil)
            } label: {
                circleIconButton(systemName: "house.fill", isPad: isPad)
            }

            Spacer()

            // Header Title
            VStack(spacing: isPad ? 4 : 1) {
                Text("Galeri Foto")
                    .font(.system(size: isPad ? 30 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.darkBlue)

                Text("Lihat kembali momen seru kalian bergerak bersama.")
                    .font(.system(size: isPad ? 15 : 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Sort button
            Button {
                // Sorting action
            } label: {
                circleIconButton(systemName: "arrow.up.arrow.down", isPad: isPad)
            }
        }
        .padding(.horizontal, isPad ? 40 : 54)
        .padding(.top, isPad ? 16 : 8)
        .padding(.bottom, isPad ? 12 : 8)
        .background(
            Color.white.opacity(0.92)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .zIndex(10)
    }

    private func circleIconButton(systemName: String, isPad: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: isPad ? 18 : 14, weight: .semibold))
            .foregroundColor(Color.darkBlue)
            .frame(width: isPad ? 46 : 36, height: isPad ? 46 : 36)
            .background(Circle().fill(Color.white))
            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
    }

    // MARK: - Grid Foto
    private func photoGrid(isPad: Bool) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: isPad ? 20 : 12),
            GridItem(.flexible(), spacing: isPad ? 20 : 12),
            GridItem(.flexible(), spacing: isPad ? 20 : 12)
        ]

        return LazyVGrid(columns: columns, spacing: isPad ? 22 : 12) {
            ForEach(Array(sampleItems.enumerated()), id: \.element.id) { index, item in
                GalleryCardView(item: item, tapeStyle: tapeStyle(for: index), isPad: isPad)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedPhoto = item
                        }
                    }
            }
        }
    }

    private func tapeStyle(for index: Int) -> TapeStyle {
        switch index % 3 {
        case 0: return .topLeftYellow
        case 2: return .topRightYellow
        default: return .bottomRightBlue
        }
    }
    
    // MARK: - Photo Detail Modal
    @ViewBuilder
    private func photoDetailModal(item: GalleryItem, isPad: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { selectedPhoto = nil }
                }

            VStack(spacing: isPad ? 16 : 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: isPad ? 24 : 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(item.date)
                            .font(.system(size: isPad ? 16 : 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation { selectedPhoto = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: isPad ? 32 : 24))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, isPad ? 24 : 14)
                
                safeImageView(named: item.imageName)
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxHeight: isPad ? 420 : 220)
                    .clipShape(RoundedRectangle(cornerRadius: isPad ? 20 : 14))
                    .shadow(color: .black.opacity(0.4), radius: 12)
            }
            .padding(isPad ? 24 : 14)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 24 : 16)
                    .fill(Color(hex: "1F2937").opacity(0.95))
            )
            .padding(.horizontal, isPad ? 60 : 40)
        }
        .zIndex(20)
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }

    @ViewBuilder
    private func safeImageView(named name: String) -> some View {
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
        } else {
            Image("markHaechan")
                .resizable()
        }
    }
}

// MARK: - Card per Item
struct GalleryCardView: View {
    let item: GalleryItem
    let tapeStyle: TapeStyle
    var isPad: Bool = UIDevice.isIPad

    var body: some View {
        ZStack(alignment: tapeAlignment) {
            VStack(alignment: .leading, spacing: isPad ? 8 : 4) {
                // Card Image
                safeCardImage(named: item.imageName)
                    .aspectRatio(1.8, contentMode: .fill)
                    .frame(maxHeight: isPad ? 140 : 75)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: isPad ? 14 : 10))
                    .padding(isPad ? 8 : 5)

                // Title + Audio icon
                HStack(spacing: 4) {
                    if item.hasAudio {
                        Image(systemName: "music.note")
                            .font(.system(size: isPad ? 13 : 10))
                            .foregroundColor(Color.darkBlue)
                    }
                    Text(item.title)
                        .font(.system(size: isPad ? 16 : 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
                .padding(.horizontal, isPad ? 10 : 7)

                // Date
                Text(item.date)
                    .font(.system(size: isPad ? 12 : 9, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, isPad ? 10 : 7)
                    .padding(.bottom, isPad ? 10 : 6)
            }
            .background(
                RoundedRectangle(cornerRadius: isPad ? 18 : 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
            )

            // Colorful tape sticker overlay on corners
            tapeSticker
                .offset(
                    x: tapeOffsetX,
                    y: tapeOffsetY
                )
        }
    }

    @ViewBuilder
    private func safeCardImage(named name: String) -> some View {
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
        } else {
            Image("markHaechan")
                .resizable()
        }
    }

    // MARK: - Tape Decorator
    @ViewBuilder
    private var tapeSticker: some View {
        let tapeW: CGFloat = isPad ? 50 : 34
        let tapeH: CGFloat = isPad ? 14 : 9
        
        switch tapeStyle {
        case .topLeftYellow:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "FDE047").opacity(0.85))
                .frame(width: tapeW, height: tapeH)
                .rotationEffect(.degrees(-18))
                .shadow(color: .black.opacity(0.12), radius: 2)

        case .topRightYellow:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "FDE047").opacity(0.85))
                .frame(width: tapeW, height: tapeH)
                .rotationEffect(.degrees(18))
                .shadow(color: .black.opacity(0.12), radius: 2)

        case .bottomRightBlue:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "93C5FD").opacity(0.85))
                .frame(width: tapeW, height: tapeH)
                .rotationEffect(.degrees(-12))
                .shadow(color: .black.opacity(0.12), radius: 2)
        }
    }

    private var tapeAlignment: Alignment {
        switch tapeStyle {
        case .topLeftYellow: return .topLeading
        case .topRightYellow: return .topTrailing
        case .bottomRightBlue: return .bottomTrailing
        }
    }

    private var tapeOffsetX: CGFloat {
        switch tapeStyle {
        case .topLeftYellow: return isPad ? -8 : -5
        case .topRightYellow: return isPad ? 8 : 5
        case .bottomRightBlue: return isPad ? 6 : 4
        }
    }

    private var tapeOffsetY: CGFloat {
        switch tapeStyle {
        case .topLeftYellow: return isPad ? -6 : -4
        case .topRightYellow: return isPad ? -6 : -4
        case .bottomRightBlue: return isPad ? 6 : 4
        }
    }
}

#Preview("Gallery - Phone Landscape", traits: .landscapeLeft) {
    GalleryView()
}

#Preview("Gallery - iPad Landscape", traits: .landscapeRight) {
    GalleryView()
}
