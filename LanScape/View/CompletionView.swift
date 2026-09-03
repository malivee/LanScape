// Completion or Result Page

import SwiftUI

struct CompletionView: View {
    var durationSeconds: TimeInterval = 243
    var photos: [String] = ["markHaechan", "markHaechan", "markHaechan", "markHaechan", "markHaechan"]
    var capturedPhotos: [UIImage] = []
    var onRestart: (() -> Void)? = nil
    var onSelectMusic: (() -> Void)? = nil
    var onMainMenu: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var showGalleryModal = false
    @State private var navigateToMainView = false
    @State private var navigateToSelectMusicView = false
    
    private var formattedDuration: String {
        let total = Int(durationSeconds)
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return "\(m) menit \(s) detik"
        } else {
            return "\(s) detik"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // title
                Text("HORE, KALIAN BERHASIL!!")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                
                // card utama
                HStack(spacing: 44) {
                    // stack foto di sebelah kiri
                    PhotoStackView(photos: photos, capturedPhotos: capturedPhotos) {
                        showGalleryModal = true
                    }
                    
                    // info teks di sebelah kanan
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Kombinasi yang luar biasa!\nKalian berhasil menyelesaikan seluruh gerakan dengan baik.")
                            .font(.system(size: 30, weight: .semibold))
                            .lineSpacing(4)
                        
                        Divider()
                            .frame(height: 1)
                            .background(.gray)
                            .padding(.vertical, 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kalian telah bergerak selama")
                                .font(.system(size: 26, weight: .regular))
                            
                            HStack(spacing: 6) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 26, weight: .bold))
                                Text(formattedDuration)
                                    .font(.system(size: 26, weight: .bold))
                            }
                            .foregroundColor(Color.darkBlue)
                        }
                    }
                    .frame(width: 470, height: 400, alignment: .leading)
                }
                .frame(width: 1050, height: 510)
                .background(Color.lightBlue)
                .cornerRadius(24)
                
                // action buttons
                HStack(spacing: 24) {
                    CompletionActionButton(title: "Ulangi", systemIcon: "arrow.counterclockwise") {
                        if let onRestart {
                            onRestart()
                        } else {
                            dismiss()
                        }
                    }
                    
                    CompletionActionButton(title: "Menu Utama", systemIcon: "house.fill") {
                        if let onMainMenu {
                            onMainMenu()
                        } else {
                            navigateToMainView = true
                        }
                    }
                    
                    CompletionActionButton(title: "Pilih Lagu", systemIcon: "play.fill", isPrimary: true) {
                        if let onSelectMusic {
                            onSelectMusic()
                        } else {
                            navigateToSelectMusicView = true
                        }
                    }
                }
            }
            .padding()
        }
        // modal preview galeri foto
        .fullScreenCover(isPresented: $showGalleryModal) {
            ImageGalleryModal(
                images: photos,
                capturedImages: capturedPhotos,
                isPresented: $showGalleryModal
            )
        }
        // navigasi ke ContentView (menu utama)
        .fullScreenCover(isPresented: $navigateToMainView) {
            ContentView()
        }
        // navigasi ke SelectMusicView (pilih lagu)
        .fullScreenCover(isPresented: $navigateToSelectMusicView) {
            SelectMusicView()
        }
    }
}

// MARK: - Reusable Photo Stack Component
struct PhotoStackView: View {
    var photos: [String] = []
    var capturedPhotos: [UIImage] = []
    let onTap: () -> Void
    
    private var totalCount: Int {
        !capturedPhotos.isEmpty ? capturedPhotos.count : photos.count
    }
    
    @ViewBuilder
    private func renderImage(at index: Int) -> some View {
        if !capturedPhotos.isEmpty {
            let safeIndex = max(0, min(index, capturedPhotos.count - 1))
            Image(uiImage: capturedPhotos[safeIndex])
                .resizable()
                .scaledToFill()
        } else if !photos.isEmpty {
            let safeIndex = max(0, min(index, photos.count - 1))
            Image(photos[safeIndex])
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.3)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // layer foto belakang
                renderImage(at: min(2, totalCount - 1))
                    .frame(width: 430, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(-8))
                
                renderImage(at: min(1, totalCount - 1))
                    .frame(width: 430, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(-4))
                
                // foto yang paling depan
                ZStack(alignment: .bottomTrailing) {
                    renderImage(at: 0)
                        .frame(width: 430, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // badge "+more"
                    if totalCount > 3 {
                        Text("+\(totalCount - 3) more")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(12)
                    }
                }
            }
            // buka modal gallery
            .onTapGesture {
                onTap()
            }
        }
    }
}

// MARK: - Image Gallery Modal
struct ImageGalleryModal: View {
    var images: [String] = []
    var capturedImages: [UIImage] = []
    @Binding var isPresented: Bool
    
    @State private var scrollPosition: Int? = 0
    
    private var currentIndex: Int {
        scrollPosition ?? 0
    }
    
    private var totalCount: Int {
        !capturedImages.isEmpty ? capturedImages.count : images.count
    }
    
    private let frameHeight: CGFloat = 715
    private let photoWidth: CGFloat = 786
    private let photoHeight: CGFloat = 510
    
    @ViewBuilder
    private func renderModalImage(at index: Int) -> some View {
        if !capturedImages.isEmpty {
            let safeIndex = max(0, min(index, capturedImages.count - 1))
            Image(uiImage: capturedImages[safeIndex])
                .resizable()
                .scaledToFill()
        } else if !images.isEmpty {
            let safeIndex = max(0, min(index, images.count - 1))
            Image(images[safeIndex])
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.3)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                ZStack {
                    Color.white
                    // foto carousel swipe kanan-kiri
                    VStack(spacing: 18) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(0..<totalCount, id: \.self) { index in
                                    renderModalImage(at: index)
                                        .frame(width: photoWidth, height: photoHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        .id(index)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, (geometry.size.width - photoWidth) / 2)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $scrollPosition)
                        .frame(height: photoHeight)
                        
                        // dots indicator
                        HStack(spacing: 8) {
                            ForEach(0..<totalCount, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.black : Color.gray.opacity(0.3))
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(width: geometry.size.width, height: frameHeight)
                .clipped()
                
                // close button
                VStack {
                    HStack {
                        Spacer()
                        CloseIconButton {
                            isPresented = false
                        }
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 64)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Reusable Action Button Component
struct CompletionActionButton: View {
    let title: String
    let systemIcon: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemIcon)
                Text(title)
            }
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 300, height: 76)
            .background(
                Group {
                    if isPrimary {
                        LinearGradient(
                            colors: [.gradient1, .gradient2, .gradient3],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.darkBlue.opacity(0.8)
                    }
                }
            )
            .cornerRadius(50)
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.white.opacity(0.6), lineWidth: isPrimary ? 0 : 1.5)
            )
        }
    }
}

#Preview {
    CompletionView()
}
