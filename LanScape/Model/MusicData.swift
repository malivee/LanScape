import SwiftUI

struct MusicData: Identifiable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var assetName: String
    var duration: String
    var moves: String
    var coverImageName: String?
    var coverColors: [Color]
    var coverIcon: String
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "",
        assetName: String,
        duration: String = "30s",
        moves: String = "4",
        coverImageName: String? = nil,
        coverColors: [Color] = [Color.blue, Color.cyan],
        coverIcon: String = "music.note"
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.assetName = assetName
        self.duration = duration
        self.moves = moves
        self.coverImageName = coverImageName
        self.coverColors = coverColors
        self.coverIcon = coverIcon
    }
}

extension MusicData {
    static let sample: [MusicData] = [
        MusicData(
            title: "Jarang Pulang",
            artist: "Lagu Populer",
            assetName: "JarangPulang.mp3",
            duration: "30s",
            moves: "5",
            coverImageName: "Jarang Pulang",
            coverColors: [Color(hex: "1E4BA3"), Color(hex: "00D2FF")],
            coverIcon: "house.fill"
        ),
        MusicData(
            title: "Bubble Gum",
            artist: "NewJeans",
            assetName: "BubbleGum",
            duration: "35s",
            moves: "5",
            coverImageName: "BubbleGumimg",
            coverColors: [Color(hex: "FF758C"), Color(hex: "FF7EB3")],
            coverIcon: "bubbles.and.sparkles.fill"
        ),
        MusicData(
            title: "Golden",
            artist: "Huntrix",
            assetName: "Golden",
            duration: "40s",
            moves: "5",
            coverImageName: "Goldenimg",
            coverColors: [Color(hex: "F7971E"), Color(hex: "FFD200")],
            coverIcon: "sparkles"
        ),
        MusicData(
            title: "Yang Penting Hepi",
            artist: "Jamal Mirdad",
            assetName: "Happy",
            duration: "30s",
            moves: "5",
            coverImageName: "Happyimg",
            coverColors: [Color(hex: "00B09B"), Color(hex: "96C93D")],
            coverIcon: "face.smiling.fill"
        ),
        MusicData(
            title: "Bole Chudiyan",
            artist: "K3G Bollywood",
            assetName: "BoleChudiyan",
            duration: "45s",
            moves: "5",
            coverImageName: "BoleChudiyanimg",
            coverColors: [Color(hex: "EB3349"), Color(hex: "F45C43")],
            coverIcon: "music.note"
        )
    ]
}
