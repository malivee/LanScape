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
            
            // LEFT HAND — RED CIRCLE
            
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
            
            
            // RIGHT HAND — YELLOW CIRCLE
            
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
            
            
            // LEFT LEG — RED SQUARE
            
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
            
            
            // RIGHT LEG — YELLOW SQUARE
            
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
            
            // LEFT HAND — GREEN CIRCLE
            
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
            
            
            // RIGHT HAND — CYAN CIRCLE
            
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
            
            
            // LEFT LEG — GREEN SQUARE
            
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
            
            
            // RIGHT LEG — CYAN SQUARE
            
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
    //   left hand  (Red Circle)    -> upper left
    //   right hand (Yellow Circle) -> middle left
    //   left foot  (Red Square)    -> far left
    //   right foot (Yellow Square) -> center
    //
    // PLAYER 2:
    //   left hand  (Green Circle)  -> upper right
    //   right hand (Cyan Circle)   -> middle right
    //   left foot  (Green Square)  -> center
    //   right foot (Cyan Square)   -> far right
    // =========================================================
    
    private static func movement2()
    -> [MovementHitbox]
    {
        
        [
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================
            
            // LEFT HAND — RED CIRCLE
            
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
            
            
            // RIGHT HAND — YELLOW CIRCLE
            
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
            
            
            // LEFT LEG — RED SQUARE
            
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
            
            
            // RIGHT LEG — YELLOW SQUARE
            
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
            
            // LEFT HAND — GREEN CIRCLE
            
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
            
            
            // RIGHT HAND — CYAN CIRCLE
            
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
            
            
            // LEFT LEG — GREEN SQUARE
            
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
            
            
            // RIGHT LEG — CYAN SQUARE
            
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
    
    
    
    private static func movement3()
    -> [MovementHitbox]
    {
        [
            
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================
            
            // LEFT HAND — RED
            // SWITCHED WITH YELLOW
            MovementHitbox(
                id: 0,
                type: .player1LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.100,
                    y: 0.331
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT HAND — YELLOW
            // SWITCHED WITH RED
            MovementHitbox(
                id: 1,
                type: .player1RightHand,
                normalizedPosition: CGPoint(
                    x: 0.484,
                    y: 0.156
                ),
                normalizedRadius: 0.065
            ),
            
            // LEFT LEG — RED
            MovementHitbox(
                id: 2,
                type: .player1LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.407,
                    y: 0.813
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT LEG — YELLOW
            MovementHitbox(
                id: 3,
                type: .player1RightFoot,
                normalizedPosition: CGPoint(
                    x: 0.289,
                    y: 0.813
                ),
                normalizedRadius: 0.065
            ),
            
            // =====================================================
            // PLAYER 2 — RIGHT SIDE
            // =====================================================
            
            // LEFT HAND — GREEN
            MovementHitbox(
                id: 4,
                type: .player2LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.519,
                    y: 0.156
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT HAND — CYAN
            MovementHitbox(
                id: 5,
                type: .player2RightHand,
                normalizedPosition: CGPoint(
                    x: 0.880,
                    y: 0.501
                ),
                normalizedRadius: 0.065
            ),
            
            // LEFT LEG — GREEN
            MovementHitbox(
                id: 6,
                type: .player2LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.567,
                    y: 0.833
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT LEG — CYAN
            MovementHitbox(
                id: 7,
                type: .player2RightFoot,
                normalizedPosition: CGPoint(
                    x: 0.684,
                    y: 0.833
                ),
                normalizedRadius: 0.065
            )
        ]
    }
    
    
    // =========================================================
    // MARK: - Movement 4
    // =========================================================
    
    private static func movement4()
    -> [MovementHitbox]
    {
        [
            
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================
            
            // LEFT HAND — RED
            // Hand extending toward left
            MovementHitbox(
                id: 0,
                type: .player1LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.491,
                    y: 0.137
                ),
                normalizedRadius: 0.065
            ),
            
            
            // RIGHT HAND — YELLOW
            // Hand raised toward the top center
            MovementHitbox(
                id: 1,
                type: .player1RightHand,
                normalizedPosition: CGPoint(
                    x: 0.408,
                    y: 0.318
                ),
                normalizedRadius: 0.065
            ),
            
            // LEFT FOOT — RED
            MovementHitbox(
                id: 2,
                type: .player1LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.446,
                    y: 0.788
                ),
                normalizedRadius: 0.065
            ),
            
            
            // RIGHT FOOT — YELLOW
            MovementHitbox(
                id: 3,
                type: .player1RightFoot,
                normalizedPosition: CGPoint(
                    x: 0.335,
                    y: 0.788
                ),
                normalizedRadius: 0.065
            ),
            
            
            // =====================================================
            // PLAYER 2 — RIGHT SIDE
            // =====================================================
            
            // LEFT HAND — GREEN
            // Raised toward the top center
            MovementHitbox(
                id: 4,
                type: .player2LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.573,
                    y: 0.404
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT HAND — CYAN
            // Extending toward the right
            MovementHitbox(
                id: 5,
                type: .player2RightHand,
                normalizedPosition: CGPoint(
                    x: 0.528,
                    y: 0.137
                    
                ),
                normalizedRadius: 0.065
            ),
            
            // LEFT FOOT — GREEN
            MovementHitbox(
                id: 6,
                type: .player2LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.654,
                    y: 0.788
                ),
                normalizedRadius: 0.065
            ),
            
            // RIGHT FOOT — CYAN
            MovementHitbox(
                id: 7,
                type: .player2RightFoot,
                normalizedPosition: CGPoint(
                    x: 0.564,
                    y: 0.788
                    
                ),
                normalizedRadius: 0.065
            )
        ]
    }
    
    
    // =========================================================
    // MARK: - Movement 5
    // =========================================================
    
    private static func movement5() -> [MovementHitbox] {
        [
            // =====================================================
            // PLAYER 1 — LEFT SIDE
            // =====================================================

            // LEFT HAND — RED
            MovementHitbox(
                id: 0,
                type: .player1LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.185,
                    y: 0.485
                ),
                normalizedRadius: 0.065
            ),

            // RIGHT HAND — YELLOW
            MovementHitbox(
                id: 1,
                type: .player1RightHand,
                normalizedPosition: CGPoint(
                    x: 0.410,
                    y: 0.430
              
                ),
                normalizedRadius: 0.065
            ),

            // LEFT FOOT — RED
            MovementHitbox(
                id: 2,
                type: .player1LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.160,
                    y: 0.790
                ),
                normalizedRadius: 0.065
            ),

            // RIGHT FOOT — YELLOW
            MovementHitbox(
                id: 3,
                type: .player1RightFoot,
                normalizedPosition: CGPoint(
 
                    x: 0.390,
                    y: 0.790
                ),
                normalizedRadius: 0.065
            ),


            // =====================================================
            // PLAYER 2 — RIGHT SIDE
            // =====================================================

            // LEFT HAND — GREEN
            MovementHitbox(
                id: 4,
                type: .player2LeftHand,
                normalizedPosition: CGPoint(
                    x: 0.590,
                    y: 0.430
                ),
                normalizedRadius: 0.065
            ),

            // RIGHT HAND — CYAN
            MovementHitbox(
                id: 5,
                type: .player2RightHand,
                normalizedPosition: CGPoint(
                    x: 0.815,
                    y: 0.335

                ),
                normalizedRadius: 0.065
            ),

            // LEFT FOOT — GREEN
            MovementHitbox(
                id: 6,
                type: .player2LeftFoot,
                normalizedPosition: CGPoint(
                    x: 0.610,
                    y: 0.790
                ),
                normalizedRadius: 0.065
            ),

            // RIGHT FOOT — CYAN
            MovementHitbox(
                id: 7,
                type: .player2RightFoot,
                normalizedPosition: CGPoint(

                    x: 0.840,
                    y: 0.790
                ),
                normalizedRadius: 0.065
            )
        ]
    }}
