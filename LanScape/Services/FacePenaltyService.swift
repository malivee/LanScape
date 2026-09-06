//
//  FacePenaltyService.swift
//  LanScape
//

import UIKit
@preconcurrency import Vision
import SwiftUI
import Combine

enum FaceAnchor {
    case headTop
    case forehead
    case eyes
    case nose
    case mouth
    case chin
    case wholeFace
}

enum PenaltyStickerType: String, CaseIterable {
    // Top of head & hair
    case poop = "💩"
    case banana = "🍌"
    case clown = "🤡"
    case hairRolls = "🧑‍🦱"
    case bambooPropeller = "🚁"
    case trashCan = "🗑️"
    case riceBasket = "🍚"
    case pizzaHat = "🍕"
    case bigRibbon = "🎀"
    case dizzyBirds = "💫"
    
    // Forehead & eyebrows
    case bandage = "🩹"
    case coffeeStain = "☕"
    case legoEyebrow = "🧱"
    
    // Eyes
    case slippingGlasses = "👓"
    case snorkelGoggles = "🥽"
    case donutGlasses = "🍩"
    case frogEyes = "🐸"
    case spiralEyes = "🤪"
    
    // Nose
    case iceCreamNose = "🍦"
    case pigSnout = "🐷"
    
    // Mouth & Chin
    case babyPacifier = "🍼"
    case floatingDentures = "🦷"
    case satayStick = "🍢"
    case fishBone = "🐟"
    case duckLips = "🦆"
    case droolMouth = "🤤"
    case broccoliBeard = "🥦"
    
    // Cheeks & Whole Face
    case puffCheeks = "🥟"
    case crackerFace = "🍙"
    case catFace = "🐱"
    case crying = "😭"
    
    var title: String {
        switch self {
        case .poop: return "Kotoran Lucu"
        case .banana: return "Kulit Pisang Nemplok"
        case .clown: return "Hidung Badut & Kribo"
        case .hairRolls: return "Roll Rambut Emak"
        case .bambooPropeller: return "Baling-Baling Bambu"
        case .trashCan: return "Helm Tong Sampah"
        case .riceBasket: return "Topi Bakul Nasi"
        case .pizzaHat: return "Topi Potongan Pizza"
        case .bigRibbon: return "Pita Raksasa Pink"
        case .dizzyBirds: return "Burung & Bintang Pusing"
            
        case .bandage: return "Koyo Cabe di Dahi"
        case .coffeeStain: return "Cipratan Kopi Jadul"
        case .legoEyebrow: return "Balok Lego di Alis"
            
        case .slippingGlasses: return "Kacamata Melorot"
        case .snorkelGoggles: return "Kacamata Selam"
        case .donutGlasses: return "Kacamata Donat"
        case .frogEyes: return "Mata Kodok Melotot"
        case .spiralEyes: return "Mata Muter & Melet"
            
        case .iceCreamNose: return "Es Krim di Hidung"
        case .pigSnout: return "Hidung Babi Pink"
            
        case .babyPacifier: return "Dot Bayi Jumbo"
        case .floatingDentures: return "Gigi Palsu Melayang"
        case .satayStick: return "Tusuk Sate di Bibir"
        case .fishBone: return "Tulang Ikan Nyangkut"
        case .duckLips: return "Bibir Bebek Monyong"
        case .droolMouth: return "Mulut Ngiler"
        case .broccoliBeard: return "Jenggot Brokoli"
            
        case .puffCheeks: return "Pipi Bakpao"
        case .crackerFace: return "Kerupuk Kaleng Bundar"
        case .catFace: return "Kumis Kucing Pink"
        case .crying: return "Air Mata Banjir"
        }
    }
    
    var anchor: FaceAnchor {
        switch self {
        case .poop, .banana, .clown, .hairRolls, .bambooPropeller, .trashCan, .riceBasket, .pizzaHat, .bigRibbon, .dizzyBirds:
            return .headTop
        case .bandage, .coffeeStain, .legoEyebrow:
            return .forehead
        case .slippingGlasses, .snorkelGoggles, .donutGlasses, .frogEyes, .spiralEyes:
            return .eyes
        case .iceCreamNose, .pigSnout:
            return .nose
        case .babyPacifier, .floatingDentures, .satayStick, .fishBone, .duckLips, .droolMouth:
            return .mouth
        case .broccoliBeard:
            return .chin
        case .puffCheeks, .crackerFace, .catFace, .crying:
            return .wholeFace
        }
    }
    
    var yOffsetFactor: CGFloat {
        switch anchor {
        case .headTop: return -0.32
        case .forehead: return 0.05
        case .eyes: return 0.22
        case .nose: return 0.42
        case .mouth: return 0.68
        case .chin: return 0.88
        case .wholeFace: return 0.35
        }
    }
}

struct DetectedFacePenalty: Identifiable, Equatable {
    let id: Int
    var normalizedRect: CGRect // Vision coordinates: (0,0) at bottom-left
    var sticker: PenaltyStickerType
}

@MainActor
final class FacePenaltyService: ObservableObject {
    @Published var isPenaltyActive: Bool = false
    @Published var currentPenaltySticker: PenaltyStickerType = .banana
    @Published var detectedFaces: [DetectedFacePenalty] = []
    
    nonisolated(unsafe) private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    private var isProcessing = false
    private var smoothedRects: [Int: CGRect] = [:]
    
    func activatePenalty(sticker: PenaltyStickerType? = nil) {
        isPenaltyActive = true
        if let sticker = sticker {
            currentPenaltySticker = sticker
        } else {
            currentPenaltySticker = PenaltyStickerType.allCases.randomElement() ?? .banana
        }
    }
    
    func clearPenalty() {
        isPenaltyActive = false
        detectedFaces.removeAll()
        smoothedRects.removeAll()
    }
    
    private func smooth(target: CGRect, for index: Int, factor: CGFloat = 0.35) -> CGRect {
        guard let current = smoothedRects[index] else {
            smoothedRects[index] = target
            return target
        }
        let smoothed = CGRect(
            x: current.origin.x + (target.origin.x - current.origin.x) * factor,
            y: current.origin.y + (target.origin.y - current.origin.y) * factor,
            width: current.width + (target.width - current.width) * factor,
            height: current.height + (target.height - current.height) * factor
        )
        smoothedRects[index] = smoothed
        return smoothed
    }
    
    private var lastFaceDetectionTime: Date = .distantPast
    
    /// Detect faces from live camera pixel buffer to position stickers over live faces
    func processLiveBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard isPenaltyActive, !isProcessing else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastFaceDetectionTime) >= 0.08 else { return }
        lastFaceDetectionTime = now
        isProcessing = true
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            do {
                try requestHandler.perform([self.faceDetectionRequest])
                let results = self.faceDetectionRequest.results ?? []
                
                Task { @MainActor in
                    self.isProcessing = false
                    if results.isEmpty {
                        // Smooth fallback default face locations for two players if no faces detected
                        let r0 = self.smooth(target: CGRect(x: 0.20, y: 0.45, width: 0.20, height: 0.25), for: 0)
                        let r1 = self.smooth(target: CGRect(x: 0.60, y: 0.45, width: 0.20, height: 0.25), for: 1)
                        self.detectedFaces = [
                            DetectedFacePenalty(id: 0, normalizedRect: r0, sticker: self.currentPenaltySticker),
                            DetectedFacePenalty(id: 1, normalizedRect: r1, sticker: self.currentPenaltySticker)
                        ]
                    } else {
                        self.detectedFaces = results.enumerated().map { index, observation in
                            let smoothed = self.smooth(target: observation.boundingBox, for: index)
                            return DetectedFacePenalty(
                                id: index,
                                normalizedRect: smoothed,
                                sticker: self.currentPenaltySticker
                            )
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    /// Bake penalty stickers directly onto the captured UIImage (Background Rendered)
    func bakePenaltyOntoImageAsync(_ sourceImage: UIImage) async -> UIImage {
        guard isPenaltyActive else { return sourceImage }
        let sticker = currentPenaltySticker
        
        return await Task.detached(priority: .userInitiated) {
            Self.renderPenalty(on: sourceImage, sticker: sticker)
        }.value
    }

    /// Bake penalty stickers directly onto the captured UIImage (Synchronous fallback)
    func bakePenaltyOntoImage(_ sourceImage: UIImage) -> UIImage {
        guard isPenaltyActive else { return sourceImage }
        return Self.renderPenalty(on: sourceImage, sticker: currentPenaltySticker)
    }

    /// Non-isolated static renderer ensuring 100% background thread execution
    nonisolated static func renderPenalty(on sourceImage: UIImage, sticker: PenaltyStickerType) -> UIImage {
        let normalizedSource = sourceImage.normalizedUp()
        guard let cgImage = normalizedSource.cgImage else { return sourceImage }
        
        // Detect faces on this high-res upright image
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try? handler.perform([request])
        
        var faceRects: [CGRect] = []
        if let observations = request.results, !observations.isEmpty {
            faceRects = observations.map { $0.boundingBox }
        } else {
            // Default dual-person fallback
            faceRects = [
                CGRect(x: 0.20, y: 0.45, width: 0.22, height: 0.25),
                CGRect(x: 0.60, y: 0.45, width: 0.22, height: 0.25)
            ]
        }
        
        let imgSize = sourceImage.size
        let renderer = UIGraphicsImageRenderer(size: imgSize)
        
        let stickeredImage = renderer.image { context in
            // Draw original photo
            sourceImage.draw(at: .zero)
            
            // Draw penalty stickers over detected faces
            for rect in faceRects {
                let faceX = rect.origin.x * imgSize.width
                let faceY = (1.0 - rect.origin.y - rect.height) * imgSize.height
                let faceW = rect.width * imgSize.width
                let faceH = rect.height * imgSize.height
                
                let stickerText = sticker.rawValue
                let fontSize = max(60, faceW * 1.1)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize)
                ]
                let attrString = NSAttributedString(string: stickerText, attributes: attributes)
                let stringSize = attrString.size()
                
                let drawX = faceX + (faceW - stringSize.width) / 2
                let drawY = faceY + (faceH * sticker.yOffsetFactor) - (stringSize.height / 2)
                
                attrString.draw(at: CGPoint(x: drawX, y: drawY))
            }
        }
        
        return stickeredImage
    }
}
