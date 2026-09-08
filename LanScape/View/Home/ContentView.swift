//
//  ContentView.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 20/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var navigateToSelectMusic = false
    @State private var navigateToGallery = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isPad = UIDevice.isIPad || geometry.size.height > 550
                let logoWidth: CGFloat = isPad ? 400 : min(210, geometry.size.width * 0.32)
                let buttonWidth: CGFloat = isPad ? 420 : min(290, geometry.size.width * 0.40)
                let buttonHeight: CGFloat = isPad ? 74 : 46
                let buttonFontSize: CGFloat = isPad ? 28 : 17
                let logoBottomSpacing: CGFloat = isPad ? 36 : 14
                let buttonSpacing: CGFloat = isPad ? 18 : 10
                
                ZStack {
                    // Soft cohesive radial gradient background
                    RadialGradient(
                        colors: [
                            Color(hex: "FFFFFF"),
                            Color(hex: "F2F7FF"),
                            Color(hex: "D9EBFF"),
                            Color(hex: "BEDDFF")
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: isPad ? 650 : 380
                    )
                    .ignoresSafeArea()
                    
                    // Ambient decorative glow blobs (subtle & non-intrusive)
                    Circle()
                        .fill(Color.white.opacity(isPad ? 0.7 : 0.5))
                        .frame(width: isPad ? 500 : 260, height: isPad ? 500 : 260)
                        .blur(radius: isPad ? 80 : 50)
                        .offset(y: isPad ? 60 : 30)
                    

                    
                    // Main Centered Content: Logo & Action Buttons
                    VStack(spacing: 0) {
                        Image("logoApp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: logoWidth)
                            .shadow(color: Color.blue.opacity(0.12), radius: 12, y: 4)
                            .padding(.bottom, logoBottomSpacing)
                        
                        // Primary CTA: Mulai Bergerak
                        GradientStartButton(
                            title: "Mulai Bergerak",
                            fontSize: buttonFontSize,
                            fontWeight: .bold
                        ) {
                            navigateToSelectMusic = true
                        }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .padding(.bottom, buttonSpacing)
                        
                        // Secondary CTA: Lihat Galeri
                        Button {
                            navigateToGallery = true
                        } label: {
                            Text("Lihat Galeri")
                                .font(.system(size: buttonFontSize, weight: .bold))
                                .frame(width: buttonWidth, height: buttonHeight)
                                .foregroundStyle(Color.darkBlue)
                                .background(Color.white.opacity(0.85))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.gradient1, .gradient2, .gradient3],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: isPad ? 3.5 : 2.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            .navigationDestination(isPresented: $navigateToSelectMusic) {
                SelectMusicView()
            }
            .navigationDestination(isPresented: $navigateToGallery) {
                GalleryView()
            }

            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PopToRoot"))) { _ in
                navigateToSelectMusic = false
                navigateToGallery = false
            }
            .ignoresSafeArea()
        }
    }
}

#Preview("Home - Phone Landscape", traits: .landscapeLeft) {
    ContentView()
}

#Preview("Home - iPad Landscape", traits: .landscapeRight) {
    ContentView()
}
