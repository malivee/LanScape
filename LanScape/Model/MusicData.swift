import SwiftUI

struct MusicData: Identifiable {
    let id = UUID()
    var image: ImageResource // Pastikan gambar .jarangPulang ada di Assets
    var title: String
    var duration: String
    var moves: String
}

extension MusicData {
    static let sample: [MusicData] = [
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5"),
        .init(image: .jarangPulang, title: "Jarang Pulang", duration: "30", moves: "5")
    ]
}
