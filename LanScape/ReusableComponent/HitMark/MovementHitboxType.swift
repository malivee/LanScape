//
//  MovementHitboxType.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 26/08/26.
//


import SwiftUI
import Vision

// MARK: - Hitbox Type

enum MovementHitboxType {

    case player1LeftHand
    case player1RightHand
    case player1LeftFoot
    case player1RightFoot

    case player2LeftHand
    case player2RightHand
    case player2LeftFoot
    case player2RightFoot
}

// MARK: - Hitbox Mapping

extension MovementHitboxType {

    // MARK: Player

    var playerIndex: Int {

        switch self {

        case .player1LeftHand,
             .player1RightHand,
             .player1LeftFoot,
             .player1RightFoot:

            return 0

        case .player2LeftHand,
             .player2RightHand,
             .player2LeftFoot,
             .player2RightFoot:

            return 1
        }
    }

    // MARK: Joint

    var jointName:
        VNHumanBodyPoseObservation.JointName {

        switch self {

        case .player1LeftHand,
             .player2LeftHand:

            return .leftWrist

        case .player1RightHand,
             .player2RightHand:

            return .rightWrist

        case .player1LeftFoot,
             .player2LeftFoot:

            return .leftAnkle

        case .player1RightFoot,
             .player2RightFoot:

            return .rightAnkle
        }
    }

    // MARK: Shared Color

    /// Gets the exact same color used by
    /// the Vision joint overlay.

    var color: Color {

        PoseBodyDefinitions.jointColor(
            for: jointName,
            personIndex: playerIndex
        )
    }
}

// MARK: - Movement Hitbox

struct MovementHitbox: Identifiable {

    let id: Int

    let type:
        MovementHitboxType

    /// 0...1 normalized screen position.
    let normalizedPosition: CGPoint

    /// Radius as a percentage of the smaller
    /// screen dimension.
    let normalizedRadius: CGFloat

    /// Automatically comes from MovementHitboxType.
    let color: Color

    init(
        id: Int,
        type: MovementHitboxType,
        normalizedPosition: CGPoint,
        normalizedRadius: CGFloat
    ) {

        self.id = id
        self.type = type
        self.normalizedPosition =
            normalizedPosition
        self.normalizedRadius =
            normalizedRadius

        self.color =
            type.color
    }
}

// MARK: - Hitbox Result

struct HitboxResult {

    let hitbox:
        MovementHitbox

    let isHit:
        Bool

    let distance:
        CGFloat
}
