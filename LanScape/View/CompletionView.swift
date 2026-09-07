//
//  CompletionView.swift
//  stamppal
//
//  Completion screen:
//  - 5 customized photos
//  - photo strip on the left
//  - Share popover matching the reference
//  - postcard -> TulisPostcardView
//  - photo -> native share sheet with 6 images
//

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
            let isPad = UIDevice.current.userInterfaceIdiom == .pad || width >= 900

            // Everything is calculated from the available landscape size.
            // This prevents the title/buttons from being pushed outside the screen.
            let horizontalPadding: CGFloat = isPad ? 42 : 24
            let titleHeight: CGFloat = isPad ? 70 : 54
            let bottomButtonHeight: CGFloat = isPad ? 72 : 58
            let bottomAreaHeight: CGFloat = isPad ? 105 : 82

            let contentTop =
                max(
                    isPad ? 135 : 100,
                    titleHeight + 42
                )

            let contentBottom =
                height - bottomAreaHeight - 18

            let photoAreaHeight =
                max(
                    300,
                    min(
                        680,
                        contentBottom - contentTop
                    )
                )

            let stripWidth =
                min(
                    isPad ? 265 : 190,
                    width * 0.22
                )

            let gridGap: CGFloat = isPad ? 24 : 14

            let availableGridWidth =
                width
                - (horizontalPadding * 2)
                - stripWidth
                - gridGap

            let cellWidth =
                max(
                    130,
                    min(
                        isPad ? 390 : 300,
                        (availableGridWidth - gridGap) / 2
                    )
                )

            let cellHeight =
                max(
                    95,
                    (photoAreaHeight - (gridGap * 2)) / 3
                )

            ZStack {

                // MARK: Background - Premium Dark Studio Canvas
                LinearGradient(
                    colors: [
                        Color(hex: "0B0F19"),
                        Color(hex: "111827"),
                        Color(hex: "0F172A")
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

                    // TITLE & SESSION STATUS
                    VStack(spacing: isPad ? 8 : 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: isPad ? 14 : 11, weight: .bold))
                                .foregroundColor(Color(hex: "10B981"))
                            Text("SESI FOTO SELESAI")
                                .font(.system(size: isPad ? 13 : 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundColor(Color(hex: "60A5FA"))
                        }
                        .padding(.horizontal, isPad ? 14 : 10)
                        .padding(.vertical, isPad ? 5 : 3.5)
                        .background(Color(hex: "1E293B").opacity(0.9))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        
                        Text("Semua Momen Tersimpan Rapi!")
                            .font(.system(size: isPad ? 36 : 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.4)
                        
                        Text("\(fivePhotos.count) Foto Kompak • \(formattedDuration) • Tersimpan di Galeri")
                            .font(.system(size: isPad ? 14 : 11, weight: .medium))
                            .foregroundColor(Color(hex: "94A3B8"))
                    }
                    .frame(height: titleHeight + (isPad ? 24 : 16), alignment: .center)
                    .padding(.top, isPad ? 22 : 12)

                    Spacer(minLength: 8)

                    // PHOTO AREA
                    HStack(
                        alignment: .top,
                        spacing: gridGap
                    ) {

                        // LEFT PHOTO STRIP
                        Button {
                            if !fivePhotos.isEmpty {
                                galleryIndex = 0
                                showGallery = true
                            }
                        } label: {
                            PhotoStripView(
                                image: postcardImage
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(
                            width: stripWidth,
                            height: photoAreaHeight
                        )

                        // RIGHT: 5 PHOTOS + 1 KEEPSAKE STAMP CARD (NO EMPTY SLOTS)
                        VStack(spacing: gridGap) {

                            HStack(spacing: gridGap) {
                                completionPhoto(
                                    index: 0,
                                    width: cellWidth,
                                    height: cellHeight
                                )

                                completionPhoto(
                                    index: 1,
                                    width: cellWidth,
                                    height: cellHeight
                                )
                            }

                            HStack(spacing: gridGap) {
                                completionPhoto(
                                    index: 2,
                                    width: cellWidth,
                                    height: cellHeight
                                )

                                completionPhoto(
                                    index: 3,
                                    width: cellWidth,
                                    height: cellHeight
                                )
                            }

                            HStack(spacing: gridGap) {
                                completionPhoto(
                                    index: 4,
                                    width: cellWidth,
                                    height: cellHeight
                                )

                                // 6th Slot: Designed Photobooth Keepsake Card
                                ZStack {
                                    RoundedRectangle(cornerRadius: isPad ? 12 : 8)
                                        .fill(Color(hex: "1E293B").opacity(0.85))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isPad ? 12 : 8)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color(hex: "38BDF8").opacity(0.5), Color(hex: "818CF8").opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                    
                                    VStack(spacing: isPad ? 6 : 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: isPad ? 26 : 18, weight: .bold))
                                            .foregroundColor(Color(hex: "38BDF8"))
                                        
                                        Text("LanScape Studio")
                                            .font(.system(size: isPad ? 16 : 12, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("5 Momen Kompak Berhasil")
                                            .font(.system(size: isPad ? 12 : 9.5, weight: .medium))
                                            .foregroundColor(Color(hex: "94A3B8"))
                                        
                                        Text("Ketuk foto untuk layar penuh")
                                            .font(.system(size: isPad ? 10 : 8, weight: .regular))
                                            .foregroundColor(Color(hex: "64748B"))
                                            .padding(.top, 2)
                                    }
                                    .padding(8)
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
                    .frame(
                        maxWidth: .infinity,
                        alignment: .top
                    )
                    .padding(.horizontal, horizontalPadding)

                    Spacer(minLength: 0)

                    // BOTTOM BUTTONS
                    HStack(spacing: isPad ? 28 : 18) {

                        CompletionButton(
                            title: "Pose Ulang",
                            icon: "arrow.counterclockwise",
                            width: isPad ? 300 : 250,
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
                            width: isPad ? 300 : 250,
                            height: bottomButtonHeight
                        ) {
                            showShareMenu = false

                            if let onMainMenu {
                                onMainMenu()
                            } else {
                                dismiss()
                            }
                        }

                        // SHARE BUTTON + POPOVER
                        ZStack(alignment: .bottom) {

                            CompletionButton(
                                title: "Share",
                                icon: "square.and.arrow.up",
                                isPrimary: true,
                                width: isPad ? 300 : 250,
                                height: bottomButtonHeight
                            ) {
                                withAnimation(
                                    .easeOut(duration: 0.18)
                                ) {
                                    showShareMenu.toggle()
                                }
                            }

                            if showShareMenu {

                                SharePopover(
                                    onPostcard: {
                                        // Close menu first.
                                        showShareMenu = false

                                        // Then present postcard.
                                        DispatchQueue.main.async {
                                            showPostcard = true
                                        }
                                    },
                                    onPhotos: {
                                        // Close menu first.
                                        showShareMenu = false

                                        guard !sixShareItems.isEmpty else {
                                            return
                                        }

                                        // Present after the popover has disappeared.
                                        DispatchQueue.main.async {
                                            showShareSheet = true
                                        }
                                    }
                                )
                                .offset(
                                    y: -(bottomButtonHeight + 14)
                                )
                                .transition(
                                    .opacity
                                        .combined(
                                            with: .scale(
                                                scale: 0.94,
                                                anchor: .bottom
                                            )
                                        )
                                )
                                .zIndex(1000)
                            }
                        }
                    }
                    .frame(
                        height: bottomAreaHeight,
                        alignment: .bottom
                    )
                    .padding(.bottom, isPad ? 26 : 18)
                }
                .frame(
                    width: width,
                    height: height
                )

            }
            .frame(
                width: width,
                height: height
            )
        }
        .ignoresSafeArea()
        .onAppear {
            saveGalleryIfNeeded()
        }

        // MARK: Gallery

        .fullScreenCover(
            isPresented: $showGallery
        ) {
            CompletionGalleryView(
                images: fivePhotos,
                selectedIndex: $galleryIndex,
                isPresented: $showGallery
            )
        }

        // MARK: Share 6 photos

        .sheet(
            isPresented: $showShareSheet
        ) {
            ShareSheetController(
                items: sixShareItems
            )
            .presentationDetents([.medium, .large])
        }

        // MARK: Postcard

        .fullScreenCover(
            isPresented: $showPostcard
        ) {
            if let postcardImage {

                TulisPostcardView(images: fivePhotos)

            } else {

                Color.white
                    .ignoresSafeArea()
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
                    .frame(
                        width: width,
                        height: height
                    )
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
                .frame(
                    width: width,
                    height: height
                )
        }
    }

    // MARK: - Gallery Save

    private func saveGalleryIfNeeded() {

        guard !didSaveGallery else {
            return
        }

        guard !fivePhotos.isEmpty else {
            return
        }

        didSaveGallery = true

        GallerySession.save(
            images: fivePhotos,
            title: "Jarang Pulang",
            into: modelContext
        )
    }

    // MARK: - Photo Strip

    private func makePhotoStrip(
        from images: [UIImage]
    ) -> UIImage? {

        guard !images.isEmpty else {
            return nil
        }

        let width: CGFloat = 700
        let imageWidth: CGFloat = 545
        let imageHeight: CGFloat = 215
        let leftPadding: CGFloat = 78
        let topPadding: CGFloat = 55
        let gap: CGFloat = 11
        let bottomPadding: CGFloat = 70

        let height =
            topPadding
            + CGFloat(images.count) * imageHeight
            + CGFloat(max(0, images.count - 1)) * gap
            + bottomPadding

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: width,
                height: height
            )
        )

        return renderer.image { context in

            UIColor.white.setFill()

            context.cgContext.fill(
                CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
            )

            for (index, image) in images.enumerated() {

                let y =
                    topPadding
                    + CGFloat(index) * (imageHeight + gap)

                let target = CGRect(
                    x: leftPadding,
                    y: y,
                    width: imageWidth,
                    height: imageHeight
                )

                let imageAspect =
                    image.size.width /
                    max(image.size.height, 1)

                let targetAspect =
                    target.width / target.height

                var drawRect = target

                if imageAspect > targetAspect {

                    let h = target.height
                    let w = h * imageAspect

                    drawRect = CGRect(
                        x: target.midX - w / 2,
                        y: target.minY,
                        width: w,
                        height: h
                    )

                } else {

                    let w = target.width
                    let h = w / imageAspect

                    drawRect = CGRect(
                        x: target.minX,
                        y: target.midY - h / 2,
                        width: w,
                        height: h
                    )
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

            let text = formatter.string(
                from: Date()
            )

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(
                    ofSize: 25
                ),
                .foregroundColor: UIColor.black
            ]

            NSAttributedString(
                string: text,
                attributes: attributes
            )
            .draw(
                at: CGPoint(
                    x: leftPadding,
                    y: height - bottomPadding + 8
                )
            )
        }
    }
}

// MARK: - Photo Strip View

private struct PhotoStripView: View {

    let image: UIImage?

    var body: some View {

        ZStack {

            Color.white

            if let image {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)

            } else {

                VStack(spacing: 10) {

                    Image(systemName: "photo")
                        .font(.system(size: 36))

                    Text("Foto")
                        .font(.system(size: 18))
                }
                .foregroundStyle(.secondary)
            }
        }
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(
                    Color.white,
                    lineWidth: 2
                )
        )
        .shadow(
            color: .black.opacity(0.14),
            radius: 7,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Share Popover

private struct SharePopover: View {

    let onPostcard: () -> Void
    let onPhotos: () -> Void

    var body: some View {

        VStack(spacing: 0) {

            Button(action: onPostcard) {

                HStack(spacing: 14) {

                    Image(systemName: "eyeglasses")
                        .font(
                            .system(
                                size: 25,
                                weight: .regular
                            )
                        )
                        .frame(
                            width: 34
                        )

                    Text("Bagikan sebagai postcard")
                        .font(
                            .system(
                                size: 20,
                                weight: .regular
                            )
                        )

                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .frame(
                    width: 370,
                    height: 66
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, 18)

            Button(action: onPhotos) {

                HStack(spacing: 14) {

                    Image(systemName: "book")
                        .font(
                            .system(
                                size: 25,
                                weight: .regular
                            )
                        )
                        .frame(
                            width: 34
                        )

                    Text("Bagikan sebagai foto")
                        .font(
                            .system(
                                size: 20,
                                weight: .regular
                            )
                        )

                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .frame(
                    width: 370,
                    height: 66
                )
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .fill(Color.white)
        )
        .shadow(
            color: .black.opacity(0.22),
            radius: 14,
            x: 0,
            y: 7
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
                    .font(
                        .system(
                            size: height * 0.43,
                            weight: .bold
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: height * 0.34,
                            weight: .bold
                        )
                    )
            }
            .foregroundStyle(.white)
            .frame(
                width: width,
                height: height
            )
            .background {
                if isPrimary {
                    LinearGradient(
                        colors: [Color(hex: "2563EB"), Color(hex: "1D4ED8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color(hex: "1E293B").opacity(0.92)
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
                color: isPrimary ? Color(hex: "2563EB").opacity(0.4) : Color.black.opacity(0.2),
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

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

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

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Gallery

private struct CompletionGalleryView: View {

    let images: [UIImage]

    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            TabView(
                selection: $selectedIndex
            ) {

                ForEach(
                    images.indices,
                    id: \.self
                ) { index in

                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                        .padding(30)
                }
            }
            .tabViewStyle(
                .page(indexDisplayMode: .automatic)
            )

            VStack {

                HStack {

                    Spacer()

                    Button {

                        isPresented = false

                    } label: {

                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(
                                width: 48,
                                height: 48
                            )
                            .background(
                                Circle()
                                    .fill(
                                        Color.black.opacity(0.55)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(
                    .trailing,
                    24
                )
                .padding(
                    .top,
                    20
                )

                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Completion Landscape") {
    CompletionView(
        durationSeconds: 180,
        capturedPhotos: []
    )
    .modelContainer(
        for: [
            GallerySession.self
        ],
        inMemory: true
    )
}
