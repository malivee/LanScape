//
//  GameplayMusicManager.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 30/08/26.
//


import Foundation
import AVFoundation

final class GameplayMusicManager {
    
    static let shared = GameplayMusicManager()
    
    private var player: AVAudioPlayer?
    
    private init() {}
    
    
    
    func play() {
        
        guard let url = Bundle.main.url(
            forResource: "lagu klery",
            withExtension: "mp3"
        ) else {
            
            print("lagu klery.mp3 not found")
            return
        }
        
        do {
            
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(
                .playback,
                mode: .default,
                options: []
            )
            
            try session.setActive(true)
            
            
            player = try AVAudioPlayer(
                contentsOf: url
            )
            
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()
            
            print("Gameplay music started")
            
        } catch {
            
            print(
                "Music error:",
                error.localizedDescription
            )
        }
    }
    
    
    
    func stop() {
        
        player?.stop()
        player = nil
        
        print("Gameplay music stopped")
    }
}
