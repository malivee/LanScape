//
//  VisionHandTrackingService.swift
//  LanScape
//
//  Created with real-time Vision Hand & Face Landmark gesture recognition.
//

import UIKit
@preconcurrency import Vision
import Combine

@MainActor
final class VisionHandTrackingService: ObservableObject {
    /// Normalized coordinates of detected hand tips / palms (0,0 bottom-left to 1,1 top-right)
    @Published var detectedHandPoints: [CGPoint] = []
    
    // Gestures
    @Published var isThumbsUpDetected: Bool = false
    @Published var isWavingDetected: Bool = false
    @Published var isHighFiveDetected: Bool = false
    @Published var isHeartPoseDetected: Bool = false
    @Published var isHandAtCenter: Bool = false
    @Published var centerDistance: CGFloat = 1.0
    
    // Face Gestures
    @Published var isMouthOpenWide: Bool = false
    @Published var isPuffCheeksActive: Bool = false
    @Published var isFishLipsActive: Bool = false
    @Published var isPeekABooCovering: Bool = false
    @Published var isPeekABooRevealed: Bool = false
    @Published var isFacesCloseTogether: Bool = false
    @Published var isHandAboveFace: Bool = false
    @Published var isHandBesideFace: Bool = false
    
    var isTrackingActive: Bool = false
    var onVisionClapDetected: (() -> Void)?
    
    private let processingQueue = DispatchQueue(label: "visionHandTrackingQueue", qos: .userInteractive)
    private var isProcessing = false
    private var lastFrameTime: Date = .distantPast
    
    // Persistent reusable requests
    nonisolated(unsafe) private let handRequest: VNDetectHumanHandPoseRequest = {
        let req = VNDetectHumanHandPoseRequest()
        req.maximumHandCount = 4
        return req
    }()
    nonisolated(unsafe) private let bodyRequest = VNDetectHumanBodyPoseRequest()
    nonisolated(unsafe) private let faceRequest = VNDetectFaceLandmarksRequest()
    
    // Clap state
    private var handsWereApart = true
    private var lastClapTime: Date = .distantPast
    private let clapCooldown: TimeInterval = 0.16
    
    // Waving history: [(x, time)]
    private var waveHistory: [(x: CGFloat, time: Date)] = []
    
    // Peek-a-boo state
    private var wasCoveringFace = false
    private var lastCoverTime: Date = .distantPast
    
    init() {
        handRequest.maximumHandCount = 4
    }
    
    func reset() {
        detectedHandPoints = []
        isThumbsUpDetected = false
        isHighFiveDetected = false
        isWavingDetected = false
        isHeartPoseDetected = false
        isHandAtCenter = false
        centerDistance = 1.0
        isMouthOpenWide = false
        isPuffCheeksActive = false
        isFishLipsActive = false
        isPeekABooCovering = false
        isPeekABooRevealed = false
        isFacesCloseTogether = false
        isHandAboveFace = false
        isHandBesideFace = false
        waveHistory.removeAll()
        wasCoveringFace = false
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard isTrackingActive, !isProcessing else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastFrameTime) >= 0.040 else { return }
        lastFrameTime = now
        isProcessing = true
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            var points: [CGPoint] = []
            var isClap = false
            var thumbsUpFound = false
            var highFiveFound = false
            var heartFound = false
            var handAtCenterFound = false
            var minCenterDist: CGFloat = 1.0
            var dominantHandX: CGFloat? = nil
            
            var mouthOpen = false
            var puffCheeks = false
            var fishLips = false
            var peekCovering = false
            var facesClose = false
            var handAboveFace = false
            var handBesideFace = false
            var hasDetectedFaces = false
            
            do {
                try requestHandler.perform([self.handRequest, self.bodyRequest, self.faceRequest])
                
                // 1. Process Hand Pose observations
                let handObservations = self.handRequest.results ?? []
                var centers: [CGPoint] = []
                var handLandmarksList: [[VNHumanHandPoseObservation.JointName: VNRecognizedPoint]] = []
                
                for hand in handObservations {
                    if let recognized = try? hand.recognizedPoints(.all) {
                        handLandmarksList.append(recognized)
                        
                        // Extract rich joints for visual tracking & collisions
                        if let indexTip = recognized[.indexTip], indexTip.confidence > 0.15 {
                            points.append(indexTip.location)
                            centers.append(indexTip.location)
                            dominantHandX = indexTip.location.x
                        }
                        if let middleTip = recognized[.middleTip], middleTip.confidence > 0.15 {
                            points.append(middleTip.location)
                            if dominantHandX == nil { dominantHandX = middleTip.location.x }
                        }
                        if let thumbTip = recognized[.thumbTip], thumbTip.confidence > 0.15 {
                            points.append(thumbTip.location)
                        }
                        if let wrist = recognized[.wrist], wrist.confidence > 0.15 {
                            points.append(wrist.location)
                            if centers.isEmpty { centers.append(wrist.location) }
                            if dominantHandX == nil { dominantHandX = wrist.location.x }
                        }
                    }
                }
                
                // Center evaluation (Target in center 0.5, 0.5)
                let centerPoint = CGPoint(x: 0.5, y: 0.5)
                for pt in points {
                    let d = hypot(pt.x - centerPoint.x, pt.y - centerPoint.y)
                    if d < minCenterDist {
                        minCenterDist = d
                    }
                }
                if minCenterDist < 0.28 {
                    handAtCenterFound = true
                }
                
                // Distance between hands for clapping (hands wide apart then close)
                if centers.count >= 2 {
                    let dist = hypot(centers[0].x - centers[1].x, centers[0].y - centers[1].y)
                    if dist < 0.12 {
                        isClap = true
                    }
                }
                
                // Body pose fallback for clapping & points
                let bodyObservations = self.bodyRequest.results ?? []
                for body in bodyObservations {
                    if let recognized = try? body.recognizedPoints(.all),
                       let lw = recognized[.leftWrist], lw.confidence > 0.20,
                       let rw = recognized[.rightWrist], rw.confidence > 0.20 {
                        points.append(lw.location)
                        points.append(rw.location)
                        
                        let wristDist = hypot(lw.location.x - rw.location.x, lw.location.y - rw.location.y)
                        if wristDist < 0.14 {
                            isClap = true
                        }
                        
                        let d1 = hypot(lw.location.x - 0.5, lw.location.y - 0.5)
                        let d2 = hypot(rw.location.x - 0.5, rw.location.y - 0.5)
                        let minD = min(d1, d2)
                        if minD < minCenterDist {
                            minCenterDist = minD
                        }
                        if minCenterDist < 0.28 {
                            handAtCenterFound = true
                        }
                    }
                }
                
                // Robust Gesture Analysis for each hand
                for recognized in handLandmarksList {
                    // Thumbs Up:
                    // 1. Thumb points up: thumbTip higher than wrist
                    // 2. Thumb tip higher than index & middle fingers
                    // 3. Other fingers curled
                    if let thumbTip = recognized[.thumbTip], thumbTip.confidence > 0.20,
                       let wrist = recognized[.wrist], wrist.confidence > 0.20 {
                        
                        let thumbIsUp = thumbTip.location.y > wrist.location.y + 0.06
                        let indexTip = recognized[.indexTip]
                        let middleTip = recognized[.middleTip]
                        
                        let thumbAboveIndex = (indexTip == nil || indexTip!.confidence < 0.20 || thumbTip.location.y > indexTip!.location.y + 0.02)
                        let thumbAboveMiddle = (middleTip == nil || middleTip!.confidence < 0.20 || thumbTip.location.y > middleTip!.location.y + 0.02)
                        
                        var fingersCurled = true
                        if let iTip = indexTip, iTip.confidence > 0.20 {
                            let thumbDist = hypot(thumbTip.location.x - wrist.location.x, thumbTip.location.y - wrist.location.y)
                            let indexDist = hypot(iTip.location.x - wrist.location.x, iTip.location.y - wrist.location.y)
                            fingersCurled = indexDist <= thumbDist * 1.05
                        }
                        
                        if thumbIsUp && thumbAboveIndex && thumbAboveMiddle && fingersCurled {
                            thumbsUpFound = true
                        }
                    }
                    
                    // High Five / Tosss: Open palm raised with fingers pointing up
                    if let wrist = recognized[.wrist], wrist.confidence > 0.20 {
                        let handRaised = wrist.location.y > 0.12
                        let indexTip = recognized[.indexTip]
                        let middleTip = recognized[.middleTip]
                        
                        let indexUp = indexTip != nil && indexTip!.confidence > 0.20 && indexTip!.location.y > wrist.location.y + 0.06
                        let middleUp = middleTip != nil && middleTip!.confidence > 0.20 && middleTip!.location.y > wrist.location.y + 0.06
                        
                        if handRaised && (indexUp || middleUp) && !thumbsUpFound {
                            highFiveFound = true
                        }
                    }
                }
                
                // Heart pose: Two hands close together near center OR single hand half-heart
                if handLandmarksList.count >= 2 {
                    let h1 = handLandmarksList[0]
                    let h2 = handLandmarksList[1]
                    if let t1 = h1[.thumbTip], let t2 = h2[.thumbTip],
                       let i1 = h1[.indexTip], let i2 = h2[.indexTip] {
                        let thumbDist = hypot(t1.location.x - t2.location.x, t1.location.y - t2.location.y)
                        let indexDist = hypot(i1.location.x - i2.location.x, i1.location.y - i2.location.y)
                        if thumbDist < 0.36 && indexDist < 0.36 {
                            heartFound = true
                        }
                    }
                    if !heartFound && centers.count >= 2 {
                        let centerDist = hypot(centers[0].x - centers[1].x, centers[0].y - centers[1].y)
                        if centerDist < 0.36 && centers[0].y > 0.18 && centers[1].y > 0.18 {
                            heartFound = true
                        }
                    }
                } else if let h1 = handLandmarksList.first,
                          let t1 = h1[.thumbTip], let i1 = h1[.indexTip] {
                    // Single-hand half heart
                    let gap = hypot(t1.location.x - i1.location.x, t1.location.y - i1.location.y)
                    if gap < 0.24 && t1.location.y > 0.20 {
                        heartFound = true
                    }
                }
                
                // 2. Process Face Landmark observations
                let faceObservations = self.faceRequest.results ?? []
                hasDetectedFaces = !faceObservations.isEmpty
                
                // Two faces close together for battery hug / cheek to cheek
                if faceObservations.count >= 2 {
                    let f1 = faceObservations[0].boundingBox
                    let f2 = faceObservations[1].boundingBox
                    let c1 = CGPoint(x: f1.midX, y: f1.midY)
                    let c2 = CGPoint(x: f2.midX, y: f2.midY)
                    let dist = hypot(c1.x - c2.x, c1.y - c2.y)
                    if dist < 0.52 {
                        facesClose = true
                    }
                }
                
                for face in faceObservations {
                    let faceBox = face.boundingBox
                    
                    // Single face leaning / head tilt (roll > 10 degrees)
                    if let roll = face.roll, abs(roll.doubleValue) > 0.18 {
                        facesClose = true
                    }
                    
                    // Check hand relation to face (head pat & sleepy pose)
                    for pt in points {
                        // Head pat: hand is in upper half of face or hovering directly above
                        if pt.y >= faceBox.midY - 0.05 && pt.y <= faceBox.maxY + 0.35 && abs(pt.x - faceBox.midX) < faceBox.width * 1.5 {
                            handAboveFace = true
                        }
                        // Sleepy pose: hand beside face
                        if abs(pt.y - faceBox.midY) < faceBox.height * 0.8 && abs(pt.x - faceBox.midX) < faceBox.width * 1.6 {
                            handBesideFace = true
                        }
                    }
                    
                    if let landmarks = face.landmarks {
                        // A. Mouth Open ('O')
                        if let innerLips = landmarks.innerLips {
                            let innerPts = innerLips.normalizedPoints
                            if !innerPts.isEmpty {
                                let minY = innerPts.map(\.y).min() ?? 0
                                let maxY = innerPts.map(\.y).max() ?? 0
                                let innerHeight = maxY - minY
                                if innerHeight > 0.05 {
                                    mouthOpen = true
                                }
                            }
                        }
                        
                        if let outerLips = landmarks.outerLips {
                            let pts = outerLips.normalizedPoints
                            if !pts.isEmpty {
                                let minY = pts.map(\.y).min() ?? 0
                                let maxY = pts.map(\.y).max() ?? 0
                                let minX = pts.map(\.x).min() ?? 0
                                let maxX = pts.map(\.x).max() ?? 0
                                
                                let mouthHeight = maxY - minY
                                let mouthWidth = max(0.01, maxX - minX)
                                let ratio = mouthHeight / mouthWidth
                                
                                // Wide open 'O': ratio > 0.28 with noticeable height
                                if ratio > 0.28 && mouthHeight > 0.08 {
                                    mouthOpen = true
                                }
                                
                                // Fish lips: puckered lips (narrow width, moderate height)
                                if mouthWidth < 0.38 && ratio > 0.18 && ratio < 0.90 {
                                    fishLips = true
                                }
                            }
                        }
                    }
                }
                
                // Cilukba (Peek-a-Boo) evaluation:
                if !handObservations.isEmpty && faceObservations.isEmpty {
                    peekCovering = true
                } else if !handObservations.isEmpty && !faceObservations.isEmpty {
                    for handPt in points {
                        for face in faceObservations {
                            if face.boundingBox.insetBy(dx: -0.08, dy: -0.08).contains(handPt) {
                                peekCovering = true
                                break
                            }
                        }
                    }
                }
                
            } catch {
                // Ignore error
            }
            
            let finalPoints = points
            let finalClap = isClap
            let finalThumbsUp = thumbsUpFound
            let finalHighFive = highFiveFound
            let finalHeart = heartFound
            let finalHandCenter = handAtCenterFound
            let finalCenterDist = minCenterDist
            let finalMouthOpen = mouthOpen
            let finalPuff = puffCheeks
            let finalFish = fishLips
            let finalFacesClose = facesClose
            let finalHandAbove = handAboveFace
            let finalHandBeside = handBesideFace
            let currentDominantX = dominantHandX
            let finalCovering = peekCovering
            let finalHasFaces = hasDetectedFaces
            
            Task { @MainActor in
                self.isProcessing = false
                self.detectedHandPoints = finalPoints
                self.isThumbsUpDetected = finalThumbsUp
                self.isHighFiveDetected = finalHighFive
                self.isHeartPoseDetected = finalHeart
                self.isHandAtCenter = finalHandCenter
                self.centerDistance = finalCenterDist
                self.isMouthOpenWide = finalMouthOpen
                self.isPuffCheeksActive = finalPuff
                self.isFishLipsActive = finalFish
                self.isFacesCloseTogether = finalFacesClose
                self.isHandAboveFace = finalHandAbove
                self.isHandBesideFace = finalHandBeside
                
                let now = Date()
                
                // Waving calculation: direction reversals with minimum amplitude
                if let x = currentDominantX {
                    self.waveHistory.append((x: x, time: now))
                    self.waveHistory = self.waveHistory.filter { now.timeIntervalSince($0.time) <= 1.2 }
                    
                    if self.waveHistory.count >= 4 {
                        var dirChanges = 0
                        var lastSign: CGFloat = 0
                        var travel: CGFloat = 0
                        for i in 1..<self.waveHistory.count {
                            let dx = self.waveHistory[i].x - self.waveHistory[i-1].x
                            travel += abs(dx)
                            if abs(dx) > 0.010 {
                                let sign: CGFloat = dx > 0 ? 1 : -1
                                if lastSign != 0 && sign != lastSign {
                                    dirChanges += 1
                                }
                                lastSign = sign
                            }
                        }
                        self.isWavingDetected = (dirChanges >= 2 && travel > 0.05)
                    } else {
                        self.isWavingDetected = false
                    }
                } else {
                    self.isWavingDetected = false
                }
                
                // Peek-a-boo transition logic:
                if finalCovering {
                    self.wasCoveringFace = true
                    self.lastCoverTime = now
                    self.isPeekABooCovering = true
                } else {
                    self.isPeekABooCovering = false
                    if self.wasCoveringFace && now.timeIntervalSince(self.lastCoverTime) < 3.0 && finalHasFaces {
                        self.isPeekABooRevealed = true
                        self.wasCoveringFace = false
                        // Keep revealed latch for 1.8s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                            self?.isPeekABooRevealed = false
                        }
                    }
                }
                
                // Clap trigger logic (minimum 0.38s cooldown and hands apart check)
                if finalClap {
                    if self.handsWereApart && now.timeIntervalSince(self.lastClapTime) > 0.38 {
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
