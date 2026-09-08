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
    var poseImages: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "",
        assetName: String,
        duration: String = "30s",
        moves: String = "5",
        coverImageName: String? = nil,
        coverColors: [Color] = [Color.blue, Color.cyan],
        coverIcon: String = "music.note",
        poseImages: [String] = []
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
        self.poseImages = poseImages
    }
    
    func poseImageName(for movementNumber: Int) -> String {
        guard !poseImages.isEmpty else {
            return "pose\(movementNumber)"
        }
        let index = max(0, min(movementNumber - 1, poseImages.count - 1))
        return poseImages[index]
    }
}

extension MusicData {
    static let sample: [MusicData] = [
        MusicData(
            title: "Jarang Pulang",
            artist: "Lagu Populer",
            assetName: "JarangPulang",
            duration: "30s",
            moves: "5",
            coverImageName: "JarangPulangimg",
            coverColors: [Color(hex: "1E4BA3"), Color(hex: "00D2FF")],
            coverIcon: "house.fill",
            poseImages: [
                "JarangPulang1",
                "JarangPulang2",
                "JarangPulang3",
                "JarangPulang4",
                "JarangPulang5"
            ]
        ),
        MusicData(
            title: "Golden",
            artist: "Huntrix",
            assetName: "Golden",
            duration: "40s",
            moves: "5",
            coverImageName: "Goldenimg",
            coverColors: [Color(hex: "F7971E"), Color(hex: "FFD200")],
            coverIcon: "sparkles",
            poseImages: [
                "Golden1",
                "Golden2",
                "Golden3",
                "Golden4",
                "Golden5"
            ]
        ),
        MusicData(
            title: "Yang Penting Hepi",
            artist: "Jamal Mirdad",
            assetName: "Happy",
            duration: "30s",
            moves: "5",
            coverImageName: "Happyimg",
            coverColors: [Color(hex: "00B09B"), Color(hex: "96C93D")],
            coverIcon: "face.smiling.fill",
            poseImages: [
                "YangPentingHappy1",
                "YangPentingHappy2",
                "YangPentingHappy3",
                "YangPentingHappy4",
                "YangPentingHappy5"
            ]
        ),
        MusicData(
            title: "Bole Chudiyan",
            artist: "K3G Bollywood",
            assetName: "BoleChudiyan",
            duration: "45s",
            moves: "5",
            coverImageName: "BoleChudiyanimg",
            coverColors: [Color(hex: "EB3349"), Color(hex: "F45C43")],
            coverIcon: "music.note",
            poseImages: [
                "BoleChudiyan1",
                "BoleChudiyan2",
                "BoleChudiyan3",
                "BoleChudiyan4",
                "BoleChudiyan5"
            ]
        ),
        MusicData(
            title: "I Love You",
            artist: "NPD",
            assetName: "ILoveYou",
            duration: "35s",
            moves: "5",
            coverImageName: "ILoveYouimg",
            coverColors: [Color(hex: "FF758C"), Color(hex: "FF7EB3")],
            coverIcon: "heart.fill",
            poseImages: [
                "ILoveYou1",
                "ILoveYou2",
                "ILoveYou3",
                "ILoveYou4",
                "ILoveYou5"
            ]
        )
    ]
}
