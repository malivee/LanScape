//
//  MovementHitboxLayout.swift
//  LanScape
//

import SwiftUI

struct MovementHitboxLayout {

    // =========================================================
    // MARK: - Main
    // =========================================================

    static func hitboxes(
        for movement: Int
    ) -> [MovementHitbox] {

        switch movement {

        case 1:
            return movement1()

        case 2:
            return movement2()

        case 3:
            return movement3()

        case 4:
            return movement4()

        case 5:
            return movement5()

        default:
            return movement1()
        }
    }


    // =========================================================
    // MARK: - Movement 1
    // =========================================================

    private static func movement1()
        -> [MovementHitbox]
    {

        [
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================

            // LEFT HAND — YELLOW

            MovementHitbox(
                id: 0,

                type:
                    .player1LeftHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.255
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT HAND — ORANGE

            MovementHitbox(
                id: 1,

                type:
                    .player1RightHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.515
                    ),

                normalizedRadius:
                    0.065
            ),


            // LEFT LEG — GREEN

            MovementHitbox(
                id: 2,

                type:
                    .player1LeftFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.385,
                        y: 0.875
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT LEG — PURPLE

            MovementHitbox(
                id: 3,

                type:
                    .player1RightFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.875
                    ),

                normalizedRadius:
                    0.065
            ),


            // =====================================================
            // PLAYER 2 — RIGHT SIDE
            // =====================================================

            // LEFT HAND — BLUE

            MovementHitbox(
                id: 4,

                type:
                    .player2LeftHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.255
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT HAND — CYAN

            MovementHitbox(
                id: 5,

                type:
                    .player2RightHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.515
                    ),

                normalizedRadius:
                    0.065
            ),


            // LEFT LEG — PURPLE

            MovementHitbox(
                id: 6,

                type:
                    .player2LeftFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.875
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT LEG — PINK

            MovementHitbox(
                id: 7,

                type:
                    .player2RightFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.610,
                        y: 0.875
                    ),

                normalizedRadius:
                    0.065
            )
        ]
    }


    // =========================================================
    // MARK: - Movement 2
    // =========================================================
    //
    // Based on the second movement image.
    //
    // PLAYER 1:
    //   left hand  -> upper left
    //   right hand -> middle left
    //   left foot  -> far left
    //   right foot -> center
    //
    // PLAYER 2:
    //   left hand  -> upper right
    //   right hand -> middle right
    //   left foot  -> center
    //   right foot -> far right
    // =========================================================

    private static func movement2()
        -> [MovementHitbox]
    {

        [
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================

            // LEFT HAND — YELLOW

            MovementHitbox(
                id: 0,

                type:
                    .player1LeftHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.338
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT HAND — ORANGE

            MovementHitbox(
                id: 1,

                type:
                    .player1RightHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.584
                    ),

                normalizedRadius:
                    0.065
            ),


            // LEFT LEG — GREEN

            MovementHitbox(
                id: 2,

                type:
                    .player1LeftFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.276,
                        y: 0.870
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT LEG — PURPLE

            MovementHitbox(
                id: 3,

                type:
                    .player1RightFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.470,
                        y: 0.870
                    ),

                normalizedRadius:
                    0.065
            ),


            // =====================================================
            // PLAYER 2 — RIGHT SIDE
            // =====================================================

            // LEFT HAND — BLUE

            MovementHitbox(
                id: 4,

                type:
                    .player2LeftHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.338
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT HAND — CYAN

            MovementHitbox(
                id: 5,

                type:
                    .player2RightHand,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.584
                    ),

                normalizedRadius:
                    0.065
            ),


            // LEFT LEG — PURPLE

            MovementHitbox(
                id: 6,

                type:
                    .player2LeftFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.525,
                        y: 0.870
                    ),

                normalizedRadius:
                    0.065
            ),


            // RIGHT LEG — PINK

            MovementHitbox(
                id: 7,

                type:
                    .player2RightFoot,

                normalizedPosition:
                    CGPoint(
                        x: 0.718,
                        y: 0.870
                    ),

                normalizedRadius:
                    0.065
            )
        ]
    }


    // =========================================================
    // MARK: - Movement 3
    // =========================================================

    private static func movement3()
        -> [MovementHitbox]
    {

        // Temporary:
        // Use Movement 2 until you provide the Movement 3 image.

        return movement2()
    }


    // =========================================================
    // MARK: - Movement 4
    // =========================================================

    private static func movement4()
        -> [MovementHitbox]
    {

        // Temporary:
        // Use Movement 2 until you provide the Movement 4 image.

        return movement2()
    }


    // =========================================================
    // MARK: - Movement 5
    // =========================================================

    private static func movement5()
        -> [MovementHitbox]
    {

        // Temporary:
        // Use Movement 2 until you provide the Movement 5 image.

        return movement2()
    }
}
