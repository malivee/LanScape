//
//  FacePenaltyService.swift
//  LanScape
//

import UIKit
@preconcurrency import Vision
import SwiftUI
import Combine

enum PenaltyStickerType: String, CaseIterable {
    case banana = "🍌"
    case trashCan = "🗑️"
    case fishBone = "🐟"
    case poop = "💩"
    case clown = "🤡"
    case crying = "😭"
    case rottenBroccoli = "🥦"
    
    var title: String {
        switch self {
        case .banana: return "Kulit Pisang"
        case .trashCan: return "Tong Sampah"
        case .fishBone: return "Tulang Ikan"
        case .poop: return "Kotoran Lucu"
        case .clown: return "Muka Badut"
        case .crying: return "Ekspresi Nangis"
        case .rottenBroccoli: return "Sayur Basi"
        }
    }
}

struct DetectedFacePenalty: Identifiable, Equatable {
    let id: UUID = UUID()
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
                        // Fallback default face locations for two players if no faces detected
                        self.detectedFaces = [
                            DetectedFacePenalty(
                                normalizedRect: CGRect(x: 0.20, y: 0.45, width: 0.20, height: 0.25),
                                sticker: self.currentPenaltySticker
                            ),
                            DetectedFacePenalty(
                                normalizedRect: CGRect(x: 0.60, y: 0.45, width: 0.20, height: 0.25),
                                sticker: self.currentPenaltySticker
                            )
                        ]
                    } else {
                        self.detectedFaces = results.map { observation in
                            DetectedFacePenalty(
                                normalizedRect: observation.boundingBox,
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
    
    /// Bake penalty stickers directly onto the captured UIImage
    func bakePenaltyOntoImage(_ sourceImage: UIImage) -> UIImage {
        guard isPenaltyActive else { return sourceImage }
        
        guard let cgImage = sourceImage.cgImage else { return sourceImage }
        
        // Detect faces on this high-res image
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
                // Vision has origin (0,0) at bottom-left, UIImage has (0,0) at top-left
                let faceX = rect.origin.x * imgSize.width
                let faceY = (1.0 - rect.origin.y - rect.height) * imgSize.height
                let faceW = rect.width * imgSize.width
                let faceH = rect.height * imgSize.height
                
                // Draw trash/emotion emoji centered on forehead/face
                let stickerText = currentPenaltySticker.rawValue
                let fontSize = max(60, faceW * 1.1)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize)
                ]
                let attrString = NSAttributedString(string: stickerText, attributes: attributes)
                let stringSize = attrString.size()
                
                let drawX = faceX + (faceW - stringSize.width) / 2
                let drawY = faceY + (faceH - stringSize.height) / 2 - (faceH * 0.15)
                
                attrString.draw(at: CGPoint(x: drawX, y: drawY))
            }
        }
        
        return stickeredImage
    }
}
