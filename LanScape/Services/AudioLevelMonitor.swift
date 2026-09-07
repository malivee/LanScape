//
//  AudioLevelMonitor.swift
//  LanScape
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioLevelMonitor: ObservableObject {
    @Published var normalizedVolume: CGFloat = 0.0
    @Published var isRunning: Bool = false
    
    var onClapDetected: (() -> Void)?
    
    private var audioRecorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var lastPeakPower: Float = -160.0
    private var lastClapTime: Date = .distantPast
    
    // Clap state machine: sharp acoustic spike with impulse crest factor
    private let clapPowerThreshold: Float = -26.0 // Peak decibels (registers natural claps from 1-2.5 meters)
    private let clapRiseThreshold: Float = 3.0    // Sudden acoustic jump from previous frame
    private let clapCooldownSeconds: TimeInterval = 0.15 // Allows natural clapping cadence (~4-5 claps/sec)
    private var isClapArmed: Bool = true
    private var hasDippedSinceLastClap: Bool = true
    private var lastClapPeak: Float = -160.0
    private var recentTroughPower: Float = -40.0
    
    init() {}
    
    func requestPermissionAndStart() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startMonitoring()
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startMonitoring()
                    }
                }
            }
        }
    }
    
    func startMonitoring() {
        guard !isRunning else { return }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)
            
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let url = tempDir.appendingPathComponent("meter_temp.caf")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleIMA4),
                AVSampleRateKey: 22050.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 16,
                AVLinearPCMBitDepthKey: 16,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            self.audioRecorder = recorder
            self.isRunning = true
            self.lastPeakPower = -160.0
            self.recentTroughPower = -40.0
            self.isClapArmed = true
            self.hasDippedSinceLastClap = true
            
            // Poll at ~30 FPS (0.033s) for fast response to claps and screaming
            meterTimer?.invalidate()
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.updateMeters()
                }
            }
        } catch {
            print("⚠️ AudioLevelMonitor start error: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        meterTimer?.invalidate()
        meterTimer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRunning = false
        normalizedVolume = 0.0
        // Retain shared AVAudioSession so background music continues uninterrupted
    }
    
    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        
        let avgPower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        
        // Convert dB (-30dB to -4dB) to normalized 0.0 ... 1.0
        // Ambient room noise (-38dB to -45dB) is clamped to 0.0 to prevent false triggers
        let minDb: Float = -30.0
        let maxDb: Float = -4.0
        let clampedAvg = max(minDb, min(maxDb, avgPower))
        let targetVolume = CGFloat((clampedAvg - minDb) / (maxDb - minDb))
        
        // Fast attack, smooth decay
        if targetVolume > normalizedVolume {
            normalizedVolume = normalizedVolume * 0.25 + targetVolume * 0.75
        } else {
            normalizedVolume = normalizedVolume * 0.82 + targetVolume * 0.18
        }
        
        // Clap detection: sharp acoustic impulse (high crest factor peak vs avg, or sudden rise)
        let powerDiff = peakPower - lastPeakPower
        let crestFactor = peakPower - avgPower
        let now = Date()
        let timeSinceLastClap = now.timeIntervalSince(lastClapTime)
        
        // Track quiet troughs between claps
        if peakPower < recentTroughPower {
            recentTroughPower = peakPower
        } else {
            // Smoothly let trough follow upward to avoid getting permanently stuck
            recentTroughPower = recentTroughPower * 0.95 + peakPower * 0.05
        }
        
        // Sound must dip before another clap can re-arm (prevents speech or shouting runaway)
        if peakPower < (lastClapPeak - 3.0) || peakPower < -28.0 {
            hasDippedSinceLastClap = true
        }
        
        // Re-arm when cooldown elapsed and sound dipped
        if timeSinceLastClap >= clapCooldownSeconds {
            if hasDippedSinceLastClap || timeSinceLastClap >= 0.28 {
                isClapArmed = true
            }
        }
        
        // An impulse requires sudden power jump OR high crest factor with rise above trough
        let isImpulse = (powerDiff >= clapRiseThreshold) || (crestFactor >= 3.2 && (peakPower - recentTroughPower) >= 3.5)
        
        if isClapArmed &&
            peakPower >= clapPowerThreshold &&
            crestFactor >= 3.0 &&
            isImpulse &&
            timeSinceLastClap >= clapCooldownSeconds {
            
            isClapArmed = false
            hasDippedSinceLastClap = false
            lastClapTime = now
            lastClapPeak = peakPower
            recentTroughPower = peakPower
            onClapDetected?()
        }
        
        lastPeakPower = peakPower
    }
    
    /// Manual trigger for testing, accessibility, or simulator tap
    func triggerManualClap() {
        onClapDetected?()
    }
}
