import SwiftUI
import Combine

struct HitMark: View {
    var themeColor: Color
    var progress: CGFloat
    var size: CGFloat = 120
    
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(themeColor)
                    .frame(width: size * 0.8, height: size * 0.8)
                    .blur(radius: size * 0.1)
                    .shadow(color: themeColor, radius: size * 0.15)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .shadow(color: Color.white.opacity(0.8), radius: size * 0.05)
            }
            
            Circle()
                .trim(from: 0.0, to: min(max(progress, 0.0), 1.0))
                .stroke(
                    themeColor.opacity(0.9),
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: themeColor.opacity(0.7), radius: size * 0.1, x: 0, y: 0)
                .animation(.linear(duration: 0.05), value: progress)
        }
        .background(
            Circle()
                .fill(themeColor.opacity(0.08))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.3)
        )
        .padding()
    }
}

struct HitMark_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var currentProgress: CGFloat = 0.0
        let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
        
        var body: some View {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()
                
                HitMark(
                    themeColor: Color(hex: "0088FF"),
                    progress: currentProgress,
                    size: 150
                )
            }
            .onReceive(timer) { _ in
                if currentProgress >= 1.0 {
                    currentProgress = 0.0
                } else {
                    currentProgress += 0.01
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
