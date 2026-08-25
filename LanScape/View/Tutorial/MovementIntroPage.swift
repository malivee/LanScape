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


    // =========================================================
    // MARK: Start
    // =========================================================

    func start() {

        currentPage =
            .followMovement

        withAnimation(
            .easeInOut(
                duration:
                    0.25
            )
        ) {

            isShowing =
                true
        }
    }


    // =========================================================
    // MARK: Next
    // =========================================================

    func next() {

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


        case .moveCloser:

            finish()
        }
    }


    // =========================================================
    // MARK: Finish
    // =========================================================

    func finish() {

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

        currentPage =
            .followMovement

        isShowing =
            false
    }
}
