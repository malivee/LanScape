//
//  BackgroundMusicService.swift
//  LanScape
//

import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
final class BackgroundMusicService: ObservableObject {
    static let shared = BackgroundMusicService()
    
    @Published var currentlyPlayingAssetName: String? = nil
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func play(assetName: String, isLooping: Bool = true, volume: Float = 0.8) {
        // If already playing this exact asset, keep playing
        if currentlyPlayingAssetName == assetName && isPlaying {
            return
        }
        
        stop()
        
        guard let dataAsset = NSDataAsset(name: assetName) else {
            print("⚠️ BackgroundMusicService: Cannot find NSDataAsset named '\(assetName)'")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            let player = try AVAudioPlayer(data: dataAsset.data)
            player.numberOfLoops = isLooping ? -1 : 0
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            self.audioPlayer = player
            self.currentlyPlayingAssetName = assetName
            self.isPlaying = true
        } catch {
            print("⚠️ BackgroundMusicService error: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlayingAssetName = nil
        isPlaying = false
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resume() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        player.play()
        isPlaying = true
    }
}
