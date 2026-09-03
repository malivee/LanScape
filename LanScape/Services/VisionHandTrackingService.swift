//
//  VisionHandTrackingService.swift
//  LanScape
//

import UIKit
@preconcurrency import Vision
import Combine

@MainActor
final class VisionHandTrackingService: ObservableObject {
    /// Normalized coordinates of detected hand tips / palms (Vision coordinates: 0,0 bottom-left to 1,1 top-right)
    @Published var detectedHandPoints: [CGPoint] = []
    
    var isTrackingActive: Bool = false
    var onVisionClapDetected: (() -> Void)?
    
    private let processingQueue = DispatchQueue(label: "visionHandTrackingQueue", qos: .userInteractive)
    private var isProcessing = false
    private var lastFrameTime: Date = .distantPast
    
    // Persistent reusable requests
    nonisolated(unsafe) private let handRequest: VNDetectHumanHandPoseRequest = {
        let req = VNDetectHumanHandPoseRequest()
        req.maximumHandCount = 2
        return req
    }()
    nonisolated(unsafe) private let bodyRequest = VNDetectHumanBodyPoseRequest()
    
    // Clap detection state
    private var handsWereApart = true
    private var lastClapTime: Date = .distantPast
    private let clapCooldown: TimeInterval = 0.22
    
    func reset() {
        isTrackingActive = false
        detectedHandPoints.removeAll()
        handsWereApart = true
        isProcessing = false
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard isTrackingActive, !isProcessing else { return }
        
        // Throttle to max 25 FPS to preserve 100% smooth UI render pipeline
        let now = Date()
        guard now.timeIntervalSince(lastFrameTime) >= 0.04 else { return }
        lastFrameTime = now
        isProcessing = true
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            var points: [CGPoint] = []
            var isClap = false
            
            do {
                try requestHandler.perform([self.handRequest, self.bodyRequest])
                
                // 1. Process Hand Pose observations
                let handObservations = handRequest.results ?? []
                var centers: [CGPoint] = []
                for hand in handObservations {
                    if let recognized = try? hand.recognizedPoints(.all) {
                        if let indexTip = recognized[.indexTip], indexTip.confidence > 0.22 {
                            points.append(indexTip.location)
                            centers.append(indexTip.location)
                        } else if let wrist = recognized[.wrist], wrist.confidence > 0.22 {
                            points.append(wrist.location)
                            centers.append(wrist.location)
                        }
                    }
                }
                
                // Distance between hands for clapping
                if centers.count >= 2 {
                    let p1 = centers[0]
                    let p2 = centers[1]
                    let dist = hypot(p1.x - p2.x, p1.y - p2.y)
                    if dist < 0.18 {
                        isClap = true
                    }
                }
                
                // 2. Process Body Pose wrists
                let bodyObservations = bodyRequest.results ?? []
                for body in bodyObservations {
                    if let recognized = try? body.recognizedPoints(.all),
                       let lw = recognized[.leftWrist], lw.confidence > 0.25,
                       let rw = recognized[.rightWrist], rw.confidence > 0.25 {
                        let dist = hypot(lw.location.x - rw.location.x, lw.location.y - rw.location.y)
                        if dist < 0.15 {
                            isClap = true
                        }
                        if points.isEmpty {
                            points.append(lw.location)
                            points.append(rw.location)
                        }
                    }
                }
            } catch {
                // Ignore error
            }
            
            let finalPoints = points
            let finalClap = isClap
            
            Task { @MainActor in
                self.isProcessing = false
                self.detectedHandPoints = finalPoints
                
                let now = Date()
                if finalClap {
                    if self.handsWereApart && now.timeIntervalSince(self.lastClapTime) > self.clapCooldown {
                        self.handsWereApart = false
                        self.lastClapTime = now
                        self.onVisionClapDetected?()
                    }
                } else {
                    self.handsWereApart = true
                }
            }
        }
    }
}
