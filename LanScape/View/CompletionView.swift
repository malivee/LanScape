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
        GeometryReader { geometry in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad || geometry.size.height > 550
            let cardWidth = isPad ? min(1050, geometry.size.width * 0.90) : min(780, geometry.size.width * 0.92)
            let cardHeight = isPad ? min(510, geometry.size.height * 0.62) : min(220, geometry.size.height * 0.60)
            let photoW = isPad ? CGFloat(400) : CGFloat(170)
            let photoH = isPad ? CGFloat(360) : CGFloat(150)
            let btnW = isPad ? CGFloat(280) : min(CGFloat(210), (geometry.size.width - 80) / 3.3)
            let btnH = isPad ? CGFloat(72) : CGFloat(44)
            let btnFont = isPad ? CGFloat(24) : CGFloat(14)
            
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: isPad ? 24 : 8) {
                    Spacer(minLength: isPad ? 10 : 4)
                    
                    // title
                    Text("HORE, KALIAN BERHASIL!!")
                        .font(.system(size: isPad ? 40 : 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // card utama
                    HStack(spacing: isPad ? 36 : 16) {
                        // stack foto di sebelah kiri
                        PhotoStackView(
                            photos: photos,
                            capturedPhotos: capturedPhotos,
                            photoWidth: photoW,
                            photoHeight: photoH
                        ) {
                            showGalleryModal = true
                        }
                        
                        // info teks di sebelah kanan
                        VStack(alignment: .leading, spacing: isPad ? 14 : 4) {
                            Text("Kombinasi yang luar biasa!\nKalian berhasil menyelesaikan seluruh gerakan dengan baik.")
                                .font(.system(size: isPad ? 26 : 13, weight: .semibold))
                                .lineSpacing(isPad ? 4 : 2)
                                .lineLimit(2)
                            
                            Divider()
                                .frame(height: 1)
                                .background(.gray)
                                .padding(.vertical, isPad ? 14 : 4)
                            
                            VStack(alignment: .leading, spacing: isPad ? 6 : 2) {
                                Text("Kalian telah bergerak selama")
                                    .font(.system(size: isPad ? 22 : 11, weight: .regular))
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: isPad ? 22 : 13, weight: .bold))
                                    Text(formattedDuration)
                                        .font(.system(size: isPad ? 24 : 14, weight: .bold))
                                }
                                .foregroundColor(Color.darkBlue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, isPad ? 20 : 10)
                    }
                    .padding(.horizontal, isPad ? 28 : 14)
                    .frame(width: cardWidth, height: cardHeight)
                    .background(Color.lightBlue)
                    .cornerRadius(isPad ? 24 : 16)
                    
                    // action buttons
                    HStack(spacing: isPad ? 20 : 10) {
                        CompletionActionButton(title: "Ulangi", systemIcon: "arrow.counterclockwise", width: btnW, height: btnH, fontSize: btnFont) {
                            if let onRestart {
                                onRestart()
                            } else {
                                dismiss()
                            }
                        }
                        
                        CompletionActionButton(title: "Menu Utama", systemIcon: "house.fill", width: btnW, height: btnH, fontSize: btnFont) {
                            if let onMainMenu {
                                onMainMenu()
                            } else {
                                navigateToMainView = true
                            }
                        }
                        
                        CompletionActionButton(title: "Pilih Lagu", systemIcon: "play.fill", isPrimary: true, width: btnW, height: btnH, fontSize: btnFont) {
                            if let onSelectMusic {
                                onSelectMusic()
                            } else {
                                navigateToSelectMusicView = true
                            }
                        }
                    }
                    
                    Spacer(minLength: isPad ? 10 : 4)
                }
                .padding(.horizontal, 16)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
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
    var photoWidth: CGFloat = 430
    var photoHeight: CGFloat = 400
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
                    .frame(width: photoWidth, height: photoHeight)
                    .clipShape(RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16)
                            .stroke(Color.white, lineWidth: photoHeight < 200 ? 1.5 : 2)
                    )
                    .rotationEffect(.degrees(-8))
                
                renderImage(at: min(1, totalCount - 1))
                    .frame(width: photoWidth, height: photoHeight)
                    .clipShape(RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16)
                            .stroke(Color.white, lineWidth: photoHeight < 200 ? 1.5 : 2)
                    )
                    .rotationEffect(.degrees(-4))
                
                // foto yang paling depan
                ZStack(alignment: .bottomTrailing) {
                    renderImage(at: 0)
                        .frame(width: photoWidth, height: photoHeight)
                        .clipShape(RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: photoHeight < 200 ? 10 : 16)
                                .stroke(Color.white, lineWidth: photoHeight < 200 ? 1.5 : 2)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // badge "+more"
                    if totalCount > 3 {
                        Text("+\(totalCount - 3) more")
                            .font(.system(size: photoHeight < 200 ? 10 : 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, photoHeight < 200 ? 6 : 10)
                            .padding(.vertical, photoHeight < 200 ? 3 : 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                            .padding(photoHeight < 200 ? 6 : 12)
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
    
    @ViewBuilder
    private func renderModalImage(at index: Int) -> some View {
        if !capturedImages.isEmpty {
            let safeIndex = max(0, min(index, capturedImages.count - 1))
            Image(uiImage: capturedImages[safeIndex])
                .resizable()
                .scaledToFit()
        } else if !images.isEmpty {
            let safeIndex = max(0, min(index, images.count - 1))
            Image(images[safeIndex])
                .resizable()
                .scaledToFit()
        } else {
            Color.gray.opacity(0.3)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frameHeight = geometry.size.height * 0.85
            
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(0..<totalCount, id: \.self) { index in
                                renderModalImage(at: index)
                                    .frame(width: geometry.size.width * 0.8, height: frameHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal, geometry.size.width * 0.1)
                    }
                    .scrollPosition(id: $scrollPosition, anchor: .center)
                    .scrollTargetBehavior(.viewAligned(anchor: .center))
                    
                    if totalCount > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<totalCount, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
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
                    .padding(.trailing, 30)
                    .padding(.top, 24)
                    
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
    var width: CGFloat = 300
    var height: CGFloat = 76
    var fontSize: CGFloat = 26
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .font(.system(size: fontSize * 0.9, weight: .bold))
                Text(title)
                    .font(.system(size: fontSize, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .background(
                Group {
                    if isPrimary {
                        LinearGradient(
                            colors: [.gradient1, .gradient2, .gradient3],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.darkBlue.opacity(0.85)
                    }
                }
            )
            .cornerRadius(height / 2)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2)
                    .stroke(Color.white.opacity(0.6), lineWidth: isPrimary ? 0 : 1.5)
            )
        }
    }
}

#Preview("Completion - Phone Landscape", traits: .landscapeLeft) {
    CompletionView()
}

#Preview("Completion - iPad Landscape", traits: .landscapeRight) {
    CompletionView()
}
