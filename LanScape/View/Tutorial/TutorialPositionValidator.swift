//
//  TutorialPositionValidator.swift
//  LanScape
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
        person: DetectedPerson?,
        targetRect: CGRect,
        viewSize: CGSize,
        videoSize: CGSize,
        convert: (CGPoint, CGSize, CGSize) -> CGPoint
    ) -> TutorialRectangleState {

        guard let person else {
            return .waiting
        }

        let points = (person.jointList.isEmpty ? person.filteredJointList : person.jointList)
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

        let centerInside = targetRect.contains(center)

        let insideCount = points.filter { targetRect.contains($0) }.count
        let insideRatio = CGFloat(insideCount) / CGFloat(points.count)

        let enoughInside = insideRatio >= 0.75

        if centerInside && enoughInside {
            return .correct
        }

        return .incorrect
    }
}
