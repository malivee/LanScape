//
//  MiniGameCatalog.swift
//  LanScape
//

import SwiftUI

enum MiniGameSensorType: Equatable {
    case audioClap
    case audioVoice
    case visionHands
    case visionMotion
    case visionFace
    case touchFallback
}

enum MiniGameID: String, CaseIterable, Identifiable, Equatable {
    // 3 Existing Core Games (screamMeter removed)
    case handClap = "hand_clap"
    case fastTap = "fast_tap"
    case fastMove = "fast_move"
    
    // 12 Additional Cooperative Games (Total: 15 Highly-Polished Games)
    case sayILoveYou = "say_i_love_you"
    case fanSmoke = "fan_smoke"
    case waveHello = "wave_hello"
    case doubleThumbsUp = "double_thumbs_up"
    case batteryHug = "battery_hug"
    case gentleHeadPat = "gentle_head_pat"
    case fishLips = "fish_lips"
    case mouthOpen = "mouth_open"
    case blowCandle = "blow_candle"
    case laughOutLoud = "laugh_out_loud"
    case sleepyPose = "sleepy_pose"
    case gentleHighFive = "gentle_high_five"
    
    var id: String { rawValue }
}

struct MiniGameMetadata: Equatable, Identifiable {
    let id: MiniGameID
    let title: String
    let icon: String
    let sfSymbol: String
    let tutorialInstruction: String
    let tutorialTip: String
    let actionPrompt: String
    let cheerText: String
    let fallbackButtonText: String
    let sensorType: MiniGameSensorType
    let durationSeconds: Int
}

struct MiniGameCatalog {
    static let allGames: [MiniGameID: MiniGameMetadata] = [
        // 1. Tepuk Tangan
        .handClap: MiniGameMetadata(
            id: .handClap,
            title: "Tepuk Tangan Bersama",
            icon: "👏",
            sfSymbol: "hands.clap.fill",
            tutorialInstruction: "Kakek & Cucu kompak tepuk tangan bersama di depan kamera!",
            tutorialTip: "Tepuk tangan dengan ceria sampai meteran penuh!",
            actionPrompt: "AYO TEPUK TANGAN BERSAMA!",
            cheerText: "LETSGOOO...!!!",
            fallbackButtonText: "Tepuk Tombol",
            sensorType: .audioClap,
            durationSeconds: 10
        ),
        // 2. Sentuh Target Layar
        .fastTap: MiniGameMetadata(
            id: .fastTap,
            title: "Sentuh Target Layar",
            icon: "✋",
            sfSymbol: "target",
            tutorialInstruction: "Kakek & Cucu sentuh tombol bercahaya di layar!",
            tutorialTip: "Cukup sentuh tombol biru di tengah layar bersama-sama!",
            actionPrompt: "AYO SENTUH TOMBOL SEKARANG!",
            cheerText: "HEBAT BANGET!",
            fallbackButtonText: "Sentuh Cepat",
            sensorType: .touchFallback,
            durationSeconds: 10
        ),
        // 4. Goyang Badan Santai
        .fastMove: MiniGameMetadata(
            id: .fastMove,
            title: "Goyang Badan Santai",
            icon: "🏃",
            sfSymbol: "figure.walk.motion",
            tutorialInstruction: "Kakek & Cucu kompak gerakkan badan atau lambaikan tangan!",
            tutorialTip: "Goyang badan santai tanpa perlu terburu-buru!",
            actionPrompt: "AYO GOYANG BADAN SANTAI!",
            cheerText: "LURUSKAN GAYA!",
            fallbackButtonText: "Goyang Layar",
            sensorType: .visionMotion,
            durationSeconds: 10
        ),
        // 5. Katakan "I Love You!"
        .sayILoveYou: MiniGameMetadata(
            id: .sayILoveYou,
            title: "Katakan 'I Love You!'",
            icon: "❤️",
            sfSymbol: "heart.fill",
            tutorialInstruction: "Kakek & Cucu ucapkan 'I Love You!' atau 'Aku Sayang Kamu!' bersama!",
            tutorialTip: "Suara hangat kalian akan memunculkan hujan hati di layar!",
            actionPrompt: "UCAPKAN 'I LOVE YOU' SEKARANG!",
            cheerText: "SO SWEET BANGET...!",
            fallbackButtonText: "Kirim Hati",
            sensorType: .audioVoice,
            durationSeconds: 10
        ),
        // 6. Kipas Sate / Buang Asap!
        .fanSmoke: MiniGameMetadata(
            id: .fanSmoke,
            title: "Kipas Sate / Buang Asap!",
            icon: "🍢",
            sfSymbol: "wind",
            tutorialInstruction: "Kompak gerakkan tangan naik-turun seperti mengipasi asap sate!",
            tutorialTip: "Kipas asap tebal di layar sampai satenya matang lezat!",
            actionPrompt: "AYO KIPAS-KIPAS TANGAN NAIK TURUN!",
            cheerText: "ASAPNYA SUDAH HILANG!",
            fallbackButtonText: "Kipas Layar",
            sensorType: .visionHands,
            durationSeconds: 12
        ),
        // 7. Lambaikan Tangan Ceria
        .waveHello: MiniGameMetadata(
            id: .waveHello,
            title: "Lambaikan Tangan Ceria",
            icon: "👋",
            sfSymbol: "hand.wave.fill",
            tutorialInstruction: "Kakek & Cucu lambaikan tangan bersama menyapa kamera 'Halo!'",
            tutorialTip: "Bintang-bintang berkilauan akan mengikuti lambaian tangan kalian!",
            actionPrompt: "AYO LAMBAIKAN TANGAN KE KAMERA!",
            cheerText: "HALOO SEMUANYA!",
            fallbackButtonText: "Lambaikan Tangan",
            sensorType: .visionHands,
            durationSeconds: 10
        ),
        // 8. Dua Jempol Kompak
        .doubleThumbsUp: MiniGameMetadata(
            id: .doubleThumbsUp,
            title: "Dua Jempol Kompak",
            icon: "👍",
            sfSymbol: "hand.thumbsup.fill",
            tutorialInstruction: "Kakek & Cucu kompak acungkan jempol mantap ke kamera!",
            tutorialTip: "Acungkan jempol ke depan kamera sampai kembang api emas meletup!",
            actionPrompt: "ACUNGKAN JEMPOL MANTAP!",
            cheerText: "MANTAP SEKALI!",
            fallbackButtonText: "Beri Jempol",
            sensorType: .visionHands,
            durationSeconds: 10
        ),
        // 10. Pelukan Cas Baterai
        .batteryHug: MiniGameMetadata(
            id: .batteryHug,
            title: "Pelukan Cas Baterai",
            icon: "🔋",
            sfSymbol: "battery.100.bolt",
            tutorialInstruction: "Kakek & Cucu saling merangkul bahu menghadap kamera!",
            tutorialTip: "Pelukan hangat kalian akan mengecas baterai cinta sampai 100%!",
            actionPrompt: "RANGKUL BAHU SEKARANG!",
            cheerText: "BATERAI PENUH 100%!",
            fallbackButtonText: "Cas Baterai",
            sensorType: .visionFace,
            durationSeconds: 10
        ),
        // 11. Elus Kepala Sayang
        .gentleHeadPat: MiniGameMetadata(
            id: .gentleHeadPat,
            title: "Elus Kepala Sayang",
            icon: "👧",
            sfSymbol: "hand.raised.fingers.spread.fill",
            tutorialInstruction: "Kakek/Nenek letakkan tangan di atas kepala cucu dengan santai!",
            tutorialTip: "Bunga-bunga virtual akan bermekaran merespons elusan sayang!",
            actionPrompt: "ELUS KEPALA DENGAN LEMBUT!",
            cheerText: "BUNGA BERMEKARAN!",
            fallbackButtonText: "Elus Kepala",
            sensorType: .visionHands,
            durationSeconds: 10
        ),
        // 14. Monyong Bibir Ikan
        .fishLips: MiniGameMetadata(
            id: .fishLips,
            title: "Monyong Bibir Ikan",
            icon: "🐠",
            sfSymbol: "mouth.fill",
            tutorialInstruction: "Kakek & Cucu kompak memonyongkan bibir santai ke kamera!",
            tutorialTip: "Gelembung-gelembung air kartun lucu akan keluar dari mulut!",
            actionPrompt: "AYO MONYONGKAN BIBIR BERSAMA!",
            cheerText: "GELEMBUNG KELUAR SEMUA!",
            fallbackButtonText: "Monyong Bibir",
            sensorType: .visionFace,
            durationSeconds: 10
        ),
        // 15. Buka Mulut Kagum 'O'
        .mouthOpen: MiniGameMetadata(
            id: .mouthOpen,
            title: "Buka Mulut Kagum 'O'",
            icon: "😮",
            sfSymbol: "face.smiling.inverse",
            tutorialInstruction: "Buka mulut bersama membentuk huruf 'O' seolah melihat kembang api!",
            tutorialTip: "Kembang api warna-warni yang meriah akan meluncur di layar!",
            actionPrompt: "BUKA MULUT 'WAAAH' SEKARANG!",
            cheerText: "KEMBANG API MELETUP!",
            fallbackButtonText: "Buka Mulut",
            sensorType: .visionFace,
            durationSeconds: 10
        ),
        // 17. Tiup Lilin Ulang Tahun
        .blowCandle: MiniGameMetadata(
            id: .blowCandle,
            title: "Tiup Lilin Ulang Tahun",
            icon: "🎂",
            sfSymbol: "flame.fill",
            tutorialInstruction: "Kakek & Cucu tiup santai ke arah mikrofon sampai api lilin padam!",
            tutorialTip: "Tiup mikrofon seperti meniup lilin kue ulang tahun!",
            actionPrompt: "TIUP LILIN BERSAMA-SAMA!",
            cheerText: "HUUFFF... LILIN PADAM!",
            fallbackButtonText: "Tiup Lilin",
            sensorType: .audioVoice,
            durationSeconds: 10
        ),
        // 18. Tawa Ceria 'Hahaha!'
        .laughOutLoud: MiniGameMetadata(
            id: .laughOutLoud,
            title: "Tawa Ceria 'Hahaha!'",
            icon: "😆",
            sfSymbol: "face.smiling.fill",
            tutorialInstruction: "Kompak tertawa ceria bersama 'Hahaha!' di depan kamera!",
            tutorialTip: "Suara tawa kalian akan memecahkan gelembung sabun raksasa di layar!",
            actionPrompt: "TERTAWA 'HAHAHA' BERSAMA!",
            cheerText: "TAWA PALING CERIA!",
            fallbackButtonText: "Ketawa Bareng",
            sensorType: .audioVoice,
            durationSeconds: 10
        ),
        // 19. Pose Bobo Nyenyak
        .sleepyPose: MiniGameMetadata(
            id: .sleepyPose,
            title: "Pose Bobo Nyenyak",
            icon: "😴",
            sfSymbol: "moon.zzz.fill",
            tutorialInstruction: "Satukan kedua telapak tangan di samping pipi sambil memejamkan mata!",
            tutorialTip: "Bulan sabit dan animasi 'Zzzz' lucu akan melayang di atas kalian!",
            actionPrompt: "TEMPEL TANGAN DI PIPI: 'ZZZZ'!",
            cheerText: "TIDUR NYENYAK SEKALI!",
            fallbackButtonText: "Pose Bobo",
            sensorType: .visionHands,
            durationSeconds: 10
        ),
        // 20. Tosss Kompak!
        .gentleHighFive: MiniGameMetadata(
            id: .gentleHighFive,
            title: "Tosss Kompak!",
            icon: "✋",
            sfSymbol: "hand.raised.fill",
            tutorialInstruction: "Kakek & Cucu angkat telapak tangan terbuka berdampingan ke kamera!",
            tutorialTip: "Angkat tangan santai ke depan kamera untuk tos virtual bersama!",
            actionPrompt: "ANGKAT TANGAN BERSAMA BUAT TOSS!",
            cheerText: "TOSSS BERHASIL!",
            fallbackButtonText: "Tosss Layar",
            sensorType: .visionHands,
            durationSeconds: 10
        )
    ]
    
    /// Select `count` random unique mini games for the photo session
    static func selectRandomChallenges(count: Int = 4) -> [MiniGameMetadata] {
        let allKeys = MiniGameID.allCases.shuffled()
        let selectedKeys = Array(allKeys.prefix(count))
        return selectedKeys.compactMap { allGames[$0] }
    }
}
