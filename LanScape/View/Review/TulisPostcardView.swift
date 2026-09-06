//
//  TulisPostcardView.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import SwiftUI
import PencilKit

struct TulisPostcardView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var showHelp = false
    @State private var canvasIsEmpty = true

    var body: some View {
        GeometryReader { geometry in

            ZStack {

                // MARK: - Background
                LinearGradient(
                    colors: [
                        Color(red: 0.72, green: 0.84, blue: 0.98),
                        Color(red: 0.88, green: 0.94, blue: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()


                // MARK: - Main Content
                VStack(spacing: 0) {

                    // MARK: Header
                    HStack {

                        // Back button
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
                                .font(.system(
                                    size: min(42, geometry.size.width * 0.034),
                                    weight: .bold
                                ))
                                .foregroundStyle(.black)

                            Text("Tulis pesan bermakna untuk orang tersayang")
                                .font(.system(
                                    size: min(24, geometry.size.width * 0.019),
                                    weight: .medium
                                ))
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        // Help button
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


                    // MARK: Content
                    HStack(
                        alignment: .top,
                        spacing: 44
                    ) {

                        // MARK: Photos
                        PhotoColumn()
                            .frame(
                                width: geometry.size.width * 0.235
                            )


                        // MARK: Postcard
                        VStack(spacing: 38) {

                            PostcardWritingArea(
                                canvasIsEmpty: $canvasIsEmpty
                            )
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )

                            // Send button
                            Button {
                                sendPostcard()
                            } label: {
                                HStack(spacing: 12) {

                                    Text("Kirim Postcard")
                                        .font(.system(
                                            size: min(
                                                30,
                                                geometry.size.width * 0.024
                                            ),
                                            weight: .semibold
                                        ))

                                    Image(systemName: "paperplane.fill")
                                        .font(.system(
                                            size: min(
                                                29,
                                                geometry.size.width * 0.023
                                            ),
                                            weight: .medium
                                        ))
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
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                    }
                    .padding(.horizontal, 95)
                    .padding(.bottom, 58)
                }
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }


    // MARK: - Send
    private func sendPostcard() {
        // Add your CloudKit / navigation logic here.
    }
}


// MARK: - Photo Column

struct PhotoColumn: View {

    // Replace these with your actual image names
    private let imageNames = [
        "postcardPhoto",
        "postcardPhoto",
        "postcardPhoto",
        "postcardPhoto"
    ]

    var body: some View {

        VStack(spacing: 10) {

            ForEach(imageNames.indices, id: \.self) { index in

                Group {

                    if let image = UIImage(named: imageNames[index]) {

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()

                    } else {

                        // Placeholder if asset doesn't exist
                        RoundedRectangle(cornerRadius: 20)
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
        .background(
            Color.white
        )
    }
}


// MARK: - Postcard Writing Area

struct PostcardWritingArea: View {

    @Binding var canvasIsEmpty: Bool

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                // White postcard
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


                // MARK: Pencil Canvas

                ZStack {

                    // Placeholder
                    if canvasIsEmpty {

                        VStack {

                            HStack {

                                Text("Tulis pesan di sini")
                                    .font(.system(
                                        size: min(
                                            23,
                                            geometry.size.width * 0.025
                                        ),
                                        weight: .regular
                                    ))
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
                        isEmpty: $canvasIsEmpty
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                }
                .padding(2)


                // MARK: Microphone Button

                VStack {

                    Spacer()

                    HStack {

                        Spacer()

                        Button {

                            startDictation()

                        } label: {

                            Image(systemName: "mic.fill")
                                .font(.system(
                                    size: 22,
                                    weight: .medium
                                ))
                                .foregroundStyle(.gray)
                                .frame(
                                    width: 58,
                                    height: 58
                                )
                                .background(
                                    Circle()
                                        .fill(.white)
                                )
                                .shadow(
                                    color: .black.opacity(0.15),
                                    radius: 7,
                                    y: 4
                                )
                        }
                    }
                }
                .padding(25)
            }
        }
    }


    private func startDictation() {
        // Connect this to your speech recognition code.
    }
}


// MARK: - PencilKit Canvas

struct PencilCanvasView: UIViewRepresentable {

    @Binding var isEmpty: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {

        let canvas = PKCanvasView()

        // MARK: Canvas configuration

        canvas.backgroundColor = .clear
        canvas.isOpaque = false

        // Allow Apple Pencil + finger
        canvas.drawingPolicy = .anyInput

        // Default pencil
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

        // Disable scrolling
        canvas.isScrollEnabled = false

        // Delegate
        canvas.delegate = context.coordinator

        return canvas
    }


    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {

    }


    // MARK: Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {

        var parent: PencilCanvasView

        init(parent: PencilCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(
            _ canvasView: PKCanvasView
        ) {

            let empty = canvasView.drawing.strokes.isEmpty

            if parent.isEmpty != empty {

                DispatchQueue.main.async {
                    self.parent.isEmpty = empty
                }
            }
        }
    }
}


// MARK: - Help View

struct HelpView: View {

    @Environment(\.dismiss) private var dismiss

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
                    "Gunakan Apple Pencil atau jari untuk menulis pesanmu di postcard."
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


// MARK: - Preview

#Preview {
    TulisPostcardView()
}
