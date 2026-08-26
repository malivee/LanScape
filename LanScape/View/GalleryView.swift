import SwiftUI

// Data Model
struct GalleryItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let date: String
    let hasAudio: Bool
}

// Tape Decor
enum TapeStyle {
    case topLeftYellow
    case topRightYellow
    case bottomRightBlue
}

// Wave Shape Background Awal
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

// Main View
struct GalleryView: View {

    @State private var wavePhase: CGFloat = 0

    let sampleItems: [GalleryItem] = [
        GalleryItem(imageName: "photo1", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: true),
        GalleryItem(imageName: "photo2", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "photo3", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "photo4", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "photo5", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: false),
        GalleryItem(imageName: "photo6", title: "Jarang Pulang", date: "21 Agustus 2026", hasAudio: false)
    ]

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            backgroundWaves

            ScrollView {
                VStack(spacing: 10) {
                    topBar
                    header
                    photoGrid
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }

    // Wave Shape Background Lanjutan
    var backgroundWaves: some View {
        VStack(spacing: 200) {
            WaveShape(phase: wavePhase, amplitude: 30, wavelengthDivisor: 1.1)
                .stroke(Color.blue.opacity(0.22), style: StrokeStyle(lineWidth: 30, lineCap: .round))
                .frame(height: 100)

            WaveShape(phase: wavePhase + .pi, amplitude: 30, wavelengthDivisor: 1.1)
                .stroke(Color.blue.opacity(0.22), style: StrokeStyle(lineWidth: 30, lineCap: .round))
                .frame(height: 100)
        }
        .padding(.top, 170)
    }

    // Top Bar (Home dan Sorting)
    var topBar: some View {
        HStack {
            circleIconButton(systemName: "house.fill")
            Spacer()
            circleIconButton(systemName: "arrow.up.arrow.down")
        }
    }

    func circleIconButton(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.black)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Color.white))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // Header
    var header: some View {
        VStack(spacing: 8) {
            Text("Galeri Foto")
                .font(.system(size: 34, weight: .bold))

            Text("Lihat kembali momen seru kalian bergerak bersama.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    // Grid Foto
    var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(Array(sampleItems.enumerated()), id: \.element.id) { index, item in
                GalleryCardView(item: item, tapeStyle: tapeStyle(for: index))
            }
        }
    }

    // Kolom 0 & 3 -> tape kuning kiri, kolom 2 & 5 -> tape kuning kanan, kolom tengah -> tape biru bawah
    func tapeStyle(for index: Int) -> TapeStyle {
        switch index % 3 {
        case 0: return .topLeftYellow
        case 2: return .topRightYellow
        default: return .bottomRightBlue
        }
    }
}

// Card per Item
struct GalleryCardView: View {
    let item: GalleryItem
    let tapeStyle: TapeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(item.imageName)
                .resizable()
                .aspectRatio(2, contentMode: .fill)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(10)

            HStack(spacing: 6) {
                if item.hasAudio {
                    Image(systemName: "music.note")
                        .font(.system(size: 14))
                }
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.horizontal, 10)

            Text(item.date)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        
    }

    var topOverlayAlignment: Alignment {
        tapeStyle == .topLeftYellow ? .topLeading : .topTrailing
    }

}

#Preview {
    GalleryView()
}
