//
//  TutorialStep.swift
//  LanScape
//

import Foundation
import SwiftUI
import Vision
import Combine

// MARK: - Tutorial Step

enum TutorialStep: Int, CaseIterable {

    case playerSetup = 0

    case countdown3
    case countdown2
    case countdown1

    case started

    var title: String {

        switch self {

        case .playerSetup:
            return "Player Setup"

        case .countdown3:
            return "Countdown #3"

        case .countdown2:
            return "Countdown #2"

        case .countdown1:
            return "Countdown #1"

        case .started:
            return "Mulai"
        }
    }

    var instruction: String {

        switch self {

        case .playerSetup:
            return "Posisikan tubuh di masing-masing area."

        case .countdown3,
             .countdown2,
             .countdown1:
            return "Bersiap..."

        case .started:
            return "Mulai!"
        }
    }

    var requiresPositionValidation: Bool {

        switch self {

        case .playerSetup:
            return true

        case .countdown3,
             .countdown2,
             .countdown1,
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
    // MARK: Current Step
    // =========================================================

    @Published
    private(set) var currentStep:
        TutorialStep = .playerSetup


    // =========================================================
    // MARK: Rectangle States
    // =========================================================

    @Published
    private(set) var player1State:
        TutorialRectangleState = .waiting

    @Published
    private(set) var player2State:
        TutorialRectangleState = .waiting


    // =========================================================
    // MARK: Countdown
    // =========================================================

    @Published
    private(set) var countdown:
        Int = 3


    // =========================================================
    // MARK: Started
    // =========================================================

    @Published
    private(set) var hasStarted:
        Bool = false


    // =========================================================
    // MARK: Internal
    // =========================================================

    private var readySince:
        Date?

    private var countdownTask:
        Task<Void, Never>?


    // =========================================================
    // MARK: Configuration
    // =========================================================

    var requiredReadyDuration:
        TimeInterval = 0.8


    // =========================================================
    // MARK: Reset
    // =========================================================

    func reset() {

        countdownTask?.cancel()
        countdownTask = nil

        currentStep =
            .playerSetup

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
    // MARK: Update Player States
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


        player1State =
            player1

        player2State =
            player2


        guard
            currentStep == .playerSetup
        else {
            return
        }


        let bothCorrect =
            player1 == .correct &&
            player2 == .correct


        // =============================================
        // One or both players are not ready
        // =============================================

        guard
            bothCorrect
        else {

            readySince =
                nil

            return
        }


        // =============================================
        // Start holding timer
        // =============================================

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


        self.readySince =
            nil


        // =============================================
        // Both players are ready
        // → Start countdown
        // =============================================

        startCountdown()
    }


    // =========================================================
    // MARK: Countdown
    // =========================================================

    private func startCountdown() {

        countdownTask?.cancel()

        countdownTask =
            nil


        currentStep =
            .countdown3

        countdown =
            3


        countdownTask =
            Task { @MainActor [weak self] in

                guard
                    let self
                else {
                    return
                }


                // =============================================
                // 3
                // =============================================

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


                // =============================================
                // 2
                // =============================================

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
                    .countdown1

                self.countdown =
                    1


                // =============================================
                // 1
                // =============================================

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


                // =============================================
                // MULAI
                // =============================================

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
    // MARK: DEBUG
    // =========================================================

    #if DEBUG

    func debugSetStep(
        _ step:
            TutorialStep
    ) {

        countdownTask?.cancel()

        countdownTask =
            nil

        readySince =
            nil


        currentStep =
            step


        switch step {

        case .playerSetup:

            countdown =
                3

            hasStarted =
                false


        case .countdown3:

            countdown =
                3

            hasStarted =
                false


        case .countdown2:

            countdown =
                2

            hasStarted =
                false


        case .countdown1:

            countdown =
                1

            hasStarted =
                false


        case .started:

            countdown =
                0

            hasStarted =
                true
        }
    }


    func debugStartCountdown() {

        countdownTask?.cancel()

        countdownTask =
            nil

        readySince =
            nil

        startCountdown()
    }


    func debugSkipToStarted() {

        countdownTask?.cancel()

        countdownTask =
            nil

        readySince =
            nil

        currentStep =
            .started

        countdown =
            0

        hasStarted =
            true
    }

    #endif
}
