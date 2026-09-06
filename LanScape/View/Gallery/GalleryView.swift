//
//  GalleryView.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Gallery View

struct GalleryView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \GallerySession.date,
        order: .reverse
    )
    private var gallerySessions: [GallerySession]

    @State private var selectedSession: GallerySession?

    var body: some View {

        GeometryReader { geometry in

            let isPad =
                UIDevice.current.userInterfaceIdiom == .pad ||
                geometry.size.height > 550

            ZStack {

                // MARK: Background

                LinearGradient(
                    colors: [
                        Color(
                            red: 0.72,
                            green: 0.84,
                            blue: 0.98
                        ),
                        Color(
                            red: 0.84,
                            green: 0.92,
                            blue: 1.0
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: Decorative Lines

                decorativeLines(
                    size: geometry.size,
                    isPad: isPad
                )

                // MARK: Main Content

                VStack(spacing: 0) {

                    // MARK: Header

                    header(
                        isPad: isPad
                    )

                    // MARK: Gallery

                    if gallerySessions.isEmpty {

                        emptyState(
                            isPad: isPad
                        )

                    } else {

                        ScrollView(
                            .vertical,
                            showsIndicators: false
                        ) {

                            LazyVGrid(
                                columns: [

                                    GridItem(
                                        .flexible(),
                                        spacing: isPad ? 40 : 28
                                    ),

                                    GridItem(
                                        .flexible(),
                                        spacing: isPad ? 40 : 28
                                    ),

                                    GridItem(
                                        .flexible(),
                                        spacing: isPad ? 40 : 28
                                    )
                                ],
                                spacing: isPad ? 42 : 30
                            ) {

                                ForEach(
                                    gallerySessions
                                ) { session in

                                    GalleryCard(
                                        session: session,
                                        isPad: isPad
                                    ) {

                                        selectedSession =
                                            session
                                    }
                                }
                            }
                            .padding(
                                .horizontal,
                                isPad ? 120 : 55
                            )
                            .padding(
                                .top,
                                isPad ? 36 : 28
                            )
                            .padding(
                                .bottom,
                                40
                            )
                        }
                    }
                }
            }
        }

        // MARK: Gallery → CompletionView

        .fullScreenCover(
            item: $selectedSession
        ) { session in
            CompletionView(
                durationSeconds: 0,
                capturedPhotos: session.images
            )
        }
    }

    // MARK: - Header

    private func header(
        isPad: Bool
    ) -> some View {

        HStack {

            // Home

            Button {

                // Put your home navigation here.

            } label: {

                Image(
                    systemName: "house.fill"
                )
                .font(
                    .system(
                        size: isPad ? 30 : 22,
                        weight: .semibold
                    )
                )
                .foregroundColor(.black)
                .frame(
                    width: isPad ? 68 : 56,
                    height: isPad ? 68 : 56
                )
                .background(
                    Color.white.opacity(0.55)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.8),
                            lineWidth: 1
                        )
                )
            }

            Spacer()

            VStack(spacing: 2) {

                Text("Galeri Foto")
                    .font(
                        .system(
                            size: isPad ? 42 : 30,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.black)

                Text(
                    "Lihat kembali momen seru saat bergerak bersama"
                )
                .font(
                    .system(
                        size: isPad ? 23 : 17,
                        weight: .medium
                    )
                )
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }

            Spacer()

            // Sort

            Button {

                // Sorting can be added later.

            } label: {

                Image(
                    systemName: "arrow.up.arrow.down"
                )
                .font(
                    .system(
                        size: isPad ? 30 : 22,
                        weight: .medium
                    )
                )
                .foregroundColor(.black)
                .frame(
                    width: isPad ? 68 : 56,
                    height: isPad ? 68 : 56
                )
                .background(
                    Color.white.opacity(0.55)
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.8),
                            lineWidth: 1
                        )
                )
            }
        }
        .padding(
            .horizontal,
            isPad ? 42 : 30
        )
        .padding(
            .top,
            isPad ? 28 : 24
        )
    }

    // MARK: - Decorative Lines

    private func decorativeLines(
        size: CGSize,
        isPad: Bool
    ) -> some View {

        ZStack {

            Path { path in

                path.move(
                    to: CGPoint(
                        x: -100,
                        y: size.height * 0.48
                    )
                )

                path.addCurve(
                    to: CGPoint(
                        x: size.width + 100,
                        y: size.height * 0.35
                    ),
                    control1: CGPoint(
                        x: size.width * 0.25,
                        y: size.height * 0.25
                    ),
                    control2: CGPoint(
                        x: size.width * 0.70,
                        y: size.height * 0.60
                    )
                )
            }
            .stroke(
                Color.white.opacity(0.9),
                lineWidth: isPad ? 14 : 8
            )

            Path { path in

                path.move(
                    to: CGPoint(
                        x: -100,
                        y: size.height * 0.86
                    )
                )

                path.addCurve(
                    to: CGPoint(
                        x: size.width + 100,
                        y: size.height * 0.76
                    ),
                    control1: CGPoint(
                        x: size.width * 0.25,
                        y: size.height * 0.78
                    ),
                    control2: CGPoint(
                        x: size.width * 0.70,
                        y: size.height * 0.95
                    )
                )
            }
            .stroke(
                Color.white.opacity(0.9),
                lineWidth: isPad ? 14 : 8
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Empty State

    private func emptyState(
        isPad: Bool
    ) -> some View {

        VStack(spacing: 18) {

            Spacer()

            Image(
                systemName: "photo.on.rectangle.angled"
            )
            .font(
                .system(
                    size: isPad ? 65 : 50
                )
            )
            .foregroundColor(
                .white.opacity(0.85)
            )

            Text("Belum ada foto")
                .font(
                    .system(
                        size: isPad ? 30 : 22,
                        weight: .bold
                    )
                )
                .foregroundColor(.black)

            Text(
                "Foto dari sesi gerakanmu akan muncul di sini."
            )
            .font(
                .system(
                    size: isPad ? 20 : 15
                )
            )
            .foregroundColor(.gray)

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - Gallery Card

struct GalleryCard: View {

    let session: GallerySession

    let isPad: Bool

    let onTap: () -> Void

    var body: some View {

        Button {

            onTap()

        } label: {

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                // MARK: Only First Photo

                ZStack(alignment: .bottomTrailing) {

                    if let firstImage =
                        session.images.first {

                        Image(
                            uiImage: firstImage
                        )
                        .resizable()
                        .scaledToFill()
                        .frame(
                            maxWidth: .infinity
                        )
                        .aspectRatio(
                            1.43,
                            contentMode: .fit
                        )
                        .clipped()

                    } else {

                        Rectangle()
                            .fill(
                                Color.gray.opacity(0.15)
                            )
                            .aspectRatio(
                                1.43,
                                contentMode: .fit
                            )
                    }

                    // MARK: Photo Count

                    if session.photoCount > 1 {

                        HStack(spacing: 5) {

                            Image(
                                systemName:
                                    "photo.stack.fill"
                            )
                            .font(
                                .system(
                                    size: isPad ? 14 : 11,
                                    weight: .bold
                                )
                            )

                            Text(
                                "\(session.photoCount)"
                            )
                            .font(
                                .system(
                                    size: isPad ? 14 : 11,
                                    weight: .bold
                                )
                            )
                        }
                        .foregroundColor(.white)
                        .padding(
                            .horizontal,
                            isPad ? 11 : 8
                        )
                        .padding(
                            .vertical,
                            isPad ? 7 : 5
                        )
                        .background(
                            Color.black.opacity(0.60)
                        )
                        .clipShape(Capsule())
                        .padding(
                            isPad ? 12 : 9
                        )
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            isPad ? 20 : 15,
                        style: .continuous
                    )
                )

                // MARK: Card Text

                VStack(
                    alignment: .leading,
                    spacing: isPad ? 5 : 3
                ) {

                    Text(session.title)
                        .font(
                            .system(
                                size: isPad ? 25 : 19,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(
                        formattedDate(
                            session.date
                        )
                    )
                    .font(
                        .system(
                            size: isPad ? 19 : 15
                        )
                    )
                    .foregroundColor(.gray)
                }
                .padding(
                    .horizontal,
                    isPad ? 18 : 14
                )
                .padding(
                    .vertical,
                    isPad ? 15 : 12
                )
            }
            .background(Color.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        isPad ? 22 : 17,
                    style: .continuous
                )
            )
            .shadow(
                color: Color.black.opacity(0.14),
                radius: 8,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Date

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier: "id_ID"
            )

        formatter.dateFormat =
            "dd MMMM yyyy"

        return formatter.string(
            from: date
        )
    }
}


// MARK: - Gallery Detail

//


// MARK: - Save Gallery Session

extension GallerySession {

    static func save(
        images: [UIImage],
        title: String,
        into modelContext: ModelContext
    ) {

        guard !images.isEmpty else {
            print(
                "⚠️ GallerySession: tidak ada gambar."
            )
            return
        }

        let session =
            GallerySession(
                title: title,
                date: Date(),
                images: Array(
                    images.prefix(5)
                )
            )

        modelContext.insert(session)

        do {

            try modelContext.save()

            print(
                "✅ Gallery session saved:"
                + " \(session.id.uuidString)"
            )

            print(
                "📸 Photos saved:"
                + " \(session.photoCount)"
            )

        } catch {

            print(
                "❌ Failed to save gallery:"
                + " \(error.localizedDescription)"
            )
        }
    }
}


// MARK: - Preview

#Preview(
    "Gallery View",
    traits: .landscapeLeft
) {

    GalleryView()
}
