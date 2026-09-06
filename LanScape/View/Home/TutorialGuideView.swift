//
//  TutorialGuideView.swift
//  LanScape
//

import SwiftUI

enum TutorialTab: String, CaseIterable, Identifiable {
    case tutorial = "Cara Bermain"
    case standing = "Contoh Berdiri"
    case sitting = "Contoh Duduk"
    case fusion = "Contoh Pose"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .tutorial: return "play.circle.fill"
        case .standing: return "figure.stand"
        case .sitting: return "figure.seated.side"
        case .fusion: return "sparkles"
        }
    }
}

struct TutorialGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: TutorialTab = .tutorial
    
    var body: some View {
        GeometryReader { geometry in
            let isPad = UIDevice.isIPad || geometry.size.height > 550
            let modalWidth = isPad ? min(1000, geometry.size.width * 0.90) : min(760, geometry.size.width * 0.94)
            let modalHeight = isPad ? min(680, geometry.size.height * 0.88) : min(340, geometry.size.height * 0.92)
            
            ZStack {
                // Dimmed backdrop
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Main Dialog Card
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .font(.system(size: isPad ? 22 : 15, weight: .bold))
                                .foregroundColor(Color.darkBlue)
                            Text("Panduan & Contoh Bermain")
                                .font(.system(size: isPad ? 24 : 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.darkBlue)
                        }
                        
                        Spacer()
                        
                        CloseIconButton {
                            dismiss()
                        }
                        .scaleEffect(isPad ? 1.0 : 0.8)
                    }
                    .padding(.horizontal, isPad ? 24 : 14)
                    .padding(.top, isPad ? 18 : 10)
                    .padding(.bottom, isPad ? 12 : 6)
                    
                    // Tab Picker
                    HStack(spacing: isPad ? 12 : 6) {
                        ForEach(TutorialTab.allCases) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: isPad ? 15 : 11, weight: .semibold))
                                    Text(tab.rawValue)
                                        .font(.system(size: isPad ? 16 : 12, weight: .bold, design: .rounded))
                                }
                                .padding(.horizontal, isPad ? 16 : 10)
                                .padding(.vertical, isPad ? 8 : 5)
                                .foregroundColor(selectedTab == tab ? .white : Color.darkBlue)
                                .background(
                                    Group {
                                        if selectedTab == tab {
                                            LinearGradient(
                                                colors: [Color(hex: "1E4BA3"), Color(hex: "00D2FF")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.white.opacity(0.7)
                                        }
                                    }
                                )
                                .clipShape(Capsule())
                                .shadow(color: selectedTab == tab ? Color.blue.opacity(0.3) : Color.clear, radius: 4)
                            }
                        }
                    }
                    .padding(.horizontal, isPad ? 20 : 10)
                    .padding(.bottom, isPad ? 12 : 6)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        tabTutorialContent(isPad: isPad, availableHeight: modalHeight - (isPad ? 120 : 80))
                            .tag(TutorialTab.tutorial)
                        
                        tabStandingContent(isPad: isPad, availableHeight: modalHeight - (isPad ? 120 : 80))
                            .tag(TutorialTab.standing)
                        
                        tabSittingContent(isPad: isPad, availableHeight: modalHeight - (isPad ? 120 : 80))
                            .tag(TutorialTab.sitting)
                        
                        tabFusionContent(isPad: isPad, availableHeight: modalHeight - (isPad ? 120 : 80))
                            .tag(TutorialTab.fusion)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .frame(width: modalWidth, height: modalHeight)
                .background(
                    RoundedRectangle(cornerRadius: isPad ? 24 : 16)
                        .fill(Color(hex: "F8FBFF"))
                        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
                )
            }
        }
    }
    
    // MARK: - Tab 1: Cara Bermain
    @ViewBuilder
    private func tabTutorialContent(isPad: Bool, availableHeight: CGFloat) -> some View {
        HStack(spacing: isPad ? 24 : 12) {
            Image("tutorial")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: availableHeight * 0.90)
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 16 : 10))
                .shadow(color: Color.black.opacity(0.08), radius: 6)
            
            VStack(alignment: .leading, spacing: isPad ? 12 : 6) {
                Text("Langkah Mudah Bermain:")
                    .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.darkBlue)
                
                stepItem(number: "1", text: "Pilih lagu favorit dan lihat urutan 5 gaya pose.", isPad: isPad)
                stepItem(number: "2", text: "Posisikan dirimu di depan kamera sesuai petunjuk.", isPad: isPad)
                stepItem(number: "3", text: "Tahan gaya pose saat hitung mundur 5 detik.", isPad: isPad)
                stepItem(number: "4", text: "Selesaikan mini game interaktif di antara pose!", isPad: isPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, isPad ? 16 : 8)
        }
        .padding(isPad ? 16 : 10)
    }
    
    // MARK: - Tab 2: Panduan Berdiri
    @ViewBuilder
    private func tabStandingContent(isPad: Bool, availableHeight: CGFloat) -> some View {
        HStack(spacing: isPad ? 24 : 14) {
            Image("standingGuide")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: availableHeight * 0.90)
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 16 : 10))
                .shadow(color: Color.black.opacity(0.08), radius: 6)
            
            VStack(alignment: .leading, spacing: isPad ? 12 : 6) {
                Text("Contoh Posisi Berdiri:")
                    .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.darkBlue)
                
                stepItem(number: "✓", text: "Pastikan seluruh tubuh atas hingga pinggang terlihat jelas.", isPad: isPad)
                stepItem(number: "✓", text: "Beri jarak sekitar 1.5 - 2 meter dari perangkat.", isPad: isPad)
                stepItem(number: "✓", text: "Pencahayaan ruangan cukup terang menghadap ke wajah.", isPad: isPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, isPad ? 16 : 8)
        }
        .padding(isPad ? 16 : 10)
    }
    
    // MARK: - Tab 3: Panduan Duduk
    @ViewBuilder
    private func tabSittingContent(isPad: Bool, availableHeight: CGFloat) -> some View {
        HStack(spacing: isPad ? 24 : 14) {
            Image("sittingGuide")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: availableHeight * 0.90)
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 16 : 10))
                .shadow(color: Color.black.opacity(0.08), radius: 6)
            
            VStack(alignment: .leading, spacing: isPad ? 12 : 6) {
                Text("Contoh Posisi Duduk:")
                    .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.darkBlue)
                
                stepItem(number: "✓", text: "Duduk tegak menghadap lurus ke arah kamera.", isPad: isPad)
                stepItem(number: "✓", text: "Pastikan kedua tangan bebas bergerak untuk mini game.", isPad: isPad)
                stepItem(number: "✓", text: "Letakkan iPad / iPhone di penyangga yang stabil.", isPad: isPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, isPad ? 16 : 8)
        }
        .padding(isPad ? 16 : 10)
    }
    
    // MARK: - Tab 4: Contoh Pose Fusion
    @ViewBuilder
    private func tabFusionContent(isPad: Bool, availableHeight: CGFloat) -> some View {
        HStack(spacing: isPad ? 24 : 14) {
            Image("fusion 550x500")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: availableHeight * 0.90)
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 16 : 10))
                .shadow(color: Color.black.opacity(0.08), radius: 6)
            
            VStack(alignment: .leading, spacing: isPad ? 12 : 6) {
                Text("Contoh Pose Bersama (Fusion):")
                    .font(.system(size: isPad ? 20 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.darkBlue)
                
                stepItem(number: "1", text: "Ajak teman atau pasanganmu berdiri berdampingan.", isPad: isPad)
                stepItem(number: "2", text: "Satukan jari telunjuk membentuk gaya ikonik Fusion!", isPad: isPad)
                stepItem(number: "3", text: "Tahan ekspresi ceria dan senyum ke arah kamera.", isPad: isPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, isPad ? 16 : 8)
        }
        .padding(isPad ? 16 : 10)
    }
    
    private func stepItem(number: String, text: String, isPad: Bool) -> some View {
        HStack(alignment: .top, spacing: isPad ? 10 : 6) {
            Text(number)
                .font(.system(size: isPad ? 14 : 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: isPad ? 24 : 17, height: isPad ? 24 : 17)
                .background(Circle().fill(Color.darkBlue))
            
            Text(text)
                .font(.system(size: isPad ? 16 : 11, weight: .medium))
                .foregroundColor(Color.black.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
