//
//  TulisPostcardView.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import SwiftUI
import UIKit
import PencilKit
import AVFoundation

struct TulisPostcardView: View {

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - UI

    @State private var showHelp = false

    // MARK: - PencilKit

    @State private var postcardDrawing = PKDrawing()
    @State private var canvasIsEmpty = true
    @State private var canvasSize: CGSize = .zero
    @State private var selectedTool: PostcardDrawingTool = .pencil

    // MARK: - Stamp

    @State private var generatedStamp: UIImage?
    @State private var isGeneratingStamp = false

    // MARK: - Media Sending

    @State private var isSending = false
    @State private var sendingStatus = ""
    @State private var postcardID = UUID()
    @State private var localVideoURL: URL?
    @State private var showShareSheet = false


    let collageImages: [UIImage]

    // MARK: - Error

    @State private var showError = false
    @State private var errorMessage = ""

    init(images: [UIImage]) {
        self.collageImages = Array(images.prefix(5))
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.72, green: 0.84, blue: 0.98),
                        Color(red: 0.88, green: 0.94, blue: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: Header

                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 27, weight: .medium))
                                .foregroundStyle(.black)
                                .frame(width: 68, height: 68)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.42))
                                )
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Tulis Postcard")
                                .font(
                                    .system(
                                        size: min(42, geometry.size.width * 0.034),
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.black)

                            Text("Tulis pesan bermakna untuk orang tersayang")
                                .font(
                                    .system(
                                        size: min(24, geometry.size.width * 0.019),
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        Button {
                            showHelp = true
                        } label: {
                            Image(systemName: "questionmark")
                                .font(.system(size: 25, weight: .medium))
                                .foregroundStyle(.black)
                                .frame(width: 68, height: 68)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.42))
                                )
                        }
                    }
                    .padding(.horizontal, 42)
                    .padding(.top, 32)

                    Spacer()
                        .frame(height: 42)

                    // MARK: Main Content

                    HStack(
                        alignment: .top,
                        spacing: 44
                    ) {

                        PhotoColumn(images: collageImages)
                            .frame(
                                width: geometry.size.width * 0.235
                            )

                        VStack(spacing: 38) {

                            PostcardWritingArea(
                                canvasIsEmpty: $canvasIsEmpty,
                                drawing: $postcardDrawing,
                                canvasSize: $canvasSize,
                                generatedStamp: $generatedStamp,
                                isGeneratingStamp: $isGeneratingStamp,
                                selectedTool: $selectedTool
                            )
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )

                            Button {
                                generateStampAndSend()
                            } label: {
                                HStack(spacing: 12) {
                                    if isGeneratingStamp || isSending {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(1.1)

                                        Text(isSending ? "Mengirim..." : "Membuat Postcard...")
                                            .font(
                                                .system(
                                                    size: min(
                                                        28,
                                                        geometry.size.width * 0.022
                                                    ),
                                                    weight: .semibold
                                                )
                                            )
                                    } else {
                                        Text("Kirim Postcard")
                                            .font(
                                                .system(
                                                    size: min(
                                                        30,
                                                        geometry.size.width * 0.024
                                                    ),
                                                    weight: .semibold
                                                )
                                            )

                                        Image(systemName: "paperplane.fill")
                                            .font(
                                                .system(
                                                    size: min(
                                                        29,
                                                        geometry.size.width * 0.023
                                                    ),
                                                    weight: .medium
                                                )
                                            )
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: 68
                                )
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 23,
                                        style: .continuous
                                    )
                                    .fill(
                                        Color(
                                            red: 0.03,
                                            green: 0.10,
                                            blue: 0.47
                                        )
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(
                                canvasIsEmpty || isGeneratingStamp
                            )
                            .opacity(
                                canvasIsEmpty ? 0.5 : 1
                            )
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                    }
                    .padding(.horizontal, 95)
                    .padding(.bottom, 58)
                }

                if isSending {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()

                        VStack(spacing: 18) {
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(.white)

                            Text(sendingStatus.isEmpty ? "Mengirim postcard..." : sendingStatus)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 34)
                        .padding(.vertical, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.black.opacity(0.78))
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // Keep the file until the share sheet has finished.
            // It is in the app temporary directory and can be cleaned by iOS.
            localVideoURL = nil
            dismiss()
        }) {
            if let localVideoURL {
                ShareSheet(items: [localVideoURL])
            }
        }
        .alert(
            "Tidak dapat membuat prangko",
            isPresented: $showError
        ) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Generate Stamp

    @available(iOS 26.0, *)
    private func generateStampAndSend() {

        guard !postcardDrawing.strokes.isEmpty else {
            errorMessage = "Silakan tulis pesan terlebih dahulu."
            showError = true
            return
        }

        guard canvasSize.width > 0, canvasSize.height > 0 else {
            errorMessage = "Ukuran area tulisan tidak valid."
            showError = true
            return
        }

        isGeneratingStamp = true

        Task { @MainActor in
            do {
                let service = StampGenerationService()

                let stamp = try await service.generateStamp(
                    from: postcardDrawing,
                    canvasSize: canvasSize
                )

                generatedStamp = stamp
                isGeneratingStamp = false

                generateMediaAndSend(stamp: stamp)

            } catch {
                isGeneratingStamp = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Generate Media + Send

    @available(iOS 26.0, *)
    private func generateMediaAndSend(stamp: UIImage) {

        guard collageImages.count >= 5 else {
            isGeneratingStamp = false
            errorMessage = "Dibutuhkan 5 gambar untuk membuat kolase."
            showError = true
            return
        }

        isGeneratingStamp = false
        isSending = true
        sendingStatus = "Membuat postcard..."

        let drawing = postcardDrawing
        let size = canvasSize
        let images = Array(collageImages.prefix(5))
        Task {
            do {
                let media = try await PostcardMediaGenerator.shared.generate(
                    drawing: drawing,
                    canvasSize: size,
                    stamp: stamp,
                    collageImages: images
                )

                // Video stays LOCAL ONLY. Nothing is uploaded to CloudKit.
                await MainActor.run {
                    sendingStatus = "Video selesai dibuat"
                    localVideoURL = media.videoURL
                    isSending = false
                    showShareSheet = true
                }

            } catch {
                await MainActor.run {
                    isSending = false
                    sendingStatus = ""
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Photo Column

struct PhotoColumn: View {

    let images: [UIImage]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { index in
                let image = index < images.count ? images[index] : UIImage()

                Group {
                    if image.size.width > 0 && image.size.height > 0 {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.gray.opacity(0.22))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.gray)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1.43, contentMode: .fit)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
            }
        }
        .padding(26)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Postcard Writing Area

struct PostcardWritingArea: View {

    @Binding var canvasIsEmpty: Bool
    @Binding var drawing: PKDrawing
    @Binding var canvasSize: CGSize
    @Binding var generatedStamp: UIImage?
    @Binding var isGeneratingStamp: Bool
    @Binding var selectedTool: PostcardDrawingTool

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                // MARK: White Postcard

                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 9,
                    x: 0,
                    y: 5
                )

                // MARK: PencilKit Canvas

                ZStack {

                    if canvasIsEmpty {
                        VStack {
                            HStack {
                                Text("Tulis pesan di sini")
                                    .font(
                                        .system(
                                            size: 23,
                                            weight: .regular
                                        )
                                    )
                                    .italic()
                                    .foregroundStyle(
                                        Color.gray.opacity(0.70)
                                    )

                                Spacer()
                            }

                            Spacer()
                        }
                        .padding(.top, 30)
                        .padding(.leading, 30)
                        .allowsHitTesting(false)
                    }

                    PencilCanvasView(
                        isEmpty: $canvasIsEmpty,
                        drawing: $drawing,
                        canvasSize: $canvasSize,
                        selectedTool: $selectedTool
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )

                // MARK: Stamp

                VStack {
                    HStack {
                        Spacer()

                        StampView(
                            image: generatedStamp,
                            isGenerating: isGeneratingStamp
                        )
                    }

                    Spacer()
                }
                .padding(28)
                .allowsHitTesting(false)

                // MARK: PencilKit Tools

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        PencilKitToolbar(
                            selectedTool: $selectedTool
                        )
                    }
                }
                .padding(.trailing, 22)
                .padding(.bottom, 24)
            }
            .onAppear {
                canvasSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                canvasSize = newSize
            }
        }
    }
}

// MARK: - PencilKit Toolbar

struct PencilKitToolbar: View {

    @Binding var selectedTool: PostcardDrawingTool

    var body: some View {
        VStack(spacing: 0) {

            ToolButton(
                systemName: "pencil",
                isSelected: selectedTool == .pencil
            ) {
                selectedTool = .pencil
            }

            Divider()
                .frame(width: 34)
                .opacity(0.25)

            ToolButton(
                systemName: "eraser",
                isSelected: selectedTool == .eraser
            ) {
                selectedTool = .eraser
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.08),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.16),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}

struct ToolButton: View {

    let systemName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(
                    .system(
                        size: 22,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    isSelected ? .white : .black
                )
                .frame(
                    width: 50,
                    height: 50
                )
                .background(
                    Circle()
                        .fill(
                            isSelected
                            ? Color(
                                red: 0.03,
                                green: 0.10,
                                blue: 0.47
                            )
                            : .clear
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PencilKit Canvas

struct PencilCanvasView: UIViewRepresentable {

    @Binding var isEmpty: Bool
    @Binding var drawing: PKDrawing
    @Binding var canvasSize: CGSize
    @Binding var selectedTool: PostcardDrawingTool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(
        context: Context
    ) -> PKCanvasView {

        let canvas = PKCanvasView()

        canvas.backgroundColor = .clear
        canvas.isOpaque = false

        // Apple Pencil + finger
        canvas.drawingPolicy = .anyInput

        // No scrolling
        canvas.isScrollEnabled = false

        canvas.delegate = context.coordinator
        canvas.drawing = drawing

        applyTool(to: canvas)

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {

        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }

        applyTool(to: canvas)
    }

    private func applyTool(to canvas: PKCanvasView) {

        switch selectedTool {

        case .pencil:
            canvas.tool = PKInkingTool(
                .pen,
                color: UIColor(
                    red: 0.25,
                    green: 0.25,
                    blue: 0.28,
                    alpha: 1
                ),
                width: 4
            )

        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        }
    }

    // MARK: Coordinator

    final class Coordinator:
        NSObject,
        PKCanvasViewDelegate {

        var parent: PencilCanvasView

        init(parent: PencilCanvasView) {
            self.parent = parent
            super.init()
        }

        func canvasViewDrawingDidChange(
            _ canvasView: PKCanvasView
        ) {

            let newDrawing = canvasView.drawing
            let empty = newDrawing.strokes.isEmpty

            DispatchQueue.main.async {
                self.parent.drawing = newDrawing
                self.parent.isEmpty = empty
                self.parent.canvasSize = canvasView.bounds.size
            }
        }
    }
}

enum PostcardDrawingTool {
    case pencil
    case eraser
}

// MARK: - Stamp View

struct StampView: View {

    let image: UIImage?
    let isGenerating: Bool

    var body: some View {
        ZStack {

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else if isGenerating {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.15)

                    Text("Membuat...")
                        .font(
                            .system(
                                size: 13,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                }

            } else {
                VStack(spacing: 6) {
                    Image(systemName: "seal")
                        .font(.system(size: 27))

                    Text("Prangko")
                        .font(
                            .system(
                                size: 18,
                                weight: .medium
                            )
                        )
                }
                .foregroundStyle(.gray)
            }
        }
        .frame(width: 125, height: 150)
        .background(
            Color.gray.opacity(0.25)
        )
        .clipped()
    }
}

// MARK: - Help View

struct HelpView: View {

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {

                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        Color(
                            red: 0.03,
                            green: 0.10,
                            blue: 0.47
                        )
                    )

                Text("Tulis Postcard")
                    .font(.largeTitle.bold())

                Text(
                    "Gunakan Apple Pencil atau jari untuk menulis pesanmu di postcard. Gunakan tombol pensil untuk menulis dan penghapus untuk menghapus."
                )
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)

                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("Bantuan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Device Helpers

extension UIDevice {

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Preview

#Preview {
    TulisPostcardView(images: [UIImage(named: "BoleChudiyanimg") ?? UIImage(), UIImage(named: "BoleChudiyanimg") ?? UIImage(), UIImage(named: "BoleChudiyanimg") ?? UIImage(), UIImage(named: "BoleChudiyanimg") ?? UIImage(), UIImage(named: "BoleChudiyanimg") ?? UIImage()])
}
