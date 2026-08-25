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

    private var holdTask:
        Task<Void, Never>?

    private var countdownTask:
        Task<Void, Never>?


    // =========================================================
    // MARK: Configuration
    // =========================================================

    var requiredReadyDuration:
        TimeInterval = 0.6


    // =========================================================
    // MARK: Reset
    // =========================================================

    func reset() {

        holdTask?.cancel()
        holdTask = nil

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
        // Both players are correct
        // → Start hold timer if not already running
        // =============================================

        if bothCorrect {

            if holdTask == nil {

                holdTask =
                    Task { @MainActor [weak self] in

                        guard
                            let self
                        else {
                            return
                        }

                        do {

                            try await Task.sleep(
                                nanoseconds:
                                    UInt64(
                                        self.requiredReadyDuration * 1_000_000_000
                                    )
                            )

                        } catch {

                            return
                        }

                        guard
                            !Task.isCancelled,
                            self.currentStep == .playerSetup
                        else {
                            return
                        }

                        self.holdTask =
                            nil

                        self.startCountdown()
                    }
            }

        } else {

            // One or both players left correct state
            holdTask?.cancel()
            holdTask =
                nil
        }
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

        holdTask?.cancel()
        holdTask = nil

        countdownTask?.cancel()
        countdownTask = nil

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

        holdTask?.cancel()
        holdTask = nil

        countdownTask?.cancel()
        countdownTask = nil

        startCountdown()
    }


    func debugSkipToStarted() {

        holdTask?.cancel()
        holdTask = nil

        countdownTask?.cancel()
        countdownTask = nil

        currentStep =
            .started

        countdown =
            0

        hasStarted =
            true
    }

    #endif
}
