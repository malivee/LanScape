import SwiftUI

struct ScoreView: View {
    var music: MusicData = MusicData.sample[0]
    var scoreBerhasil: Int = 3
    var scoreTerlewat: Int = 2
    
    var body: some View {
        ZStack{
            Image("dummyBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack (spacing: 40){
                ZStack{
                    // Yang text SCORE ini masih pake AI mweheh
                    // Layer 1
                    Text("SCORE")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                    // Move text to create outline/stroke
                        .offset(x: -2, y: -2)
                        .background(Text("SCORE").font(.system(size: 80, weight: .bold)).foregroundColor(.white).offset(x: 2, y: -2))
                        .background(Text("SCORE").font(.system(size: 80, weight: .bold)).foregroundColor(.white).offset(x: -2, y: 2))
                        .background(Text("SCORE").font(.system(size: 80, weight: .bold)).foregroundColor(.white).offset(x: 2, y: 2))
                    // White Glow
                        .shadow(color: Color.white.opacity(0.25), radius: 8, x: 0, y: 0)
                    // Black Drop Shadow
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    
                    // Layer 2
                    Text("SCORE")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(Color(red: 56/255, green: 124/255, blue: 255/255))
                }
                
                
                HStack (spacing: 40){
                    MusicCardView(
                        music: music,
                        isSelected: false
                    )
                    
                    
                    ZStack{
                        VStack (spacing: 60){
                            HStack (alignment: .center, spacing: 300){
                                Text("Berhasil")
                                    .font(.system(size: 38, weight: .bold))
                                
                                Text("\(scoreBerhasil)")
                                    .font(Font.system(size: 44, weight: .bold))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.5))
                            
                            HStack (alignment: .center, spacing: 300){
                                Text("Terlewat")
                                    .font(.system(size: 38, weight: .bold))
                                
                                Text("\(scoreTerlewat)")
                                    .font(Font.system(size: 44, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(width: 650, height: 360)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.black.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.white.opacity(0.15), radius: 8, x: 0, y: 0)
                        
                    }
                }
                
                HStack (spacing: 40) {
                    ScoreActionButton(title: "Ulangi", systemIcon: "arrow.counterclockwise"){
                        
                    }
                    ScoreActionButton(title: "Menu Utama", systemIcon: "house.fill"){
                        
                    }
                    ScoreActionButton(title: "Pilih Lagu", systemIcon: "play.fill", action:  {
                        
                    }, isPrimary: true)
                }
            }
        }
    }
}

struct ScoreActionButton: View {
    let title: String
    let systemIcon: String
    let action: () -> Void
    
    var isPrimary: Bool = false
    private let buttonCornerRadius: CGFloat = 50
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemIcon)
                .font(.largeTitle.bold())
                .frame(width: 320)
                .frame(height: 80)
                .foregroundStyle(.white)
                .background{
                    if isPrimary {
                        // Gaya Gradasi Khusus "Pilih Lagu"
                        LinearGradient(
                            colors: [
                                .gradient1,
                                .gradient2,
                                .gradient3
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Gaya Asli untuk "Ulangi" & "Menu Utama"
                        Color.darkBlue.opacity(0.8)
                    }
                }
                .overlay {
                    if isPrimary {
                        Color.clear
                    } else {
                        RoundedRectangle(cornerRadius: buttonCornerRadius)
                            .stroke(Color.white, lineWidth: 2)
                    }
                }
                .glassEffect()
                .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius))
        }
    }
}

#Preview {
    ScoreView()
}
