//  EditablePhoto.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import SwiftUI
import PencilKit
import UIKit
import Combine

// MARK: - Editable Photo

final class EditablePhoto: ObservableObject, Identifiable {

    let id = UUID()

    @Published var image: UIImage

    // PencilKit drawing
    @Published var drawing: PKDrawing = PKDrawing()

    // Stickers
    @Published var stickers: [StickerItem] = []

    // Imported images
    @Published var imageLayers: [ImageLayerItem] = []

    init(image: UIImage) {
        self.image = image
    }
}

// MARK: - Sticker

struct StickerItem: Identifiable, Equatable {

    let id = UUID()

    var emoji: String

    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)

    var scale: CGFloat = 1.0

    var rotation: Angle = .zero
}

// MARK: - Image Layer

struct ImageLayerItem: Identifiable, Equatable {

    let id = UUID()

    var image: UIImage

    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)

    var scale: CGFloat = 1.0

    var rotation: Angle = .zero

    static func == (lhs: ImageLayerItem, rhs: ImageLayerItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Main View

struct CustomizePhotoView: View {

    // MARK: Input

    let photos: [UIImage]

    var onDone: (([UIImage]) -> Void)? = nil

    // MARK: State

    @State private var pages: [EditablePhoto]

    @State private var currentIndex: Int = 0

    @State private var selectedSticker: UUID?

    @State private var selectedImageLayer: UUID?

    @State private var showingToolPicker = false

    @Environment(\.dismiss)
    private var dismiss

    // MARK: Init

    init(
        photos: [UIImage],
        onDone: (([UIImage]) -> Void)? = nil
    ) {
        self.photos = photos
        self.onDone = onDone

        _pages = State(
            initialValue: photos.map {
                EditablePhoto(image: $0)
            }
        )
    }

    // MARK: Body

    var body: some View {

        GeometryReader { geometry in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad || geometry.size.height >= 550
            let screenW = geometry.size.width
            let screenH = geometry.size.height

            ZStack {

                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.84, green: 0.91, blue: 1.0),
                        Color(red: 0.72, green: 0.85, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                HStack(spacing: 0) {

                    // MARK: Sticker / Image Panel

                    editorSidePanel(isPad: isPad)
                        .frame(
                            width: isPad
                                ? min(screenW * 0.22, 280)
                                : min(screenW * 0.25, 195)
                        )

                    Spacer(minLength: isPad ? 24 : 10)

                    // MARK: Photo Area

                    photoArea(isPad: isPad)
                        .frame(
                            maxWidth: isPad ? screenW * 0.68 : screenW * 0.63,
                            maxHeight: isPad ? screenH * 0.76 : screenH * 0.74
                        )

                    Spacer(minLength: isPad ? 24 : 10)
                }

                // MARK: Top Title

                VStack {

                    Text("Yuk, hias foto kalian!")
                        .font(
                            .system(
                                size: isPad ? 34 : 18,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)

                    Spacer()
                }
                .padding(.top, isPad ? 24 : 8)

                // MARK: Done Button

                VStack {

                    HStack {

                        Spacer()

                        Button {

                            finishEditing()

                        } label: {

                            Image(systemName: "checkmark")
                                .font(
                                    .system(
                                        size: isPad ? 26 : 17,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                                .frame(
                                    width: isPad ? 64 : 40,
                                    height: isPad ? 64 : 40
                                )
                                .background(
                                    Circle()
                                        .fill(
                                            Color.blue
                                        )
                                )
                                .shadow(
                                    color: .black.opacity(0.18),
                                    radius: 6,
                                    y: 3
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, isPad ? 36 : 16)
                        .padding(.top, isPad ? 20 : 8)
                    }

                    Spacer()
                }

                // MARK: PencilKit Button

                VStack {

                    Spacer()

                    HStack {

                        Button {

                            showingToolPicker.toggle()

                            NotificationCenter.default.post(
                                name: .showPencilKitTools,
                                object: showingToolPicker
                            )

                        } label: {

                            Image(
                                systemName:
                                    "pencil.tip.crop.circle"
                            )
                            .font(
                                .system(
                                    size: isPad ? 30 : 20,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.black)
                            .frame(
                                width: isPad ? 70 : 44,
                                height: isPad ? 70 : 44
                            )
                            .background(
                                Circle()
                                    .fill(
                                        Color.white.opacity(0.85)
                                    )
                            )
                            .shadow(
                                color: .black.opacity(0.15),
                                radius: 6,
                                y: 3
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.leading, isPad ? 40 : 16)
                    .padding(.bottom, isPad ? 20 : 10)
                }
            }
        }
    }

    // MARK: - Side Panel

    private func editorSidePanel(isPad: Bool) -> some View {

        VStack(
            alignment: .leading,
            spacing: isPad ? 14 : 6
        ) {

            Text("Stiker")
                .font(
                    .system(
                        size: isPad ? 26 : 15,
                        weight: .bold
                    )
                )

            Text("Geser stiker ke foto")
                .font(
                    .system(size: isPad ? 16 : 10)
                )
                .foregroundStyle(.secondary)

            stickerGrid(isPad: isPad)

            Divider()
                .padding(.vertical, isPad ? 5 : 2)

            Spacer()
        }
        .padding(isPad ? 20 : 10)
        .background(
            RoundedRectangle(
                cornerRadius: isPad ? 24 : 14
            )
            .fill(
                Color.white.opacity(0.25)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: isPad ? 24 : 14
                )
                .stroke(
                    Color.white.opacity(0.7),
                    lineWidth: 1
                )
            )
        )
        .padding(.leading, isPad ? 40 : 16)
    }

    // MARK: - Stickers

    private func stickerGrid(isPad: Bool) -> some View {

        let stickers = [
            "🌸",
            "👑",
            "❤️",
            "👓",
            "✨",
            "🤡",
            "🐥",
            "🥶",
            "🎓",
            "🦋",
            "⭐️",
            "⚡️",
            "🥽",
            "🧢",
            "🎩"
        ]

        let columns = isPad
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(
            columns: columns,
            spacing: isPad ? 10 : 6
        ) {

            ForEach(
                Array(stickers.enumerated()),
                id: \.offset
            ) { index, sticker in

                Button {

                    addSticker(sticker)

                } label: {

                    Text(sticker)
                        .font(.system(size: isPad ? 32 : 20))
                        .frame(
                            maxWidth: .infinity,
                            minHeight: isPad ? 54 : 34
                        )
                        .background(
                            RoundedRectangle(
                                cornerRadius: isPad ? 8 : 6
                            )
                            .fill(
                                Color.blue.opacity(0.12)
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Photo Area

    private func photoArea(isPad: Bool) -> some View {

        VStack(spacing: isPad ? 16 : 8) {

            HStack(spacing: isPad ? 18 : 8) {

                // Previous - leading side of the photo
                navigationButton(
                    systemName: "chevron.left",
                    isPad: isPad
                ) {
                    previousPhoto()
                }

                // Actual editor
                if !pages.isEmpty {
                    PhotoCanvasEditor(
                        page: pages[currentIndex],
                        showTools: showingToolPicker,
                        selectedSticker: $selectedSticker,
                        selectedImageLayer: $selectedImageLayer
                    )
                    .id(pages[currentIndex].id)
                    .aspectRatio(
                        pages[currentIndex].image.size,
                        contentMode: .fit
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: isPad ? 22 : 14
                        )
                    )
                    .shadow(
                        color: .black.opacity(0.22),
                        radius: isPad ? 12 : 6,
                        y: isPad ? 8 : 4
                    )
                    .frame(maxWidth: .infinity)
                }

                // Next - trailing side of the photo
                navigationButton(
                    systemName: "chevron.right",
                    isPad: isPad
                ) {
                    nextPhoto()
                }
            }
            .frame(maxWidth: .infinity)

            // MARK: Dots

            HStack(spacing: isPad ? 12 : 8) {

                ForEach(
                    pages.indices,
                    id: \.self
                ) { index in

                    Circle()
                        .fill(
                            index == currentIndex
                            ? Color.black
                            : Color.gray.opacity(0.55)
                        )
                        .frame(
                            width: isPad
                                ? (index == currentIndex ? 12 : 10)
                                : (index == currentIndex ? 8 : 6),
                            height: isPad
                                ? (index == currentIndex ? 12 : 10)
                                : (index == currentIndex ? 8 : 6)
                        )
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: currentIndex
                        )
                }
            }
        }
    }

    // MARK: Navigation Button

    private func navigationButton(
        systemName: String,
        isPad: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Image(systemName: systemName)
                .font(
                    .system(
                        size: isPad ? 24 : 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.black)
                .frame(
                    width: isPad ? 54 : 36,
                    height: isPad ? 54 : 36
                )
                .background(
                    Circle()
                        .fill(
                            Color.white.opacity(0.85)
                        )
                )
                .shadow(
                    color: .black.opacity(0.12),
                    radius: isPad ? 8 : 4,
                    y: isPad ? 4 : 2
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Add Sticker

    private func addSticker(
        _ emoji: String
    ) {

        let sticker = StickerItem(
            emoji: emoji,
            position: CGPoint(
                x: 0.5,
                y: 0.5
            )
        )

        pages[currentIndex].stickers.append(sticker)

        selectedSticker = sticker.id
        selectedImageLayer = nil
    }

    // MARK: Previous

    private func previousPhoto() {

        guard !pages.isEmpty else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {

            currentIndex =
                currentIndex == 0
                ? pages.count - 1
                : currentIndex - 1
        }

        selectedSticker = nil
        selectedImageLayer = nil
    }

    // MARK: Next

    private func nextPhoto() {

        guard !pages.isEmpty else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {

            currentIndex =
                (currentIndex + 1) % pages.count
        }

        selectedSticker = nil
        selectedImageLayer = nil
    }

    // MARK: Finish

    private func finishEditing() {

        let renderedImages = pages.map {
            renderPhoto($0)
        }

        onDone?(renderedImages)

        dismiss()
    }

    // MARK: Render Final Image

    private func renderPhoto(
        _ page: EditablePhoto
    ) -> UIImage {

        let size = page.image.size

        let renderer = UIGraphicsImageRenderer(
            size: size
        )

        return renderer.image { context in

            let rect = CGRect(
                origin: .zero,
                size: size
            )

            // Background image

            page.image.draw(
                in: rect
            )

            // Imported images

            for layer in page.imageLayers {

                let image = layer.image

                let baseWidth =
                    size.width * 0.25

                let width =
                    baseWidth * layer.scale

                let height =
                    width *
                    image.size.height /
                    image.size.width

                let center = CGPoint(
                    x: size.width * layer.position.x,
                    y: size.height * layer.position.y
                )

                let imageRect = CGRect(
                    x: center.x - width / 2,
                    y: center.y - height / 2,
                    width: width,
                    height: height
                )

                context.cgContext.saveGState()

                context.cgContext.translateBy(
                    x: center.x,
                    y: center.y
                )

                context.cgContext.rotate(
                    by: CGFloat(
                        layer.rotation.radians
                    )
                )

                image.draw(
                    in: CGRect(
                        x: -width / 2,
                        y: -height / 2,
                        width: width,
                        height: height
                    )
                )

                context.cgContext.restoreGState()
            }

            // Stickers

            for sticker in page.stickers {

                let center = CGPoint(
                    x: size.width * sticker.position.x,
                    y: size.height * sticker.position.y
                )

                let fontSize =
                    size.width * 0.08 *
                    sticker.scale

                let attributes: [
                    NSAttributedString.Key: Any
                ] = [
                    .font: UIFont.systemFont(
                        ofSize: fontSize
                    )
                ]

                let string = NSAttributedString(
                    string: sticker.emoji,
                    attributes: attributes
                )

                let textSize = string.size()

                context.cgContext.saveGState()

                context.cgContext.translateBy(
                    x: center.x,
                    y: center.y
                )

                context.cgContext.rotate(
                    by: CGFloat(
                        sticker.rotation.radians
                    )
                )

                string.draw(
                    at: CGPoint(
                        x: -textSize.width / 2,
                        y: -textSize.height / 2
                    )
                )

                context.cgContext.restoreGState()
            }

            // PencilKit drawing

            let drawingImage =
                page.drawing.image(
                    from: CGRect(
                        origin: .zero,
                        size: page.drawing.bounds.size
                    ),
                    scale: UIScreen.main.scale
                )

            if !page.drawing.bounds.isEmpty {

                drawingImage.draw(
                    in: rect
                )
            }
        }
    }
}

// MARK: - Photo Canvas Editor

struct PhotoCanvasEditor: View {

    @ObservedObject var page: EditablePhoto

    let showTools: Bool

    @Binding var selectedSticker: UUID?

    @Binding var selectedImageLayer: UUID?

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                // MARK: Photo

                Image(uiImage: page.image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )

                // MARK: PencilKit
                //
                // Keep PencilKit underneath the editable layers.
                // This lets stickers/images receive drag gestures.
                PhotoEditorCanvasView(
                    drawing: $page.drawing,
                    showToolPicker: showTools
                )
                .allowsHitTesting(showTools)

                // MARK: Imported Images

                ForEach(
                    page.imageLayers
                ) { layer in

                    EditableImageLayer(
                        layer: binding(
                            for: layer.id,
                            in: $page.imageLayers
                        ),
                        isSelected:
                            selectedImageLayer == layer.id
                    )
                    .onTapGesture {

                        selectedImageLayer = layer.id
                        selectedSticker = nil
                    }
                }

                // MARK: Stickers

                ForEach(
                    page.stickers
                ) { sticker in

                    EditableSticker(
                        sticker: binding(
                            for: sticker.id,
                            in: $page.stickers
                        ),
                        isSelected:
                            selectedSticker == sticker.id,
                        onDelete: {
                            page.stickers.removeAll { $0.id == sticker.id }
                            selectedSticker = nil
                        }
                    )
                    .onTapGesture {

                        selectedSticker = sticker.id
                        selectedImageLayer = nil
                    }
                }
            }
        }
        .background(.white)
    }

    // MARK: Sticker Binding

    private func binding(
        for id: UUID,
        in array: Binding<[StickerItem]>
    ) -> Binding<StickerItem> {

        Binding(
            get: {

                array.wrappedValue.first {
                    $0.id == id
                } ?? StickerItem(
                    emoji: "❤️"
                )
            },

            set: { newValue in

                if let index =
                    array.wrappedValue.firstIndex(
                        where: {
                            $0.id == id
                        }
                    ) {

                    array.wrappedValue[index] =
                        newValue
                }
            }
        )
    }

    // MARK: Image Binding

    private func binding(
        for id: UUID,
        in array: Binding<[ImageLayerItem]>
    ) -> Binding<ImageLayerItem> {

        Binding(
            get: {

                array.wrappedValue.first {
                    $0.id == id
                } ?? ImageLayerItem(
                    image: UIImage()
                )
            },

            set: { newValue in

                if let index =
                    array.wrappedValue.firstIndex(
                        where: {
                            $0.id == id
                        }
                    ) {

                    array.wrappedValue[index] =
                        newValue
                }
            }
        )
    }
}

// MARK: - PencilKit Canvas

struct PhotoEditorCanvasView: UIViewRepresentable {

    @Binding var drawing: PKDrawing

    let showToolPicker: Bool

    func makeCoordinator()
    -> Coordinator {

        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> PKCanvasView {

        let canvas = PKCanvasView()

        canvas.backgroundColor =
            .clear

        canvas.isOpaque = false

        canvas.drawing =
            drawing

        canvas.drawingPolicy =
            .anyInput

        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false

        canvas.delegate =
            context.coordinator

        // Important:
        // Let PencilKit handle the full tool picker.

        let toolPicker =
            PKToolPicker()

        context.coordinator.toolPicker =
            toolPicker

        toolPicker.addObserver(canvas)

        toolPicker.setVisible(
            showToolPicker,
            forFirstResponder: canvas
        )

        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {

        if canvas.drawing != drawing {

            canvas.drawing =
                drawing
        }

        guard let toolPicker =
            context.coordinator.toolPicker
        else {
            return
        }

        toolPicker.setVisible(
            showToolPicker,
            forFirstResponder: canvas
        )

        if showToolPicker {

            if !canvas.isFirstResponder {

                canvas.becomeFirstResponder()
            }
        }
    }

    // MARK: Coordinator

    final class Coordinator:
        NSObject,
        PKCanvasViewDelegate {

        var parent: PhotoEditorCanvasView

        var toolPicker: PKToolPicker?

        init(
            _ parent: PhotoEditorCanvasView
        ) {

            self.parent = parent
        }

        func canvasViewDrawingDidChange(
            _ canvasView: PKCanvasView
        ) {

            parent.drawing =
                canvasView.drawing
        }
    }
}

// MARK: - Editable Sticker

struct EditableSticker: View {

    @Binding var sticker: StickerItem

    let isSelected: Bool
    var onDelete: (() -> Void)? = nil

    @State private var dragStart:
        CGPoint?

    @State private var scaleStart:
        CGFloat?

    @State private var rotationStart:
        Angle?

    var body: some View {

        GeometryReader { geometry in

            Text(sticker.emoji)
                .font(
                    .system(
                        size:
                            min(
                                geometry.size.width,
                                geometry.size.height
                            ) * 0.08
                    )
                )
                .frame(width: 80, height: 80)
                .contentShape(Rectangle())
                .scaleEffect(
                    sticker.scale
                )
                .rotationEffect(
                    sticker.rotation
                )
                .position(
                    x:
                        geometry.size.width *
                        sticker.position.x,

                    y:
                        geometry.size.height *
                        sticker.position.y
                )
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .position(
                                x: geometry.size.width * sticker.position.x,
                                y: geometry.size.height * sticker.position.y
                            )

                        Button {
                            onDelete?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.red))
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                        .position(
                            x: geometry.size.width * sticker.position.x + 34,
                            y: geometry.size.height * sticker.position.y - 34
                        )
                    }
                }
                .gesture(

                    DragGesture()
                        .onChanged { value in

                            if dragStart == nil {

                                dragStart =
                                    sticker.position
                            }

                            guard
                                let start =
                                    dragStart
                            else {
                                return
                            }

                            let dx =
                                value.translation.width /
                                geometry.size.width

                            let dy =
                                value.translation.height /
                                geometry.size.height

                            sticker.position =
                                CGPoint(
                                    x:
                                        min(
                                            max(
                                                start.x + dx,
                                                0.05
                                            ),
                                            0.95
                                        ),

                                    y:
                                        min(
                                            max(
                                                start.y + dy,
                                                0.05
                                            ),
                                            0.95
                                        )
                                )
                        }
                        .onEnded { _ in

                            dragStart = nil
                        }
                )
                .simultaneousGesture(

                    MagnificationGesture()
                        .onChanged { value in

                            if scaleStart == nil {

                                scaleStart =
                                    sticker.scale
                            }

                            sticker.scale =
                                min(
                                    max(
                                        (scaleStart ?? 1)
                                        * value,
                                        0.3
                                    ),
                                    4.0
                                )
                        }
                        .onEnded { _ in

                            scaleStart = nil
                        }
                )
                .simultaneousGesture(

                    RotationGesture()
                        .onChanged { value in

                            if rotationStart == nil {

                                rotationStart =
                                    sticker.rotation
                            }

                            sticker.rotation =
                                (rotationStart ?? .zero)
                                + value
                        }
                        .onEnded { _ in

                            rotationStart = nil
                        }
                )
        }
    }
}

// MARK: - Editable Image Layer

struct EditableImageLayer: View {

    @Binding var layer: ImageLayerItem

    let isSelected: Bool

    @State private var dragStart:
        CGPoint?

    @State private var scaleStart:
        CGFloat?

    @State private var rotationStart:
        Angle?

    var body: some View {

        GeometryReader { geometry in

            let width =
                geometry.size.width *
                0.28 *
                layer.scale

            let height =
                width *
                layer.image.size.height /
                max(
                    layer.image.size.width,
                    1
                )

            Image(uiImage: layer.image)
                .resizable()
                .scaledToFit()
                .frame(
                    width: width,
                    height: height
                )
                .rotationEffect(
                    layer.rotation
                )
                .position(
                    x:
                        geometry.size.width *
                        layer.position.x,

                    y:
                        geometry.size.height *
                        layer.position.y
                )
                .overlay {

                    if isSelected {

                        RoundedRectangle(
                            cornerRadius: 8
                        )
                        .stroke(
                            Color.blue,
                            lineWidth: 3
                        )
                        .frame(
                            width: width + 10,
                            height: height + 10
                        )
                        .rotationEffect(
                            layer.rotation
                        )
                        .position(
                            x:
                                geometry.size.width *
                                layer.position.x,

                            y:
                                geometry.size.height *
                                layer.position.y
                        )
                    }
                }
                .gesture(

                    DragGesture()
                        .onChanged { value in

                            if dragStart == nil {

                                dragStart =
                                    layer.position
                            }

                            guard
                                let start =
                                    dragStart
                            else {
                                return
                            }

                            let dx =
                                value.translation.width /
                                geometry.size.width

                            let dy =
                                value.translation.height /
                                geometry.size.height

                            layer.position =
                                CGPoint(
                                    x:
                                        min(
                                            max(
                                                start.x + dx,
                                                0.05
                                            ),
                                            0.95
                                        ),

                                    y:
                                        min(
                                            max(
                                                start.y + dy,
                                                0.05
                                            ),
                                            0.95
                                        )
                                )
                        }
                        .onEnded { _ in

                            dragStart = nil
                        }
                )
                .simultaneousGesture(

                    MagnificationGesture()
                        .onChanged { value in

                            if scaleStart == nil {

                                scaleStart =
                                    layer.scale
                            }

                            layer.scale =
                                min(
                                    max(
                                        (scaleStart ?? 1)
                                        * value,
                                        0.2
                                    ),
                                    4.0
                                )
                        }
                        .onEnded { _ in

                            scaleStart = nil
                        }
                )
                .simultaneousGesture(

                    RotationGesture()
                        .onChanged { value in

                            if rotationStart == nil {

                                rotationStart =
                                    layer.rotation
                            }

                            layer.rotation =
                                (rotationStart ?? .zero)
                                + value
                        }
                        .onEnded { _ in

                            rotationStart = nil
                        }
                )
        }
    }
}

// MARK: - Notification

extension Notification.Name {

    static let showPencilKitTools =
        Notification.Name(
            "showPencilKitTools"
        )
}
