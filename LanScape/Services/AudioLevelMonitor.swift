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
    
    // Clap threshold: sharp spike in decibels
    private let clapPowerThreshold: Float = -15.0 // Peak decibels
    private let clapRiseThreshold: Float = 10.0 // Sudden jump from previous frame
    private let clapCooldownSeconds: TimeInterval = 0.20
    
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
        
        // Convert dB (-55dB to 0dB) to normalized 0.0 ... 1.0
        let minDb: Float = -50.0
        let maxDb: Float = -3.0
        let clampedAvg = max(minDb, min(maxDb, avgPower))
        let targetVolume = CGFloat((clampedAvg - minDb) / (maxDb - minDb))
        
        // Smooth screaming volume with dynamic response
        if targetVolume > normalizedVolume {
            normalizedVolume = normalizedVolume * 0.4 + targetVolume * 0.6
        } else {
            normalizedVolume = normalizedVolume * 0.85 + targetVolume * 0.15
        }
        
        // Clap detection: sharp jump or loud peak
        let powerDiff = peakPower - lastPeakPower
        let now = Date()
        let timeSinceLastClap = now.timeIntervalSince(lastClapTime)
        
        if (peakPower >= clapPowerThreshold || (powerDiff >= clapRiseThreshold && peakPower > -22.0)) &&
            timeSinceLastClap >= clapCooldownSeconds {
            lastClapTime = now
            onClapDetected?()
        }
        
        lastPeakPower = peakPower
    }
    
    /// Manual trigger for testing, accessibility, or simulator tap
    func triggerManualClap() {
        onClapDetected?()
    }
}
