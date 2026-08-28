import SwiftUI

struct CloseIconButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 30))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .background(Color.white.opacity(0.5))
        .clipShape(Circle())
        .padding(10)
    }
}

#Preview("Close Button") {
    CloseIconButton(action: {})
        .padding()
        .background(Color.gray)
}
