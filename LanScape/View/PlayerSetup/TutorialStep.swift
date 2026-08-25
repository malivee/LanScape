//
//  TutorialStep.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 25/08/26.
//

import Foundation
import SwiftUI
import Vision
import Combine


// MARK: - Tutorial Step

enum TutorialStep: Int, CaseIterable {

    case playerSetup1 = 0
    case playerStance1
    case playerStance2
    case playerStance3
    case playerStance4
    case countdown1
    case countdown2
    case countdown3
    case started


    // MARK: - Title

    var title: String {

        switch self {

        case .playerSetup1:
            return "Player Setup #1"

        case .playerStance1:
            return "Player Stance #1"

        case .playerStance2:
            return "Player Stance #2"

        case .playerStance3:
            return "Player Stance #3"

        case .playerStance4:
            return "Player Stance #4"

        case .countdown1:
            return "Countdown #1"

        case .countdown2:
            return "Countdown #2"

        case .countdown3:
            return "Countdown #3"

        case .started:
            return "Mulai!"
        }
    }


    // MARK: - Instruction

    var instruction: String {

        switch self {

        case .playerSetup1:
            return "Posisikan tubuh di masing-masing area."

        case .playerStance1:
            return "Perhatikan gerakan pertama."

        case .playerStance2:
            return "Pertahankan posisi kalian."

        case .playerStance3:
            return "Perhatikan gerakan berikutnya."

        case .playerStance4:
            return "Pertahankan posisi kalian."

        case .countdown1,
             .countdown2,
             .countdown3:

            return "Bersiap..."

        case .started:
            return "Mulai!"
        }
    }


    // MARK: - Position Validation

    var requiresPositionValidation: Bool {

        switch self {

        case .playerSetup1,
             .playerStance1,
             .playerStance2,
             .playerStance3,
             .playerStance4:

            return true

        case .countdown1,
             .countdown2,
             .countdown3,
             .started:

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
    // MARK: - Published State
    // =========================================================

    @Published
    private(set) var currentStep:
        TutorialStep = .playerSetup1

    @Published
    private(set) var player1State:
        TutorialRectangleState = .waiting

    @Published
    private(set) var player2State:
        TutorialRectangleState = .waiting

    @Published
    private(set) var countdown:
        Int = 3

    @Published
    private(set) var hasStarted:
        Bool = false


    // =========================================================
    // MARK: - Internal State
    // =========================================================

    private var readySince:
        Date?

    private var transitionWorkItem:
        DispatchWorkItem?

    private var countdownTask:
        Task<Void, Never>?


    // =========================================================
    // MARK: - Configuration
    // =========================================================

    /// Both players must remain correctly positioned
    /// for this amount of time before advancing.

    var requiredReadyDuration:
        TimeInterval = 0.8


    // =========================================================
    // MARK: - Reset
    // =========================================================

    func reset() {

        transitionWorkItem?.cancel()
        transitionWorkItem = nil

        countdownTask?.cancel()
        countdownTask = nil

        currentStep =
            .playerSetup1

        player1State =
            .waiting

        player2State =
            .waiting

        countdown =
            3

        hasStarted =
            false

        readySince =
            nil
    }


    // =========================================================
    // MARK: - Update Player States
    // =========================================================

    func updatePlayerStates(
        player1:
            TutorialRectangleState,

        player2:
            TutorialRectangleState
    ) {

        guard
            !hasStarted
        else {
            return
        }

        // Update UI states.

        player1State =
            player1

        player2State =
            player2


        // Current step must require validation.

        guard
            currentStep.requiresPositionValidation
        else {
            return
        }


        // Both players must be correct.

        let bothCorrect =
            player1 == .correct &&
            player2 == .correct


        // If either player isn't correct,
        // reset the stability timer.

        if !bothCorrect {

            readySince =
                nil

            return
        }


        // Start stability timer.

        if readySince == nil {

            readySince =
                Date()

            return
        }


        guard
            let readySince
        else {
            return
        }


        let duration =
            Date()
                .timeIntervalSince(
                    readySince
                )


        guard
            duration >=
                requiredReadyDuration
        else {
            return
        }


        // Both players stayed correct
        // long enough.

        self.readySince =
            nil

        advance()
    }


    // =========================================================
    // MARK: - Advance
    // =========================================================

    private func advance() {

        guard
            !hasStarted
        else {
            return
        }


        switch currentStep {

        case .playerSetup1:

            moveTo(
                .playerStance1
            )


        case .playerStance1:

            moveTo(
                .playerStance2
            )


        case .playerStance2:

            moveTo(
                .playerStance3
            )


        case .playerStance3:

            moveTo(
                .playerStance4
            )


        case .playerStance4:

            startCountdown()


        case .countdown1,
             .countdown2,
             .countdown3,
             .started:

            break
        }
    }


    // =========================================================
    // MARK: - Move To
    // =========================================================

    private func moveTo(
        _ step:
            TutorialStep
    ) {

        currentStep =
            step

        readySince =
            nil
    }


    // =========================================================
    // MARK: - Countdown
    // =========================================================

    private func startCountdown() {

        countdownTask?.cancel()

        countdownTask =
            nil


        // Start at 3.

        currentStep =
            .countdown1

        countdown =
            3


        countdownTask =
            Task { @MainActor [weak self] in

                guard
                    let self
                else {
                    return
                }


                // =========================================
                // 3 → 2
                // =========================================

                do {

                    try await Task.sleep(
                        nanoseconds:
                            1_000_000_000
                    )

                } catch {

                    return
                }


                guard
                    !Task.isCancelled
                else {
                    return
                }


                self.currentStep =
                    .countdown2

                self.countdown =
                    2


                // =========================================
                // 2 → 1
                // =========================================

                do {

                    try await Task.sleep(
                        nanoseconds:
                            1_000_000_000
                    )

                } catch {

                    return
                }


                guard
                    !Task.isCancelled
                else {
                    return
                }


                self.currentStep =
                    .countdown3

                self.countdown =
                    1


                // =========================================
                // 1 → STARTED
                // =========================================

                do {

                    try await Task.sleep(
                        nanoseconds:
                            1_000_000_000
                    )

                } catch {

                    return
                }


                guard
                    !Task.isCancelled
                else {
                    return
                }


                self.currentStep =
                    .started

                self.countdown =
                    0

                self.hasStarted =
                    true

                self.countdownTask =
                    nil
            }
    }


    // =========================================================
    // MARK: - DEBUG
    // =========================================================

    #if DEBUG

    /// Manually advances exactly ONE tutorial step.
    ///
    /// This is only for testing.
    ///
    /// Example:
    ///
    /// Player Setup
    ///      ↓ tap
    /// Stance 1
    ///      ↓ tap
    /// Stance 2
    ///      ↓ tap
    /// Stance 3
    ///      ↓ tap
    /// Stance 4
    ///      ↓ tap
    /// Countdown
    ///      ↓
    /// Started
    func debugNextStep() {

        guard
            !hasStarted
        else {
            return
        }


        // Stop any running countdown.

        countdownTask?.cancel()
        countdownTask =
            nil


        switch currentStep {

        case .playerSetup1:

            currentStep =
                .playerStance1


        case .playerStance1:

            currentStep =
                .playerStance2


        case .playerStance2:

            currentStep =
                .playerStance3


        case .playerStance3:

            currentStep =
                .playerStance4


        case .playerStance4:

            startCountdown()


        case .countdown1:

            currentStep =
                .countdown2

            countdown =
                2


        case .countdown2:

            currentStep =
                .countdown3

            countdown =
                1


        case .countdown3:

            currentStep =
                .started

            countdown =
                0

            hasStarted =
                true


        case .started:

            break
        }
    }


    /// Immediately skips the entire tutorial.
    ///
    /// Useful for testing the Core ML
    /// movement sequence directly.

    func skipToStarted() {

        countdownTask?.cancel()
        countdownTask =
            nil

        transitionWorkItem?.cancel()
        transitionWorkItem =
            nil

        readySince =
            nil

        player1State =
            .correct

        player2State =
            .correct

        countdown =
            0

        currentStep =
            .started

        hasStarted =
            true
    }

    #endif
}
