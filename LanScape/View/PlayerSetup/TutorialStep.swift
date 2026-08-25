import Foundation
import SwiftUI
import Vision
import Combine

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
            return "Mulai"
        }
    }

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

struct TutorialPlayerZone {

    let playerIndex: Int
    let rect: CGRect
    let state: TutorialRectangleState
}

@MainActor
final class TutorialController: ObservableObject {

    @Published private(set) var currentStep:
        TutorialStep = .playerSetup1

    @Published private(set) var player1State:
        TutorialRectangleState = .waiting

    @Published private(set) var player2State:
        TutorialRectangleState = .waiting

    @Published private(set) var countdown:
        Int = 3

    @Published private(set) var hasStarted =
        false

    private var readySince:
        Date?

    private var countdownWorkItem:
        DispatchWorkItem?

    var requiredReadyDuration:
        TimeInterval = 0.8

    func reset() {

        countdownWorkItem?.cancel()

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

    func updatePlayerStates(
        player1:
            TutorialRectangleState,

        player2:
            TutorialRectangleState
    ) {

        guard !hasStarted else {
            return
        }

        player1State =
            player1

        player2State =
            player2

        guard
            currentStep.requiresPositionValidation
        else {
            return
        }

        let bothCorrect =
            player1 == .correct &&
            player2 == .correct

        // Someone moved out of position.
        // Reset the stability timer.

        if !bothCorrect {

            readySince =
                nil

            return
        }

        // First frame where both are correct.

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

        advance()
    }

    private func advance() {

        guard !hasStarted else {
            return
        }

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

        case .countdown1,
             .countdown2,
             .countdown3,
             .started:

            break
        }
    }

    private func startCountdown() {

        currentStep =
            .countdown1

        countdown =
            3

        countdownWorkItem?.cancel()

        DispatchQueue.main.asyncAfter(
            deadline:
                .now() + 1
        ) { [weak self] in

            guard
                let self
            else {
                return
            }

            self.currentStep =
                .countdown2

            self.countdown =
                2
        }

        DispatchQueue.main.asyncAfter(
            deadline:
                .now() + 2
        ) { [weak self] in

            guard
                let self
            else {
                return
            }

            self.currentStep =
                .countdown3

            self.countdown =
                1
        }

        DispatchQueue.main.asyncAfter(
            deadline:
                .now() + 3
        ) { [weak self] in

            guard
                let self
            else {
                return
            }

            self.currentStep =
                .started

            self.hasStarted =
                true
        }
    }
}
