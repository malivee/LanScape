import SwiftUI
import SwiftData
import UIKit

struct CompletionView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Input

    let durationSeconds: TimeInterval
    let capturedPhotos: [UIImage]
    
    /// Set `true` saat dibuka dari GalleryView
    var isReadOnly: Bool = false

    var onRestart: (() -> Void)? = nil
    var onSelectMusic: (() -> Void)? = nil
    var onMainMenu: (() -> Void)? = nil

    // MARK: - State

    @State private var showShareMenu = false
    @State private var showShareSheet = false
    @State private var showPostcard = false
    @State private var showGallery = false
    @State private var galleryIndex = 0
    @State private var didSaveGallery = false

    // MARK: - Photos

    private var fivePhotos: [UIImage] {
        Array(capturedPhotos.prefix(5))
    }

    private var postcardImage: UIImage? {
        makePhotoStrip(from: fivePhotos)
            ?? fivePhotos.first
    }

    private var sixShareItems: [Any] {
        var items: [Any] = []

        if let strip = postcardImage {
            items.append(strip)
        }

        items.append(contentsOf: fivePhotos)

        return items
    }

    // MARK: - Duration

    private var formattedDuration: String {
        let total = max(0, Int(durationSeconds))
        let minutes = total / 60
        let seconds = total % 60

        return "\(minutes) menit \(seconds) detik"
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in

            let width = geometry.size.width
            let height = geometry.size.height
            let isPad = UIDevice.current.userInterfaceIdiom == .pad || height >= 550

            let horizontalPadding: CGFloat = isPad ? 42 : 20
            let titleHeight: CGFloat = isPad ? 60 : 38
            let bottomButtonHeight: CGFloat = isPad ? 64 : 42
            let bottomAreaHeight: CGFloat = isPad ? 90 : 54

            let contentTop: CGFloat = isPad ? 104 : 56
            let contentBottom: CGFloat = height - bottomAreaHeight - (isPad ? 12 : 6)

            let maxPhotoH: CGFloat = isPad ? 640 : 230
            let photoAreaHeight: CGFloat = max(
                140.0,
                min(
                    maxPhotoH,
                    contentBottom - contentTop
                )
            )

            let stripWidth = min(
                isPad ? 250 : 150,
                width * 0.20
            )

            let gridGap: CGFloat = isPad ? 20 : 10

            let availableGridWidth = width
                - (horizontalPadding * 2)
                - stripWidth
                - gridGap

            let cellWidth = max(
                90,
                min(
                    isPad ? 380 : 260,
                    (availableGridWidth - gridGap) / 2
                )
            )

            let cellHeight = max(
                40,
                (photoAreaHeight - (gridGap * 2)) / 3
            )

            let bottomBtnWidth: CGFloat = isPad ? 280 : 170
            let shareButtonWidth: CGFloat = min(
                width - (horizontalPadding * 2),
                isReadOnly ? (isPad ? 880 : 460) : bottomBtnWidth
            )

            ZStack {

                // MARK: Background - Light Pastel Sky Blue
                LinearGradient(
                    colors: [
                        Color(red: 0.84, green: 0.92, blue: 1.00),
                        Color(red: 0.73, green: 0.86, blue: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // MARK: Outside-tap layer
                if showShareMenu {
                    Color.clear
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.18)) {
                                showShareMenu = false
                            }
                        }
                }

                // MARK: Main layout
                VStack(spacing: 0) {

                    // TOP NAVIGATION BAR & TITLE
                    ZStack {
                        if isReadOnly {
                            HStack {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: isPad ? 20 : 15, weight: .bold))
                                        .foregroundStyle(.black)
                                        .frame(width: isPad ? 48 : 34, height: isPad ? 48 : 34)
                                        .background(Circle().fill(.white.opacity(0.85)))
                                        .shadow(color: .black.opacity(0.12), radius: 4)
                                }
                                .buttonStyle(.plain)

                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding)
                        }

                        // TITLE
                        VStack(spacing: isPad ? 4 : 2) {
                            Text("Tersimpan di galeri!")
                                .font(.system(size: isPad ? 32 : 19, weight: .bold))
                                .foregroundStyle(.black)
                            
                            Text("\(fivePhotos.count) Foto Kompak • \(formattedDuration)")
                                .font(.system(size: isPad ? 14 : 11, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                    }
                    .frame(height: titleHeight + (isPad ? 12 : 6), alignment: .center)
                    .padding(.top, isPad ? 16 : 8)

                    Spacer(minLength: isPad ? 8 : 4)

                    // PHOTO AREA
                    HStack(alignment: .top, spacing: gridGap) {

                        // LEFT PHOTO STRIP - Utilizing the Dynamic Array Initializer
                        Button {
                            if !fivePhotos.isEmpty {
                                galleryIndex = 0
                                showGallery = true
                            }
                        } label: {
                            PhotoStripView(images: fivePhotos)
                        }
                        .buttonStyle(.plain)
                        .frame(width: stripWidth, height: photoAreaHeight)

                        // RIGHT: 5 PHOTOS + 1 KEEPSAKE STAMP CARD (NO EMPTY SLOTS)
                        VStack(spacing: gridGap) {

                            HStack(spacing: gridGap) {
                                completionPhoto(index: 0, width: cellWidth, height: cellHeight)
                                completionPhoto(index: 1, width: cellWidth, height: cellHeight)
                            }

                            HStack(spacing: gridGap) {
                                completionPhoto(index: 2, width: cellWidth, height: cellHeight)
                                completionPhoto(index: 3, width: cellWidth, height: cellHeight)
                            }

                            HStack(spacing: gridGap) {
                                completionPhoto(index: 4, width: cellWidth, height: cellHeight)


                                // 6th Slot: Clean White Postcard Card
                                ZStack {
                                    RoundedRectangle(cornerRadius: isPad ? 12 : 8)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.12), radius: isPad ? 6 : 3, y: isPad ? 3 : 2)
                                    
                                    VStack(spacing: isPad ? 4 : 2) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: isPad ? 22 : 14, weight: .bold))
                                            .foregroundColor(Color(red: 0.20, green: 0.39, blue: 0.70))
                                        
                                        Text("LanScape")
                                            .font(.system(size: isPad ? 15 : 10.5, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Text("Momen Berhasil Disimpan")
                                            .font(.system(size: isPad ? 11 : 8, weight: .medium))
                                            .foregroundColor(Color.black.opacity(0.6))
                                    }
                                    .padding(isPad ? 6 : 3)
                                }
                                .frame(
                                    width: cellWidth,
                                    height: cellHeight
                                )
                            }
                        }
                        .frame(
                            width: cellWidth * 2 + gridGap,
                            height: photoAreaHeight,
                            alignment: .top
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, horizontalPadding)

                    Spacer(minLength: 0)

                    // BOTTOM BUTTONS AREA
                    HStack(spacing: isPad ? 24 : 12) {

                        if !isReadOnly {
                            CompletionButton(
                                title: "Pose Ulang",
                                icon: "arrow.counterclockwise",
                                width: bottomBtnWidth,
                                height: bottomButtonHeight
                            ) {
                                showShareMenu = false
                                if let onRestart {
                                    onRestart()
                                } else {
                                    dismiss()
                                }
                            }

                            CompletionButton(
                                title: "Menu Utama",
                                icon: "house.fill",
                                width: bottomBtnWidth,
                                height: bottomButtonHeight
                            ) {
                                showShareMenu = false
                                if let onMainMenu {
                                    onMainMenu()
                                } else {
                                    dismiss()
                                }
                            }
                        }

                        // SHARE BUTTON + OVERLAY POPOVER
                        CompletionButton(
                            title: "Share",
                            icon: "square.and.arrow.up",
                            isPrimary: true,
                            width: shareButtonWidth,
                            height: bottomButtonHeight
                        ) {
                            withAnimation(.easeOut(duration: 0.18)) {
                                showShareMenu.toggle()
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if showShareMenu {
                                SharePopover(
                                    isPad: isPad,
                                    onPostcard: {
                                        showShareMenu = false
                                        DispatchQueue.main.async {
                                            showPostcard = true
                                        }
                                    },
                                    onPhotos: {
                                        showShareMenu = false
                                        guard !sixShareItems.isEmpty else { return }
                                        DispatchQueue.main.async {
                                            showShareSheet = true
                                        }
                                    }
                                )
                                .frame(width: isPad ? 370 : 270)
                                .offset(y: -(bottomButtonHeight + 10))
                                .transition(
                                    .opacity.combined(
                                        with: .scale(scale: 0.94, anchor: .bottom)
                                    )
                                )
                                .zIndex(1000)
                            }
                        }
                    }
                    .frame(height: bottomAreaHeight, alignment: .bottom)
                    .padding(.bottom, isPad ? 22 : 12)
                }
                .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
        }
        .ignoresSafeArea()
        .onAppear {
            saveGalleryIfNeeded()
        }

        // MARK: Gallery

        .fullScreenCover(isPresented: $showGallery) {
            CompletionGalleryView(
                images: fivePhotos,
                selectedIndex: $galleryIndex,
                isPresented: $showGallery
            )
        }

        // MARK: Share 6 photos

        .sheet(isPresented: $showShareSheet) {
            ShareSheetController(items: sixShareItems)
                .presentationDetents([.medium, .large])
        }

        // MARK: Postcard

        .fullScreenCover(isPresented: $showPostcard) {
            if let postcardImage {
                TulisPostcardView(images: fivePhotos)
            } else {
                Color.white.ignoresSafeArea()
            }
        }
    }

    // MARK: - Photo

    @ViewBuilder
    private func completionPhoto(
        index: Int,
        width: CGFloat,
        height: CGFloat
    ) -> some View {

        if fivePhotos.indices.contains(index) {
            Button {
                galleryIndex = index
                showGallery = true
            } label: {
                Image(uiImage: fivePhotos[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .background(Color.white)
                    .overlay {
                        Rectangle()
                            .stroke(
                                Color.white.opacity(0.95),
                                lineWidth: 2
                            )
                    }
                    .shadow(
                        color: .black.opacity(0.16),
                        radius: 5,
                        x: 0,
                        y: 3
                    )
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(width: width, height: height)
        }
    }

    // MARK: - Gallery Save

    private func saveGalleryIfNeeded() {
        guard !isReadOnly, !didSaveGallery else { return }
        guard !fivePhotos.isEmpty else { return }

        didSaveGallery = true

        GallerySession.save(
            images: fivePhotos,
            title: "Jarang Pulang",
            into: modelContext
        )
    }

    // MARK: - Photo Strip

    private func makePhotoStrip(from images: [UIImage]) -> UIImage? {
        guard !images.isEmpty else { return nil }

        let width: CGFloat = 700
        let imageWidth: CGFloat = 545
        let imageHeight: CGFloat = 215
        let leftPadding: CGFloat = 78
        let topPadding: CGFloat = 55
        let gap: CGFloat = 11
        let bottomPadding: CGFloat = 70

        let height = topPadding
            + CGFloat(images.count) * imageHeight
            + CGFloat(max(0, images.count - 1)) * gap
            + bottomPadding

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height)
        )

        return renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))

            for (index, image) in images.enumerated() {
                let y = topPadding + CGFloat(index) * (imageHeight + gap)
                let target = CGRect(x: leftPadding, y: y, width: imageWidth, height: imageHeight)

                let imageAspect = image.size.width / max(image.size.height, 1)
                let targetAspect = target.width / target.height

                var drawRect = target

                if imageAspect > targetAspect {
                    let h = target.height
                    let w = h * imageAspect
                    drawRect = CGRect(x: target.midX - w / 2, y: target.minY, width: w, height: h)
                } else {
                    let w = target.width
                    let h = w / imageAspect
                    drawRect = CGRect(x: target.minX, y: target.midY - h / 2, width: w, height: h)
                }

                context.cgContext.saveGState()
                context.cgContext.addRect(target)
                context.cgContext.clip()
                image.draw(in: drawRect)
                context.cgContext.restoreGState()
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "id_ID")
            formatter.dateFormat = "d/M/yyyy 'pada' HH:mm"

            let text = formatter.string(from: Date())
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 25),
                .foregroundColor: UIColor.black
            ]

            NSAttributedString(string: text, attributes: attributes)
                .draw(at: CGPoint(x: leftPadding, y: height - bottomPadding + 8))
        }
    }
}

// MARK: - Share Popover

private struct SharePopover: View {

    var isPad: Bool = false
    let onPostcard: () -> Void
    let onPhotos: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onPostcard) {
                HStack(spacing: isPad ? 14 : 10) {
                    Image(systemName: "eyeglasses")
                        .font(.system(size: isPad ? 24 : 17, weight: .regular))
                        .frame(width: isPad ? 34 : 26)

                    Text("Bagikan sebagai postcard")
                        .font(.system(size: isPad ? 19 : 13.5, weight: .regular))

                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, isPad ? 20 : 14)
                .frame(maxWidth: .infinity, minHeight: isPad ? 62 : 44)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, isPad ? 18 : 12)

            Button(action: onPhotos) {
                HStack(spacing: isPad ? 14 : 10) {
                    Image(systemName: "book")
                        .font(.system(size: isPad ? 24 : 17, weight: .regular))
                        .frame(width: isPad ? 34 : 26)

                    Text("Bagikan sebagai foto")
                        .font(.system(size: isPad ? 19 : 13.5, weight: .regular))

                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, isPad ? 20 : 14)
                .frame(maxWidth: .infinity, minHeight: isPad ? 62 : 44)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: isPad ? 24 : 16, style: .continuous)
                .fill(Color.white)
        )
        .shadow(
            color: .black.opacity(0.22),
            radius: isPad ? 14 : 8,
            x: 0,
            y: isPad ? 7 : 4
        )
    }
}

// MARK: - Completion Button

private struct CompletionButton: View {

    let title: String
    let icon: String
    var isPrimary = false

    let width: CGFloat
    let height: CGFloat

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: height * 0.43, weight: .bold))

                Text(title)
                    .font(.system(size: height * 0.34, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: width, height: height)
            .background {
                if isPrimary {
                    LinearGradient(
                        colors: [
                            Color(red: 0.51, green: 0.55, blue: 1.0),
                            Color(red: 0.10, green: 0.45, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color(red: 0.20, green: 0.39, blue: 0.70)
                }
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        Color.white.opacity(isPrimary ? 0.25 : 0.16),
                        lineWidth: 1.2
                    )
            )
            .shadow(
                color: isPrimary ? Color(red: 0.15, green: 0.39, blue: 0.92).opacity(0.4) : Color.black.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet

private struct ShareSheetController: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Gallery

private struct CompletionGalleryView: View {

    let images: [UIImage]

    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(images.indices, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .padding(30)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Spacer()

                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color.black.opacity(0.55)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 24)
                .padding(.top, 20)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}
