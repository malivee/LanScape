//
//  MotionDetectionService.swift
//  LanScape
//

import Foundation
import CoreVideo
import CoreImage
import Combine

@MainActor
final class MotionDetectionService: ObservableObject {
    @Published var instantMotion: CGFloat = 0.0
    @Published var accumulatedProgress: CGFloat = 0.0 // 0.0 to 1.0
    @Published var isTargetReached: Bool = false
    
    var onTargetReached: (() -> Void)?
    
    private var previousGrid: [UInt8] = []
    var isTrackingActive: Bool = false
    private let gridWidth = 24
    private let gridHeight = 16
    private var isCompleted = false
    
    private var lastProcessedTime: Date = .distantPast
    
    func reset() {
        isTrackingActive = false
        instantMotion = 0.0
        accumulatedProgress = 0.0
        isTargetReached = false
        isCompleted = false
        previousGrid.removeAll()
    }
    
    /// Process incoming camera pixel buffer to calculate motion energy
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard isTrackingActive, !isCompleted else { return }
        
        // 20 FPS is optimal for motion energy calculation without saturating the CPU
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= 0.05 else { return }
        lastProcessedTime = now
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // Sample downsampled grid of luminance values
        var currentGrid = [UInt8]()
        currentGrid.reserveCapacity(gridWidth * gridHeight)
        
        let stepX = max(1, width / gridWidth)
        let stepY = max(1, height / gridHeight)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for yIndex in 0..<gridHeight {
            let rowOffset = (yIndex * stepY) * bytesPerRow
            for xIndex in 0..<gridWidth {
                let pixelOffset = rowOffset + (xIndex * stepX) * 4 // BGRA format
                // Luminance approximation: 0.299R + 0.587G + 0.114B
                let b = UInt32(buffer[pixelOffset])
                let g = UInt32(buffer[pixelOffset + 1])
                let r = UInt32(buffer[pixelOffset + 2])
                let sum = (r * 77) + (g * 150) + (b * 29)
                let lum = UInt8(sum >> 8)
                currentGrid.append(lum)
            }
        }
        
        guard !previousGrid.isEmpty, previousGrid.count == currentGrid.count else {
            previousGrid = currentGrid
            return
        }
        
        var diffSum: Int = 0
        for i in 0..<currentGrid.count {
            diffSum += abs(Int(currentGrid[i]) - Int(previousGrid[i]))
        }
        
        previousGrid = currentGrid
        
        let avgDiff = CGFloat(diffSum) / CGFloat(currentGrid.count)
        let rawMotion = min(1.0, max(0.0, (avgDiff - 4.0) / 25.0))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isCompleted else { return }
            self.instantMotion = self.instantMotion * 0.3 + rawMotion * 0.7
            
            if self.instantMotion > 0.15 {
                self.accumulatedProgress = min(1.0, self.accumulatedProgress + (self.instantMotion * 0.035))
                if self.accumulatedProgress >= 1.0 && !self.isCompleted {
                    self.isCompleted = true
                    self.isTargetReached = true
                    self.onTargetReached?()
                }
            }
        }
    }
    
    /// Manual boost for testing in simulator or touch interaction
    func addManualMotion(amount: CGFloat = 0.08) {
        guard !isCompleted else { return }
        instantMotion = 1.0
        accumulatedProgress = min(1.0, accumulatedProgress + amount)
        if accumulatedProgress >= 1.0 && !isCompleted {
            isCompleted = true
            isTargetReached = true
            onTargetReached?()
        }
    }
}
