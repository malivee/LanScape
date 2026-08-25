//
//  MovementIntroTutorial.swift
//  LanScape
//

import SwiftUI
import Combine

// MARK: - Movement Intro Page

enum MovementIntroPage: Int, CaseIterable {

    case followMovement = 0
    case moveCloser

    var instruction: String {

        switch self {

        case .followMovement:
            return "Ikuti gerakan yang muncul di layar masing-masing."

        case .moveCloser:
            return "Makin mirip pose contoh, makin ke tengah!"
        }
    }

    var buttonTitle: String {

        switch self {

        case .followMovement:
            return "Lanjut"

        case .moveCloser:
            return "Mengerti"
        }
    }
}


// MARK: - Movement Intro Tutorial

@MainActor
final class MovementIntroTutorial:
    ObservableObject {

    @Published
    private(set) var currentPage:
        MovementIntroPage = .followMovement

    @Published
    private(set) var isShowing:
        Bool = false

    @Published
    private(set) var timeRemaining:
        Int = 4

    private var timerTask:
        Task<Void, Never>?


    // =========================================================
    // MARK: Start
    // =========================================================

    func start() {

        currentPage =
            .followMovement

        timeRemaining =
            4

        withAnimation(
            .easeInOut(
                duration:
                    0.25
            )
        ) {

            isShowing =
                true
        }

        startTimer()
    }


    // =========================================================
    // MARK: Timer (4 Detik)
    // =========================================================

    private func startTimer() {

        timerTask?.cancel()
        timerTask = nil
        timeRemaining = 4

        timerTask = Task { @MainActor [weak self] in

            guard let self else { return }

            for second in (1...4).reversed() {

                self.timeRemaining = second

                do {
                    try await Task.sleep(
                        nanoseconds: 1_000_000_000
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
            }

            self.next()
        }
    }


    // =========================================================
    // MARK: Next
    // =========================================================

    func next() {

        timerTask?.cancel()
        timerTask = nil

        switch currentPage {

        case .followMovement:

            withAnimation(
                .easeInOut(
                    duration:
                        0.25
                )
            ) {

                currentPage =
                    .moveCloser
            }

            startTimer()


        case .moveCloser:

            finish()
        }
    }


    // =========================================================
    // MARK: Finish
    // =========================================================

    func finish() {

        timerTask?.cancel()
        timerTask = nil

        withAnimation(
            .easeOut(
                duration:
                    0.25
            )
        ) {

            isShowing =
                false
        }
    }


    // =========================================================
    // MARK: Reset
    // =========================================================

    func reset() {

        timerTask?.cancel()
        timerTask = nil

        currentPage =
            .followMovement

        timeRemaining =
            4

        isShowing =
            false
    }
}
