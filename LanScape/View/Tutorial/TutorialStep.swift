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
    case colorMatchingGuide
    case practiceHold
    case tutorialCompleted
    case readyCountdown3
    case readyCountdown2
    case readyCountdown1
    case started

    // Backward compatibility aliases
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
        case .colorMatchingGuide:
            return "Petunjuk Simbol & Warna"
        case .practiceHold:
            return "Tahan Posisi 5 Detik"
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
        case .colorMatchingGuide:
            return "Perhatikan simbol dan warna"
        case .practiceHold:
            return "Tahan posisimu selama 5 detik"
        case .tutorialCompleted:
            return "Tutorial selesai! Bersiap masuk ke game..."
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

enum TutorialRectangleState {

    case waiting
    case incorrect
    case correct

    var color: Color {
        switch self {
        case .waiting:
            return .blue
        case .incorrect:
            return .red
        case .correct:
            return .green
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

    // =========================================================
    // MARK: Published State
    // =========================================================

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


    // =========================================================
    // MARK: Internal Tasks
    // =========================================================

    private var holdTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var slideTimerTask: Task<Void, Never>?


    // =========================================================
    // MARK: Configuration
    // =========================================================

    var requiredReadyDuration: TimeInterval = 0.6
    let slideDurationSeconds: Int = 8


    // =========================================================
    // MARK: Reset
    // =========================================================

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


    // =========================================================
    // MARK: Update Player States (Player Setup Phase)
    // =========================================================

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


    // =========================================================
    // MARK: Step 1 -> Setup Countdown (Bersiap dalam... 3.. 2.. 1..)
    // =========================================================

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

            withAnimation(.easeInOut(duration: 0.3)) {
                self.startColorMatchingGuide()
            }
        }
    }


    // =========================================================
    // MARK: Step 2 -> Slide 1: Sentuh Sesuai Warna (8 Detik)
    // =========================================================

    func startColorMatchingGuide() {
        cancelAllTasks()

        currentStep = .colorMatchingGuide

        slideTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(
                    nanoseconds: UInt64(self.slideDurationSeconds) * 1_000_000_000
                )
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.startPracticeHold()
            }
        }
    }


    // =========================================================
    // MARK: Step 3 -> Slide 2: Tahan Posisi 5 Detik (8 Detik Slide)
    // =========================================================

    func startPracticeHold() {
        cancelAllTasks()

        currentStep = .practiceHold
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

            withAnimation(.easeInOut(duration: 0.3)) {
                self.startTutorialCompleted()
            }
        }
    }


    // =========================================================
    // MARK: Step 4 -> Tutorial Selesai! Bersiap masuk ke game... (2 Detik)
    // =========================================================

    func startTutorialCompleted() {
        cancelAllTasks()

        currentStep = .tutorialCompleted

        slideTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.startReadyCountdown()
            }
        }
    }


    // =========================================================
    // MARK: Step 5 -> Ready Countdown (3.. 2.. 1.. Mulai!)
    // =========================================================

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

            // MULAI!
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.currentStep = .started
                self.countdown = 0
            }

            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            withAnimation {
                self.hasStarted = true
                self.countdownTask = nil
            }
        }
    }


    // =========================================================
    // MARK: Skip / Next
    // =========================================================

    func nextStep() {
        switch currentStep {
        case .playerSetup, .setupCountdown3, .setupCountdown2, .setupCountdown1:
            startColorMatchingGuide()

        case .colorMatchingGuide:
            startPracticeHold()

        case .practiceHold:
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


    // =========================================================
    // MARK: DEBUG Helpers
    // =========================================================

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

        case .colorMatchingGuide:
            hasStarted = false
            startColorMatchingGuide()

        case .practiceHold:
            hasStarted = false
            startPracticeHold()

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
