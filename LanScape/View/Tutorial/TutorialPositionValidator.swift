//
//  RectangleProgressShape 2.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 29/08/26.
//


import Foundation
import Vision
import SwiftUI

// ============================================================
// RectangleProgressShape
// ============================================================

struct RectangleProgressShape: Shape {

    var progress: CGFloat
    var cornerRadius: CGFloat = 14

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {

        let p = min(max(progress, 0), 1)

        let radius = min(
            cornerRadius,
            min(rect.width, rect.height) / 2
        )

        let top = rect.minY
        let bottom = rect.maxY
        let left = rect.minX
        let right = rect.maxX

        let width = rect.width
        let height = rect.height

        // Total perimeter
        let perimeter =
            (width - 2 * radius) +
            (height - 2 * radius) +
            (width - 2 * radius) +
            (height - 2 * radius) +
            (2 * .pi * radius)

        let targetLength = perimeter * p

        var path = Path()

        // =====================================================
        // START = TOP CENTER
        // Direction:
        // TOP → RIGHT → BOTTOM → LEFT → TOP
        // =====================================================

        let startX = rect.midX

        path.move(
            to: CGPoint(
                x: startX,
                y: top
            )
        )

        var remaining = targetLength

        // -----------------------------------------------------
        // 1. TOP CENTER → TOP RIGHT
        // -----------------------------------------------------

        let topRightDistance = right - startX - radius

        if remaining > 0 {

            let length = min(
                remaining,
                topRightDistance
            )

            path.addLine(
                to: CGPoint(
                    x: startX + length,
                    y: top
                )
            )

            remaining -= length
        }

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 2. TOP-RIGHT CORNER
        // -----------------------------------------------------

        let cornerLength = .pi * radius / 2

        let length2 = min(
            remaining,
            cornerLength
        )

        let angle = -Double.pi / 2 +
            (Double.pi / 2) *
            Double(length2 / cornerLength)

        path.addArc(
            center: CGPoint(
                x: right - radius,
                y: top + radius
            ),
            radius: radius,
            startAngle: .radians(angle - (.pi / 2) * 0),
            endAngle: .radians(angle),
            clockwise: false
        )

        remaining -= length2

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 3. RIGHT SIDE
        // -----------------------------------------------------

        let rightDistance =
            height - 2 * radius

        let length3 = min(
            remaining,
            rightDistance
        )

        path.addLine(
            to: CGPoint(
                x: right,
                y: top + radius + length3
            )
        )

        remaining -= length3

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 4. BOTTOM-RIGHT CORNER
        // -----------------------------------------------------

        let length4 = min(
            remaining,
            cornerLength
        )

        let fraction4 =
            Double(length4 / cornerLength)

        path.addArc(
            center: CGPoint(
                x: right - radius,
                y: bottom - radius
            ),
            radius: radius,
            startAngle: .radians(0),
            endAngle: .radians(
                fraction4 * (.pi / 2)
            ),
            clockwise: false
        )

        remaining -= length4

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 5. BOTTOM → LEFT
        // -----------------------------------------------------

        let bottomDistance =
            width - 2 * radius

        let length5 = min(
            remaining,
            bottomDistance
        )

        path.addLine(
            to: CGPoint(
                x: right - radius - length5,
                y: bottom
            )
        )

        remaining -= length5

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 6. BOTTOM-LEFT CORNER
        // -----------------------------------------------------

        let length6 = min(
            remaining,
            cornerLength
        )

        let fraction6 =
            Double(length6 / cornerLength)

        path.addArc(
            center: CGPoint(
                x: left + radius,
                y: bottom - radius
            ),
            radius: radius,
            startAngle: .radians(.pi / 2),
            endAngle: .radians(
                .pi / 2 + fraction6 * (.pi / 2)
            ),
            clockwise: false
        )

        remaining -= length6

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 7. LEFT SIDE
        // -----------------------------------------------------

        let leftDistance =
            height - 2 * radius

        let length7 = min(
            remaining,
            leftDistance
        )

        path.addLine(
            to: CGPoint(
                x: left,
                y: bottom - radius - length7
            )
        )

        remaining -= length7

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 8. TOP-LEFT CORNER
        // -----------------------------------------------------

        let length8 = min(
            remaining,
            cornerLength
        )

        let fraction8 =
            Double(length8 / cornerLength)

        path.addArc(
            center: CGPoint(
                x: left + radius,
                y: top + radius
            ),
            radius: radius,
            startAngle: .radians(.pi),
            endAngle: .radians(
                .pi + fraction8 * (.pi / 2)
            ),
            clockwise: false
        )

        remaining -= length8

        if remaining <= 0 {
            return path
        }

        // -----------------------------------------------------
        // 9. TOP-LEFT → TOP CENTER
        // -----------------------------------------------------

        let finalDistance =
            startX - left - radius

        let finalLength = min(
            remaining,
            finalDistance
        )

        path.addLine(
            to: CGPoint(
                x: left + radius + finalLength,
                y: top
            )
        )

        return path
    }
}

struct TutorialPositionValidator {

    static func validate(
        person: DetectedPerson?,
        targetRect: CGRect,
        viewSize: CGSize,
        videoSize: CGSize,
        convert: (CGPoint, CGSize, CGSize) -> CGPoint
    ) -> TutorialRectangleState {

        guard let person else {
            return .waiting
        }

        let points =
            (person.jointList.isEmpty
             ? person.filteredJointList
             : person.jointList)
            .map {
                convert(
                    $0.location,
                    viewSize,
                    videoSize
                )
            }

        guard !points.isEmpty else {
            return .waiting
        }

        let xValues = points.map { $0.x }
        let yValues = points.map { $0.y }

        guard
            let minX = xValues.min(),
            let maxX = xValues.max(),
            let minY = yValues.min(),
            let maxY = yValues.max()
        else {
            return .waiting
        }

        let boundingBox = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        let center = CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )

        let centerInside =
            targetRect.contains(center)

        let insideCount =
            points.filter {
                targetRect.contains($0)
            }.count

        let insideRatio =
            CGFloat(insideCount) /
            CGFloat(points.count)

        let enoughInside =
            insideRatio >= 0.75

        if centerInside && enoughInside {
            return .correct
        }

        return .incorrect(count: 0)
    }
}
