//
//  AppPreloadService.swift
//  LanScape
//

import UIKit
import Vision

@MainActor
final class AppPreloadService {
    static let shared = AppPreloadService()
    
    private var isPreloaded = false
    
    private init() {}
    
    func preloadAll() {
        guard !isPreloaded else { return }
        isPreloaded = true
        
        // 1. Preload and decode all songs in background
        BackgroundMusicService.shared.preloadAllSongs()
        
        // 2. Preload and warm up Camera & GPU pipeline
        CameraService.shared.warmUp()
        
        // 3. Preload all Pose & UI images and warm up Vision models in background
        DispatchQueue.global(qos: .userInitiated).async {
            let assetNames = [
                "BoleChudiyan1", "BoleChudiyan2", "BoleChudiyan3", "BoleChudiyan4", "BoleChudiyan5",
                "Golden1", "Golden2", "Golden3", "Golden4", "Golden5",
                "ILoveYou1", "ILoveYou2", "ILoveYou3", "ILoveYou4", "ILoveYou5",
                "JarangPulang1", "JarangPulang2", "JarangPulang3", "JarangPulang4", "JarangPulang5",
                "YangPentingHappy1", "YangPentingHappy2", "YangPentingHappy3", "YangPentingHappy4", "YangPentingHappy5",
                "BoleChudiyanimg", "Goldenimg", "Happyimg", "ILoveYouimg", "JarangPulangimg",
                "pose 1", "pose2", "pose3", "pose4", "pose5",
                "logoApp", "markHaechan", "tutorial", "standingGuide",
                "sittingGuide", "fusion 550x500"
            ]
            
            for name in assetNames {
                if let image = UIImage(named: name) {
                    // Force background decompression of bitmap so first render has zero lag
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
                    _ = renderer.image { _ in
                        image.draw(at: .zero)
                    }
                }
            }
            
            // 4. Preload & compile Vision neural pipeline in background
            let dummyFaceRequest = VNDetectFaceRectanglesRequest()
            let dummyHandRequest = VNDetectHumanHandPoseRequest()
            let dummyBodyRequest = VNDetectHumanBodyPoseRequest()
            let dummyImage = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
            if let cgImage = dummyImage.cgImage {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([dummyFaceRequest, dummyHandRequest, dummyBodyRequest])
            }
        }
    }
}
