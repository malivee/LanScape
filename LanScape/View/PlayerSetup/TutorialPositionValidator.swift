//
//  TutorialPositionValidator.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 25/08/26.
//


import Foundation
import Vision

struct TutorialPositionValidator {

    /// Checks whether a detected person is correctly
    /// positioned inside the specified rectangle.
    ///
    /// We don't require every joint to be inside.
    /// This makes the system more tolerant of Vision noise.

    static func validate(
        person:
            DetectedPerson?,

        targetRect:
            CGRect,

        viewSize:
            CGSize,

        videoSize:
            CGSize,

        convert:
            (CGPoint, CGSize, CGSize) -> CGPoint
    ) -> TutorialRectangleState {

        // ---------------------------------------------------------
        // No person detected
        // ---------------------------------------------------------

        guard
            let person
        else {

            return .waiting
        }

        // ---------------------------------------------------------
        // Get detected joints
        // ---------------------------------------------------------

        let points =
            (person.jointList.isEmpty ? person.filteredJointList : person.jointList)
                .map {

                    convert(
                        $0.location,
                        viewSize,
                        videoSize
                    )
                }

        guard
            !points.isEmpty
        else {

            return .waiting
        }

        // ---------------------------------------------------------
        // Calculate bounding box
        // ---------------------------------------------------------

        let xValues =
            points.map {
                $0.x
            }

        let yValues =
            points.map {
                $0.y
            }

        guard
            let minX =
                xValues.min(),

            let maxX =
                xValues.max(),

            let minY =
                yValues.min(),

            let maxY =
                yValues.max()
        else {

            return .waiting
        }

        let boundingBox =
            CGRect(
                x:
                    minX,

                y:
                    minY,

                width:
                    maxX - minX,

                height:
                    maxY - minY
            )

        // ---------------------------------------------------------
        // Center of person
        // ---------------------------------------------------------

        let center =
            CGPoint(
                x:
                    boundingBox.midX,

                y:
                    boundingBox.midY
            )

        // ---------------------------------------------------------
        // Center must be inside
        // ---------------------------------------------------------

        let centerInside =
            targetRect.contains(
                center
            )

        // ---------------------------------------------------------
        // Calculate percentage of joints inside
        // ---------------------------------------------------------

        let insideCount =
            points.filter {
                targetRect.contains(
                    $0
                )
            }
            .count

        let insideRatio =
            CGFloat(
                insideCount
            )
            /
            CGFloat(
                points.count
            )

        // ---------------------------------------------------------
        // Require 75% of joints inside
        // ---------------------------------------------------------

        let enoughInside =
            insideRatio >= 0.75

        if centerInside &&
            enoughInside {

            return .correct
        }

        return .incorrect
    }
}