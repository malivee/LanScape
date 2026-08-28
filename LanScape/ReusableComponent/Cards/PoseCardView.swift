import SwiftUI

struct PoseCardView: View {
    
    var title: String
    var imageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(UIColor.lightGray))
            
            
            ZStack {
               
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.25, green: 0.25, blue: 0.27))
                
               
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
            }
            .frame(width: 260, height: 180)
        }
    }
}


#Preview {
    ZStack {
        
        Color.black.ignoresSafeArea()
        PoseCardView(title: "Frame 13", imageName: "pose 1")
    }
}
