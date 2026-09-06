import SwiftUI

struct MovementItemCard: View {
    let imageName: String
    let title: String
    var imageHeight: CGFloat = 160
    var titleFontSize: CGFloat = 24
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: imageHeight)
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: titleFontSize * 0.8))
                        .foregroundColor(Color.darkBlue.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, imageHeight < 100 ? 8 : 14)
            .padding(.horizontal, 8)
            .background(Color.lightBlue)
            .clipShape(.rect(cornerRadius: imageHeight < 100 ? 14 : 20))
            .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Movement Item Card") {
    ZStack {
        Color.blue.opacity(0.2).ignoresSafeArea()
        MovementItemCard(imageName: "pose 1", title: "Pose Pertama")
            .padding()
    }
}
