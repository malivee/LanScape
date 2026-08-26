//
//  MovementHitboxValidator.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 26/08/26.
//


import SwiftUI
import Vision

struct MovementHitboxValidator {

    // =========================================================
    // MARK: - Configuration
    // =========================================================

    /// Minimum Vision confidence required.
    static let minimumConfidence:
        Float = 0.15


    // =========================================================
    // MARK: - Validate All
    // =========================================================

    static func validate(

        people:
            [DetectedPerson],

        hitboxes:
            [MovementHitbox],

        viewSize:
            CGSize,

        videoSize:
            CGSize,

        convert:
            (CGPoint, CGSize, CGSize) -> CGPoint

    ) -> [HitboxResult] {

        hitboxes.map {

            validateHitbox(

                hitbox: $0,

                people:
                    people,

                viewSize:
                    viewSize,

                videoSize:
                    videoSize,

                convert:
                    convert
            )
        }
    }


    // =========================================================
    // MARK: - Validate One
    // =========================================================

    private static func validateHitbox(

        hitbox:
            MovementHitbox,

        people:
            [DetectedPerson],

        viewSize:
            CGSize,

        videoSize:
            CGSize,

        convert:
            (CGPoint, CGSize, CGSize) -> CGPoint

    ) -> HitboxResult {

        // -----------------------------------------------------
        // Find correct player.
        // -----------------------------------------------------

        guard
            let person =
                people.first(
                    where: {
                        $0.personIndex ==
                        hitbox.type.playerIndex
                    }
                )
        else {

            return HitboxResult(

                hitbox:
                    hitbox,

                isHit:
                    false,

                distance:
                    .greatestFiniteMagnitude
            )
        }


        // -----------------------------------------------------
        // Find EXACT required joint.
        // -----------------------------------------------------

        guard
            let joint =
                person.jointList.first(
                    where: {
                        $0.name ==
                        hitbox.type.jointName
                    }
                )
        else {

            return HitboxResult(

                hitbox:
                    hitbox,

                isHit:
                    false,

                distance:
                    .greatestFiniteMagnitude
            )
        }


        // -----------------------------------------------------
        // Confidence check.
        // -----------------------------------------------------

        guard
            joint.confidence >=
                minimumConfidence
        else {

            return HitboxResult(

                hitbox:
                    hitbox,

                isHit:
                    false,

                distance:
                    .greatestFiniteMagnitude
            )
        }


        // -----------------------------------------------------
        // Convert Vision coordinate.
        // -----------------------------------------------------

        let jointPoint =
            convert(

                joint.location,

                viewSize,

                videoSize
            )


        // -----------------------------------------------------
        // Convert hitbox position.
        // -----------------------------------------------------

        let targetPoint =
            CGPoint(

                x:
                    hitbox
                        .normalizedPosition
                        .x
                    *
                    viewSize.width,

                y:
                    hitbox
                        .normalizedPosition
                        .y
                    *
                    viewSize.height
            )


        // -----------------------------------------------------
        // Hitbox radius.
        // -----------------------------------------------------

        let radius =
            hitbox.normalizedRadius
            *
            min(
                viewSize.width,
                viewSize.height
            )


        // -----------------------------------------------------
        // Distance.
        // -----------------------------------------------------

        let distance =
            hypot(

                jointPoint.x -
                    targetPoint.x,

                jointPoint.y -
                    targetPoint.y
            )


        // -----------------------------------------------------
        // Hit.
        // -----------------------------------------------------

        let isHit =
            distance <= radius


        return HitboxResult(

            hitbox:
                hitbox,

            isHit:
                isHit,

            distance:
                distance
        )
    }
}
