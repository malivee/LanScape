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
    private var playerCache: [String: AVAudioPlayer] = [:]
    private var currentLoadTask: Task<Void, Never>? = nil
    private var isAudioSessionConfigured = false
    
    private init() {
        configureAudioSessionAsync()
    }
    
    private func configureAudioSessionAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                DispatchQueue.main.async {
                    self.isAudioSessionConfigured = true
                }
            } catch {
                print("⚠️ BackgroundMusicService session error: \(error.localizedDescription)")
            }
        }
    }
    
    func play(assetName: String, isLooping: Bool = true, volume: Float = 0.8) {
        // If already playing this exact asset, just update volume if needed and return
        if currentlyPlayingAssetName == assetName && isPlaying {
            audioPlayer?.volume = volume
            return
        }
        
        currentLoadTask?.cancel()
        
        // Fast path: cached player
        if let cachedPlayer = playerCache[assetName] {
            stop()
            cachedPlayer.currentTime = 0
            cachedPlayer.numberOfLoops = isLooping ? -1 : 0
            cachedPlayer.volume = volume
            cachedPlayer.play()
            
            self.audioPlayer = cachedPlayer
            self.currentlyPlayingAssetName = assetName
            self.isPlaying = true
            return
        }
        
        // Asynchronous load to eliminate any UI freeze
        currentLoadTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let dataAsset = NSDataAsset(name: assetName) else {
                print("⚠️ BackgroundMusicService: Cannot find NSDataAsset named '\(assetName)'")
                return
            }
            
            guard !Task.isCancelled else { return }
            
            do {
                let player = try AVAudioPlayer(data: dataAsset.data)
                player.numberOfLoops = isLooping ? -1 : 0
                player.volume = volume
                player.prepareToPlay()
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard let self = self else { return }
                    self.stop()
                    player.play()
                    self.playerCache[assetName] = player
                    self.audioPlayer = player
                    self.currentlyPlayingAssetName = assetName
                    self.isPlaying = true
                }
            } catch {
                print("⚠️ BackgroundMusicService error: \(error.localizedDescription)")
            }
        }
    }
    
    func stop() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
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
