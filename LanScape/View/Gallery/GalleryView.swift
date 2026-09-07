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
    @State private var isSelectionMode = false
    @State private var selectedSessions: Set<GallerySession> = []
    @State private var showDeleteConfirmation = false

    var body: some View {

        GeometryReader { geometry in

            let isPad =
                UIDevice.current.userInterfaceIdiom == .pad ||
                geometry.size.height > 550
            let screenW = geometry.size.width
            let columns = isPad
                ? [GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32)]
                : (screenW < 750
                    ? [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                    : [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)])
            let gridSpacing: CGFloat = isPad ? 36 : (screenW < 750 ? 16 : 20)
            let horizontalPad: CGFloat = isPad ? 80 : 20

            ZStack(alignment: .bottom) {

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
                                columns: columns,
                                spacing: gridSpacing
                            ) {

                                ForEach(
                                    gallerySessions
                                ) { session in

                                    GalleryCard(
                                        session: session,
                                        isPad: isPad,
                                        isSelectionMode: isSelectionMode,
                                        isSelected: selectedSessions.contains(session),
                                        onTap: {
                                            if isSelectionMode {
                                                toggleSelection(session)
                                            } else {
                                                selectedSession = session
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(
                                .horizontal,
                                horizontalPad
                            )
                            .padding(
                                .top,
                                isPad ? 28 : 14
                            )
                            .padding(
                                .bottom,
                                isSelectionMode ? 100 : 36
                            )
                        }
                    }
                }

                // MARK: Bottom Selection Toolbar

                if isSelectionMode {
                    selectionBottomToolbar(isPad: isPad)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }

        // MARK: Gallery → CompletionView

        .fullScreenCover(
            item: $selectedSession
        ) { session in
            CompletionView(
                durationSeconds: 0,
                capturedPhotos: session.images,
                isReadOnly: true
            )
        }

        // MARK: Delete Confirmation Dialog

        .confirmationDialog(
            "Hapus Sesi Foto?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Hapus \(selectedSessions.count) Sesi", role: .destructive) {
                deleteSelectedSessions()
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Sesi foto yang dipilih akan dihapus secara permanen dari galeri.")
        }
    }

    // MARK: - Selection Actions

    private func toggleSelection(_ session: GallerySession) {
        if selectedSessions.contains(session) {
            selectedSessions.remove(session)
        } else {
            selectedSessions.insert(session)
        }
    }

    private func deleteSelectedSessions() {
        withAnimation {
            for session in selectedSessions {
                modelContext.delete(session)
            }
            do {
                try modelContext.save()
                print("✅ Selected sessions deleted.")
            } catch {
                print("❌ Failed to delete sessions: \(error.localizedDescription)")
            }
            selectedSessions.removeAll()
            isSelectionMode = false
        }
    }

    // MARK: - Header

    private func header(
        isPad: Bool
    ) -> some View {

        HStack {
            // Sisi kiri kosong untuk menjaga judul tetap simetris di tengah
            Color.clear
                .frame(width: isPad ? 80 : 48, height: isPad ? 44 : 32)

            Spacer()

            VStack(spacing: 2) {

                Text("Galeri Foto")
                    .font(
                        .system(
                            size: isPad ? 36 : 20,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.black)

                Text(
                    "Lihat kembali momen seru saat bergerak bersama"
                )
                .font(
                    .system(
                        size: isPad ? 18 : 11.5,
                        weight: .medium
                    )
                )
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }

            Spacer()

            // Tombol Pilih / Batal (Toolbar Header Kanan)
            if !gallerySessions.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedSessions.removeAll()
                        }
                    }
                } label: {
                    Text(isSelectionMode ? "Batal" : "Pilih")
                        .font(.system(size: isPad ? 18 : 13, weight: .bold))
                        .foregroundColor(isSelectionMode ? .red : .blue)
                        .padding(.horizontal, isPad ? 16 : 10)
                        .padding(.vertical, isPad ? 8 : 4)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Capsule())
                }
            } else {
                Color.clear
                    .frame(width: isPad ? 80 : 48, height: isPad ? 44 : 32)
            }
        }
        .padding(
            .horizontal,
            isPad ? 42 : 20
        )
        .padding(
            .top,
            isPad ? 24 : 10
        )
    }

    // MARK: - Bottom Toolbar

    private func selectionBottomToolbar(isPad: Bool) -> some View {
        HStack {
            Text("\(selectedSessions.count) dipilih")
                .font(.system(size: isPad ? 18 : 13, weight: .medium))
                .foregroundColor(.black)

            Spacer()

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Hapus")
                }
                .font(.system(size: isPad ? 18 : 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 22 : 14)
                .padding(.vertical, isPad ? 10 : 6)
                .background(selectedSessions.isEmpty ? Color.gray : Color.red)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
            }
            .disabled(selectedSessions.isEmpty)
        }
        .padding(.horizontal, isPad ? 60 : 24)
        .padding(.vertical, isPad ? 14 : 8)
        .background(
            Color.white.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: -3)
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
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {

        Button {
            onTap()
        } label: {

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                // MARK: Only First Photo & Selection Checkmark

                ZStack(alignment: .topTrailing) {

                    ZStack(alignment: .bottomTrailing) {

                        if let firstImage = session.images.first {

                            Image(uiImage: firstImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1.43, contentMode: .fit)
                                .clipped()

                        } else {

                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .aspectRatio(1.43, contentMode: .fit)
                        }

                        // MARK: Photo Count Badge

                        if session.photoCount > 1 {
                            HStack(spacing: 5) {
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: isPad ? 14 : 11, weight: .bold))

                                Text("\(session.photoCount)")
                                    .font(.system(size: isPad ? 14 : 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, isPad ? 11 : 8)
                            .padding(.vertical, isPad ? 7 : 5)
                            .background(Color.black.opacity(0.60))
                            .clipShape(Capsule())
                            .padding(isPad ? 12 : 9)
                        }
                    }

                    // Selection Checkmark Circle Overlay
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: isPad ? 26 : 20, weight: .bold))
                            .foregroundColor(isSelected ? .blue : .white)
                            .background(Circle().fill(Color.black.opacity(0.2)))
                            .padding(isPad ? 12 : 9)
                    }
                }
        .clipShape(
                    RoundedRectangle(
                        cornerRadius: isPad ? 20 : 15,
                        style: .continuous
                    )
                )

                // MARK: Card Text

                VStack(
                    alignment: .leading,
                    spacing: isPad ? 4 : 2
                ) {

                    Text(session.title)
                        .font(
                            .system(
                                size: isPad ? 22 : 14,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(
                        formattedDate(session.date)
                    )
                    .font(
                        .system(
                            size: isPad ? 16 : 11
                        )
                    )
                    .foregroundColor(.gray)
                }
                .padding(
                    .horizontal,
                    isPad ? 16 : 10
                )
                .padding(
                    .vertical,
                    isPad ? 12 : 8
                )
            }
            .background(Color.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: isPad ? 20 : 13,
                    style: .continuous
                )
            )
            .shadow(
                color: Color.black.opacity(0.14),
                radius: isPad ? 8 : 4,
                x: 0,
                y: isPad ? 5 : 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 20 : 13)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: isPad ? 3 : 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Date

    private func formattedDate(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "dd MMMM yyyy"

        return formatter.string(from: date)
    }
}


// MARK: - Save Gallery Session

extension GallerySession {

    static func save(
        images: [UIImage],
        title: String,
        into modelContext: ModelContext
    ) {

        guard !images.isEmpty else {
            print("⚠️ GallerySession: tidak ada gambar.")
            return
        }

        let session = GallerySession(
            title: title,
            date: Date(),
            images: Array(images.prefix(5))
        )

        modelContext.insert(session)

        do {
            try modelContext.save()

            print("✅ Gallery session saved: \(session.id.uuidString)")
            print("📸 Photos saved: \(session.photoCount)")

        } catch {
            print("❌ Failed to save gallery: \(error.localizedDescription)")
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
