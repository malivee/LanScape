//
//  MovementHitboxLayout.swift
//  LanScape
//

import SwiftUI

struct MovementHitboxLayout {

    static func hitboxes()
        -> [MovementHitbox] {

        [

            // =================================================
            // PLAYER 1 — LEFT SIDE
            // =================================================

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
                    0.045
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
                    0.045
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
                    0.045
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
                    0.045
            ),


            // =================================================
            // PLAYER 2 — RIGHT SIDE
            // =================================================

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
                    0.045
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
                    0.045
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
                    0.045
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
                    0.045
            )
        ]
    }
}
