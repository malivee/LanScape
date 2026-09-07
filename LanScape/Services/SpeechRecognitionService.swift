//
//  SpeechRecognitionService.swift
//  LanScape
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isKeywordDetected: Bool = false
    @Published var isListening: Bool = false
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Target keywords for "I Love You" / "Aku Sayang Kamu"
    private let targetKeywords: [String] = [
        "love", "sayang", "cinta", "i love you", "love you", "aku sayang", "aku cinta", "you", "saranghae", "ai ni"
    ]
    
    init() {
        // Prefer Indonesian, fallback to English
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID")) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startListening(onKeywordMatched: (() -> Void)? = nil) {
        stopListening()
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                guard let self = self else { return }
                guard authStatus == .authorized else {
                    print("⚠️ Speech Recognition not authorized: \(authStatus)")
                    return
                }
                self.beginRecording(onKeywordMatched: onKeywordMatched)
            }
        }
    }
    
    private func beginRecording(onKeywordMatched: (() -> Void)?) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            recognizedText = ""
            isKeywordDetected = false
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    let transcribed = result.bestTranscription.formattedString.lowercased()
                    Task { @MainActor in
                        self.recognizedText = transcribed
                        for kw in self.targetKeywords {
                            if transcribed.contains(kw) {
                                self.isKeywordDetected = true
                                onKeywordMatched?()
                                break
                            }
                        }
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    // Task finished or error
                }
            }
        } catch {
            print("⚠️ Speech Recognition start failed: \(error)")
            isListening = false
        }
    }
    
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}
