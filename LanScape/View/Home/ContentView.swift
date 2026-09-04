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
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    colors: [
                        Color(hex: "FBFCFF"),
                        Color(hex: "E4F1FF"),
                        Color(hex: "C3DFFF")
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 550
                )
                .ignoresSafeArea()
                    
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showHelp = true
                        } label: {
                            Image(systemName: "questionmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.darkBlue)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.85))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                    }
                    .padding(.trailing, 140)
                    .padding(.top, 20)
                    Spacer()
                }
                ZStack {
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 1440, height: 770)
                        .offset(y: 490)
                        .shadow(color: .black.opacity(0.25), radius: 16, y: -2)
                    
                    VStack {
                        Image("logoApp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 450)
                            .padding(.bottom, 90)
                        
                        GradientStartButton(title: "Mulai Berpose", fontSize:34, fontWeight: .bold) {
                            // trigger navigation
                            navigateToSelectMusic = true
                        }
                        .frame(width: 450, height: 85)
                        .padding(.bottom, 24)
                        
                        Button {
                            navigateToGallery = true
                        } label: {
                            Text("Lihat Galeri")
                                .font(.system(size: 34, weight: .bold))
                                .frame(width: 450, height: 85)
                                .foregroundStyle(.darkBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                .background(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(LinearGradient(
                                            colors: [.gradient1, .gradient2, .gradient3],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ), lineWidth: 4))
                        }
                    }
                    .padding(.top, 50)
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


#Preview {
    ContentView()
}
