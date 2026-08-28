import SwiftUI

struct MovementItemCard: View {
    let imageName: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 160)
            
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.lightBlue)
        .clipShape(.rect(cornerRadius: 20))
    }
}

#Preview("Movement Item Card") {
    ZStack {
        Color.blue.opacity(0.2).ignoresSafeArea()
        MovementItemCard(imageName: "Mountain Pose", title: "Mountain Pose")
            .padding()
    }
}
