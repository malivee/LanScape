import SwiftUI

struct DotPageIndicator: View {
    let totalPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    
                    .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                    .frame(
                        width: currentPage == index ? 10 : 7,
                        height: currentPage == index ? 10 : 7
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview("Dot Indicator") {
    DotPageIndicator(totalPages: 6, currentPage: 1)
}
