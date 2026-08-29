//
//  TutorialStep.swift
//  LanScape
//

import Foundation
import SwiftUI
import Vision
import Combine

// MARK: - Tutorial Step

enum TutorialStep: Int, CaseIterable, Equatable {

    case playerSetup = 0
    case setupCountdown3
    case setupCountdown2
    case setupCountdown1
    
    // Storyboard Tutorial Slides (1 to 14)
    case tutorialIntro              // Slide 1: "Sebelum mulai perhatikan langkah-langkah berikut, ya!"
    case symbolColorGuide           // Slide 2 & 3: "Petunjuk Simbol dan Warna" modal
    case progressHeaderGuide        // Slide 4: "Kalian bisa melihat progress dan jumlah pose di sini"
    case poseAppearanceExplanation  // Slide 5: "Setiap pose akan muncul di tengah layar selama beberapa detik."
    case poseInstructionCard        // Slide 6: "Pose Pertama - Pose Fusion" card
    case followPoseIntro            // Slide 7: "Ikuti posenya!" + top right mini badge
    case hitboxTargetPreview        // Slide 8: Camera + hitboxes targets
    case hitboxExplanation          // Slide 9: "Pastikan tangan dan kaki kalian mengenai masing-masing titiknya."
    case matchPointsGuide           // Slide 10: "Cocokkan semua titik" badge + live players
    case holdInstruction            // Slide 11: "Tahan posisi kalian selama 5 detik!"
    case practiceHoldCountdown      // Slide 12: 5-second circular countdown hold (5.. 4.. 3.. 2.. 1..)
    case poseSuccess                // Slide 13: "KEREN BANGET!"
    case tutorialCompleted          // Slide 14: "Tutorial selesai. Mari kita mulai!"
    
    case readyCountdown3
    case readyCountdown2
    case readyCountdown1
    case started

    // Backward compatibility aliases
    static var colorMatchingGuide: TutorialStep { .symbolColorGuide }
    static var practiceHold: TutorialStep { .practiceHoldCountdown }
    static var countdown3: TutorialStep { .setupCountdown3 }
    static var countdown2: TutorialStep { .setupCountdown2 }
    static var countdown1: TutorialStep { .setupCountdown1 }

    var title: String {
        switch self {
        case .playerSetup:
            return "Persiapan Pemain"
        case .setupCountdown3:
            return "Bersiap: 3"
        case .setupCountdown2:
            return "Bersiap: 2"
        case .setupCountdown1:
            return "Bersiap: 1"
        case .tutorialIntro:
            return "Tutorial #1"
        case .symbolColorGuide:
            return "Petunjuk Simbol & Warna"
        case .progressHeaderGuide:
            return "Progress Gerakan"
        case .poseAppearanceExplanation:
            return "Kemunculan Pose"
        case .poseInstructionCard:
            return "Pose Pertama"
        case .followPoseIntro:
            return "Ikuti Posenya"
        case .hitboxTargetPreview:
            return "Titik Target"
        case .hitboxExplanation:
            return "Posisikan Tubuh"
        case .matchPointsGuide:
            return "Cocokkan Semua Titik"
        case .holdInstruction:
            return "Tahan Posisi"
        case .practiceHoldCountdown:
            return "Tahan Posisi 5 Detik"
        case .poseSuccess:
            return "Keren Banget!"
        case .tutorialCompleted:
            return "Tutorial Selesai!"
        case .readyCountdown3:
            return "Mulai: 3"
        case .readyCountdown2:
            return "Mulai: 2"
        case .readyCountdown1:
            return "Mulai: 1"
        case .started:
            return "Mulai!"
        }
    }

    var instruction: String {
        switch self {
        case .playerSetup:
            return "Posisikan tubuh di dalam area kotak masing-masing."
        case .setupCountdown3, .setupCountdown2, .setupCountdown1:
            return "Bersiap dalam..."
        case .tutorialIntro:
            return "Sebelum mulai, perhatikan langkah-langkah berikut, ya!"
        case .symbolColorGuide:
            return "Perhatikan simbol dan warna"
        case .progressHeaderGuide:
            return "Kalian bisa melihat progress dan jumlah pose di sini"
        case .poseAppearanceExplanation:
            return "Setiap pose akan muncul di tengah layar selama beberapa detik."
        case .poseInstructionCard:
            return "Pose Pertama - Pose Fusion"
        case .followPoseIntro:
            return "Ikuti posenya!"
        case .hitboxTargetPreview:
            return "Lihat posisi titik target di layar"
        case .hitboxExplanation:
            return "Pastikan tangan dan kaki kalian mengenai masing-masing titiknya."
        case .matchPointsGuide:
            return "Cocokkan semua titik target sesuai warna tubuhmu"
        case .holdInstruction:
            return "Tahan posisi kalian selama 5 detik!"
        case .practiceHoldCountdown:
            return "Tahan posisimu selama 5 detik"
        case .poseSuccess:
            return "KEREN BANGET!"
        case .tutorialCompleted:
            return "Tutorial selesai. Mari kita mulai!"
        case .readyCountdown3, .readyCountdown2, .readyCountdown1:
            return "Bersiap dalam..."
        case .started:
            return "Mulai!"
        }
    }

    var requiresPositionValidation: Bool {
        switch self {
        case .playerSetup:
            return true
        default:
            return false
        }
    }
}


// MARK: - Rectangle State

enum TutorialRectangleState: Equatable {

    case waiting

    /// 0/4, 1/4, 2/4, or 3/4 points are inside.
    case incorrect(count: Int)

    /// All four required points are inside.
    case correct

    var pointCount: Int {
        switch self {
        case .waiting:
            return 0
        case .incorrect(let count):
            return count
        case .correct:
            return 4
        }
    }

    var color: Color {
        switch self {
        case .waiting:
            return .red
        case .incorrect(let count):
            switch count {
            case 0:
                return Color(hex: "FF3B30")
            case 1:
                return Color(hex: "FF5A36")
            case 2:
                return Color(hex: "FFB020")
            case 3:
                return Color(hex: "D6E82F")
            default:
                return Color(hex: "FF3B30")
            }
        case .correct:
            return Color(hex: "34C759")
        }
    }

    var prompt: String {
        switch self {
        case .waiting:
            return "Pastikan seluruh tubuh kalian terlihat jelas."
        case .incorrect(let count):
            switch count {
            case 0, 1:
                return "Berikan sedikit jarak lagi!"
            case 2, 3:
                return "Sudah hampir tepat!"
            default:
                return "Sudah hampir tepat!"
            }
        case .correct:
            return "Yeay, kalian sudah terlihat jelas di kamera!"
        }
    }

    var systemImage: String {
        switch self {
        case .waiting:
            return "circle.dashed"
        case .incorrect:
            return "xmark.circle.fill"
        case .correct:
            return "checkmark.circle.fill"
        }
    }
}


// MARK: - Player Zone

struct TutorialPlayerZone {
    let playerIndex: Int
    let rect: CGRect
    let state: TutorialRectangleState
}


// MARK: - Tutorial Controller

@MainActor
final class TutorialController: ObservableObject {

    // MARK: Published State

    @Published
    private(set) var currentStep: TutorialStep = .playerSetup

    @Published
    private(set) var player1State: TutorialRectangleState = .waiting

    @Published
    private(set) var player2State: TutorialRectangleState = .waiting

    @Published
    private(set) var countdown: Int = 3

    @Published
    private(set) var hasStarted: Bool = false

    // MARK: Internal Tasks

    private var holdTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var slideTimerTask: Task<Void, Never>?

    // MARK: Configuration

    var requiredReadyDuration: TimeInterval = 0.6

    // MARK: Reset

    func reset() {
        cancelAllTasks()

        currentStep = .playerSetup
        player1State = .waiting
        player2State = .waiting
        countdown = 3
        hasStarted = false
    }

    private func cancelAllTasks() {
        holdTask?.cancel()
        holdTask = nil

        countdownTask?.cancel()
        countdownTask = nil

        slideTimerTask?.cancel()
        slideTimerTask = nil
    }

    // MARK: Update Player States (Player Setup Phase)

    func updatePlayerStates(
        player1: TutorialRectangleState,
        player2: TutorialRectangleState
    ) {
        guard !hasStarted else { return }

        player1State = player1
        player2State = player2

        guard currentStep == .playerSetup else { return }

        let bothCorrect = player1 == .correct && player2 == .correct

        if bothCorrect {
            if holdTask == nil {
                holdTask = Task { @MainActor [weak self] in
                    guard let self else { return }

                    do {
                        try await Task.sleep(
                            nanoseconds: UInt64(self.requiredReadyDuration * 1_000_000_000)
                        )
                    } catch {
                        return
                    }

                    guard !Task.isCancelled, self.currentStep == .playerSetup else {
                        return
                    }

                    self.holdTask = nil
                    self.startSetupCountdown()
                }
            }
        } else {
            holdTask?.cancel()
            holdTask = nil
        }
    }

    // MARK: - Step 0 -> Setup Countdown (3.. 2.. 1..)

    private func startSetupCountdown() {
        cancelAllTasks()

        currentStep = .setupCountdown3
        countdown = 3

        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for num in [3, 2, 1] {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    self.countdown = num
                    switch num {
                    case 3: self.currentStep = .setupCountdown3
                    case 2: self.currentStep = .setupCountdown2
                    case 1: self.currentStep = .setupCountdown1
                    default: break
                    }
                }

                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
            }

            withAnimation(.easeInOut(duration: 0.35)) {
                self.startTutorialIntro()
            }
        }
    }

    // MARK: - Slide 1: Tutorial Intro
    func startTutorialIntro() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .tutorialIntro
        }
    }

    // MARK: - Slide 2 & 3: Symbol & Color Guide
    func startSymbolColorGuide() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .symbolColorGuide
        }
    }

    // MARK: - Slide 4: Progress Header Guide
    func startProgressHeaderGuide() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .progressHeaderGuide
        }
    }

    // MARK: - Slide 5: Pose Appearance Explanation
    func startPoseAppearanceExplanation() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .poseAppearanceExplanation
        }
    }

    // MARK: - Slide 6: Pose Instruction Card
    func startPoseInstructionCard() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .poseInstructionCard
        }
    }

    // MARK: - Slide 7: Follow Pose Intro
    func startFollowPoseIntro() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .followPoseIntro
        }
    }

    // MARK: - Slide 8: Hitbox Target Preview
    func startHitboxTargetPreview() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .hitboxTargetPreview
        }
    }

    // MARK: - Slide 9: Hitbox Explanation
    func startHitboxExplanation() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .hitboxExplanation
        }
    }

    // MARK: - Slide 10: Match Points Guide
    func startMatchPointsGuide() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .matchPointsGuide
        }
    }

    // MARK: - Slide 11: Hold Instruction
    func startHoldInstruction() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .holdInstruction
        }
    }

    // MARK: - Slide 12: Practice Hold 5-Second Countdown
    func startPracticeHoldCountdown() {
        cancelAllTasks()
        currentStep = .practiceHoldCountdown
        countdown = 5

        slideTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for num in (1...5).reversed() {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    self.countdown = num
                }

                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
            }

            withAnimation(.easeInOut(duration: 0.35)) {
                self.startPoseSuccess()
            }
        }
    }

    // MARK: - Slide 13: Pose Success ("BERHASIL!")
    func startPoseSuccess() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .poseSuccess
        }
    }

    // MARK: - Slide 14: Tutorial Completed ("Tutorial selesai. Mari kita lanjut!")
    func startTutorialCompleted() {
        cancelAllTasks()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .tutorialCompleted
        }
    }

    // MARK: - Ready Countdown (3.. 2.. 1.. Mulai!)

    func startReadyCountdown() {
        cancelAllTasks()

        currentStep = .readyCountdown3
        countdown = 3

        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }

            for num in [3, 2, 1] {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    self.countdown = num
                    switch num {
                    case 3: self.currentStep = .readyCountdown3
                    case 2: self.currentStep = .readyCountdown2
                    case 1: self.currentStep = .readyCountdown1
                    default: break
                    }
                }

                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
            }

            // Immediately start gameplay upon countdown completion!
            withAnimation(.easeInOut(duration: 0.15)) {
                self.currentStep = .started
                self.countdown = 0
                self.hasStarted = true
                self.countdownTask = nil
            }
        }
    }

    // MARK: - Skip / Next (On Click / Tap)
    func nextStep() {
        switch currentStep {
        case .playerSetup, .setupCountdown3, .setupCountdown2, .setupCountdown1:
            startTutorialIntro()
        case .tutorialIntro:
            startSymbolColorGuide()
        case .symbolColorGuide:
            startProgressHeaderGuide()
        case .progressHeaderGuide:
            startPoseAppearanceExplanation()
        case .poseAppearanceExplanation:
            startPoseInstructionCard()
        case .poseInstructionCard:
            startFollowPoseIntro()
        case .followPoseIntro:
            startHitboxTargetPreview()
        case .hitboxTargetPreview:
            startHitboxExplanation()
        case .hitboxExplanation:
            startMatchPointsGuide()
        case .matchPointsGuide:
            startHoldInstruction()
        case .holdInstruction:
            startPracticeHoldCountdown()
        case .practiceHoldCountdown:
            startPoseSuccess()
        case .poseSuccess:
            startTutorialCompleted()
        case .tutorialCompleted:
            startReadyCountdown()
        case .readyCountdown3, .readyCountdown2, .readyCountdown1, .started:
            skipToStarted()
        }
    }

    func skipToStarted() {
        cancelAllTasks()
        currentStep = .started
        countdown = 0
        hasStarted = true
    }

    // MARK: - DEBUG Helpers

    #if DEBUG
    func debugSetStep(_ step: TutorialStep) {
        cancelAllTasks()
        currentStep = step

        switch step {
        case .playerSetup:
            countdown = 3
            hasStarted = false

        case .setupCountdown3, .setupCountdown2, .setupCountdown1:
            countdown = step == .setupCountdown3 ? 3 : (step == .setupCountdown2 ? 2 : 1)
            hasStarted = false

        case .tutorialIntro:
            hasStarted = false
            startTutorialIntro()

        case .symbolColorGuide:
            hasStarted = false
            startSymbolColorGuide()

        case .progressHeaderGuide:
            hasStarted = false
            startProgressHeaderGuide()

        case .poseAppearanceExplanation:
            hasStarted = false
            startPoseAppearanceExplanation()

        case .poseInstructionCard:
            hasStarted = false
            startPoseInstructionCard()

        case .followPoseIntro:
            hasStarted = false
            startFollowPoseIntro()

        case .hitboxTargetPreview:
            hasStarted = false
            startHitboxTargetPreview()

        case .hitboxExplanation:
            hasStarted = false
            startHitboxExplanation()

        case .matchPointsGuide:
            hasStarted = false
            startMatchPointsGuide()

        case .holdInstruction:
            hasStarted = false
            startHoldInstruction()

        case .practiceHoldCountdown:
            hasStarted = false
            startPracticeHoldCountdown()

        case .poseSuccess:
            hasStarted = false
            startPoseSuccess()

        case .tutorialCompleted:
            hasStarted = false
            startTutorialCompleted()

        case .readyCountdown3, .readyCountdown2, .readyCountdown1:
            countdown = step == .readyCountdown3 ? 3 : (step == .readyCountdown2 ? 2 : 1)
            hasStarted = false

        case .started:
            countdown = 0
            hasStarted = true
        }
    }

    func debugSkipToStarted() {
        skipToStarted()
    }
    #endif
}
