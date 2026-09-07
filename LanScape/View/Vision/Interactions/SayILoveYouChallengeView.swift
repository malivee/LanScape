//
//  SayILoveYouChallengeView.swift
//  LanScape
//

import SwiftUI

struct SayILoveYouChallengeView: View {
    @ObservedObject var audioMonitor: AudioLevelMonitor
    let onSuccess: () -> Void
    let onFailure: () -> Void
    
    @StateObject private var speechService = SpeechRecognitionService()
    
    @State private var timeRemaining: Int = 12
    @State private var progress: CGFloat = 0.0
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var isFinished: Bool = false
    @State private var pulseHeart: Bool = false
    
    var body: some View {
        let isPad = UIDevice.isIPad
        
        ZStack {
            // Completely transparent background so camera preview remains 100% visible & clear
            Color.clear
                .ignoresSafeArea()
            
            // Floating Hearts in background
            ForEach(0..<6, id: \.self) { i in
                Image(systemName: "heart.fill")
                    .font(.system(size: isPad ? 36 : 24))
                    .foregroundColor(Color(hex: "F43F5E").opacity(progress > 0.1 ? 0.8 : 0.0))
                    .position(
                        x: CGFloat(80 + (i * 125)).truncatingRemainder(dividingBy: 700) + 30,
                        y: CGFloat(80 + (i * 55))
                    )
                    .scaleEffect(pulseHeart ? 1.25 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.7 + Double(i) * 0.15).repeatForever(autoreverses: true),
                        value: pulseHeart
                    )
            }
            
            VStack(spacing: isPad ? 16 : 8) {
                Spacer()
                
                // 1. Timer Badge
                HStack(spacing: 6) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: isPad ? 14 : 11, weight: .bold))
                        .foregroundColor(Color(hex: "38BDF8"))
                    Text("\(timeRemaining)s")
                        .font(.system(size: isPad ? 17 : 12.5, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0B0F19").opacity(0.88))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(hex: "38BDF8").opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
                
                // 2. Action Prompt
                Text("UCAPKAN 'I LOVE YOU' ATAU 'AKU SAYANG KAMU'!")
                    .font(.system(size: isPad ? 24 : 15.5, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 6, y: 3)
                
                // 3. Hero Visual Display (Pure Speech Recognition, SF Symbol)
                ZStack {
                    Circle()
                        .stroke(speechService.isKeywordDetected ? Color.green : Color(hex: "F43F5E"), lineWidth: isPad ? 6 : 4)
                        .scaleEffect(pulseHeart ? 1.08 : 0.98)
                        .opacity(pulseHeart ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseHeart)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1E293B").opacity(0.92),
                                    Color(hex: "0F172A").opacity(0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle().stroke(Color(hex: "F43F5E").opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: (speechService.isKeywordDetected ? Color.green : Color(hex: "F43F5E")).opacity(0.5), radius: isPad ? 20 : 14)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: isPad ? 56 : 38))
                            .foregroundColor(speechService.isKeywordDetected ? .green : Color(hex: "FDA4AF"))
                            .scaleEffect(pulseHeart ? 1.15 : 0.95)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6).repeatForever(autoreverses: true), value: pulseHeart)
                        
                        Text(speechService.isKeywordDetected ? "Kata Cinta Terdeteksi!" : "Katakan Cinta")
                            .font(.system(size: isPad ? 13 : 9, weight: .bold, design: .rounded))
                            .foregroundColor(speechService.isKeywordDetected ? .green : Color(hex: "FFE4E6"))
                    }
                }
                .frame(width: isPad ? 180 : 130, height: isPad ? 180 : 130)
                .padding(.vertical, isPad ? 4 : 2)
                
                // 4. Recognized Speech Subtitle (Transparent Feedback)
                if !speechService.recognizedText.isEmpty {
                    Text("\"\(speechService.recognizedText)\"")
                        .font(.system(size: isPad ? 15 : 11, weight: .bold, design: .rounded))
                        .foregroundColor(speechService.isKeywordDetected ? .green : Color(hex: "FDA4AF"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0B0F19").opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .transition(.opacity)
                }
                
                // 5. Progress Feedback
                VStack(spacing: isPad ? 7 : 4) {
                    Text(progress >= 1.0 ? "SO SWEET BANGETTT!" : "LETSGOOO...!!!")
                        .font(.system(size: isPad ? 20 : 13.5, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "FB7185"))
                        .tracking(0.6)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "0B0F19").opacity(0.85))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "F43F5E"), Color(hex: "10B981")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * min(1.0, progress)))
                                .animation(.easeOut(duration: 0.15), value: progress)
                        }
                    }
                    .frame(width: isPad ? 280 : 190, height: isPad ? 10 : 7)
                }
                
                // 6. Helper Pill
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: isPad ? 12 : 9, weight: .bold))
                        .foregroundColor(Color(hex: "FB7185"))
                    Text("Ucapkan jelas ke arah mikrofon perangkat")
                        .font(.system(size: isPad ? 12 : 9, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isPad ? 18 : 12)
                .padding(.vertical, isPad ? 6 : 4)
                .background(Color(hex: "0B0F19").opacity(0.88))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.top, isPad ? 4 : 2)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            pulseHeart = true
            startChallenge()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func startChallenge() {
        speechService.startListening {
            Task { @MainActor in
                registerBoost(1.0)
            }
        }
        
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                if speechService.isKeywordDetected {
                    registerBoost(1.0)
                    return
                }
                
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                } catch { return }
                
                guard !Task.isCancelled, !isFinished else { return }
            }
            
            guard !Task.isCancelled, !isFinished else { return }
            finishChallenge(success: progress >= 1.0)
        }
        
        Task { @MainActor in
            while timeRemaining > 0 && !isFinished {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch { return }
                
                guard !Task.isCancelled, !isFinished else { return }
                timeRemaining -= 1
            }
            
            guard !Task.isCancelled, !isFinished else { return }
            finishChallenge(success: progress >= 1.0)
        }
    }
    
    private func registerBoost(_ amount: CGFloat) {
        guard !isFinished else { return }
        progress = min(1.0, progress + amount)
        if progress >= 1.0 {
            finishChallenge(success: true)
        }
    }
    
    private func finishChallenge(success: Bool) {
        guard !isFinished else { return }
        isFinished = true
        cleanup()
        if success {
            onSuccess()
        } else {
            onFailure()
        }
    }
    
    private func cleanup() {
        timerTask?.cancel()
        speechService.stopListening()
    }
}
