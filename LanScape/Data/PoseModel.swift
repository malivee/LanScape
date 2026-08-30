//
//  PoseModel.swift
//  LanScape
//

import Foundation
import CoreGraphics
import Vision
import SwiftUI
import Combine

// =============================================================
// MARK: - Player Role
// =============================================================

public enum PlayerRole: String, CaseIterable {

    case player1 = "Player 1"
    case player2 = "Player 2"

    // ---------------------------------------------------------
    // Backward compatibility
    // ---------------------------------------------------------

    public static var upperBody: PlayerRole {
        .player1
    }

    public static var lowerBody: PlayerRole {
        .player2
    }

    public static var fullBody: PlayerRole {
        .player1
    }

    // ---------------------------------------------------------
    // Display title
    // ---------------------------------------------------------

    public var title: String {

        switch self {

        case .player1:
            return "Orang 1"

        case .player2:
            return "Orang 2"
        }
    }

    // ---------------------------------------------------------
    // Main player color
    // ---------------------------------------------------------

    public var primaryColor: Color {

        switch self {

        case .player1:
            return Color(hex: "FFD84D")

        case .player2:
            return Color(hex: "00D2FF")
        }
    }

    // ---------------------------------------------------------
    // Connections
    // ---------------------------------------------------------

    public var connections:
        [
            (
                VNHumanBodyPoseObservation.JointName,
                VNHumanBodyPoseObservation.JointName
            )
        ] {

        []
    }

    // ---------------------------------------------------------
    // Relevant joints
    // ---------------------------------------------------------

    public var relevantJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

        PoseBodyDefinitions.trackedJoints
    }
}


// =============================================================
// MARK: - Joint Shape
// =============================================================

public enum JointShape {

    case circle
    case square
}


// =============================================================
// MARK: - Pose Body Definitions
// =============================================================

public struct PoseBodyDefinitions {

    // ---------------------------------------------------------
    // Gameplay joints
    //
    // leftWrist  = left hand
    // rightWrist = right hand
    // leftAnkle  = left leg
    // rightAnkle = right leg
    // ---------------------------------------------------------

    public static let trackedJoints:
        Set<VNHumanBodyPoseObservation.JointName> = [

        .leftWrist,
        .rightWrist,
        .leftAnkle,
        .rightAnkle
    ]

    public static var allJoints:
        Set<VNHumanBodyPoseObservation.JointName> {

        trackedJoints
    }


    // =========================================================
    // MARK: - Joint Shape
    // =========================================================

    public static func jointShape(
        for joint: VNHumanBodyPoseObservation.JointName
    ) -> JointShape {

        switch joint {

        // Hands
        case .leftWrist,
             .rightWrist:

            return .circle

        // Legs
        case .leftAnkle,
             .rightAnkle:

            return .square

        default:

            return .circle
        }
    }


    // =========================================================
    // MARK: - Shared Joint Color
    // =========================================================
    //
    // THIS IS THE SINGLE SOURCE OF TRUTH.
    //
    // Vision overlay and hitboxes both use this function.
    //
    // PLAYER 1:
    //
    // LEFT  = RED
    // RIGHT = YELLOW
    //
    // PLAYER 2:
    //
    // LEFT  = GREEN
    // RIGHT = CYAN
    //
    // =========================================================

    public static func jointColor(
        for joint:
            VNHumanBodyPoseObservation.JointName,
        personIndex: Int
    ) -> Color {

        // =====================================================
        // PLAYER 1
        //
        // Left  -> RED
        // Right -> YELLOW
        // =====================================================

        if personIndex == 0 {

            switch joint {

            // -------------------------------------------------
            // LEFT SIDE
            // -------------------------------------------------

            case .leftWrist,
                 .leftAnkle:

                return Color(hex: "FF3B30")


            // -------------------------------------------------
            // RIGHT SIDE
            // -------------------------------------------------

            case .rightWrist,
                 .rightAnkle:

                return Color(hex: "FFD84D")


            // -------------------------------------------------
            // Fallback
            // -------------------------------------------------

            default:

                return Color(hex: "FF3B30")
            }
        }


        // =====================================================
        // PLAYER 2
        //
        // Left  -> GREEN
        // Right -> CYAN
        // =====================================================

        switch joint {

        // -----------------------------------------------------
        // LEFT SIDE
        // -----------------------------------------------------

        case .leftWrist,
             .leftAnkle:

            return Color(hex: "34C759")


        // -----------------------------------------------------
        // RIGHT SIDE
        // -----------------------------------------------------

        case .rightWrist,
             .rightAnkle:

            return Color(hex: "00D2FF")


        // -----------------------------------------------------
        // Fallback
        // -----------------------------------------------------

        default:

            return Color(hex: "34C759")
        }
    }
}


// =============================================================
// MARK: - Joint Point
// =============================================================

public struct JointPoint: Identifiable {

    public let id = UUID()

    public let name:
        VNHumanBodyPoseObservation.JointName

    public let location:
        CGPoint

    public let confidence:
        Float


    public init(
        name:
            VNHumanBodyPoseObservation.JointName,

        location:
            CGPoint,

        confidence:
            Float
    ) {

        self.name =
            name

        self.location =
            location

        self.confidence =
            confidence
    }


    // ---------------------------------------------------------
    // Shape
    // ---------------------------------------------------------

    public var shape:
        JointShape {

        PoseBodyDefinitions.jointShape(
            for: name
        )
    }


    // ---------------------------------------------------------
    // Display name
    // ---------------------------------------------------------

    public var displayName:
        String {

        switch name {

        case .rightWrist:

            return "Right Hand"

        case .leftWrist:

            return "Left Hand"

        case .rightAnkle:

            return "Right Leg"

        case .leftAnkle:

            return "Left Leg"

        default:

            return name.rawValue.rawValue
        }
    }
}


// =============================================================
// MARK: - Detected Person
// =============================================================

public struct DetectedPerson: Identifiable {

    public let id =
        UUID()

    public let personIndex:
        Int

    public let joints:
        [
            VNHumanBodyPoseObservation.JointName:
                CGPoint
        ]

    public let jointList:
        [JointPoint]


    public init(
        personIndex:
            Int,

        joints:
            [
                VNHumanBodyPoseObservation.JointName:
                    CGPoint
            ],

        jointList:
            [JointPoint]
    ) {

        self.personIndex =
            personIndex

        self.joints =
            joints

        self.jointList =
            jointList
    }


    // =========================================================
    // MARK: - Player Role
    // =========================================================

    public var role:
        PlayerRole {

        switch personIndex {

        case 0:

            return .player1

        case 1:

            return .player2

        default:

            return .player1
        }
    }


    // =========================================================
    // MARK: - Connections
    // =========================================================

    public var activeConnections:
        [
            (
                VNHumanBodyPoseObservation.JointName,
                VNHumanBodyPoseObservation.JointName
            )
        ] {

        role.connections
    }


    // =========================================================
    // MARK: - Filtered Gameplay Joints
    // =========================================================

    public var filteredJointList:
        [JointPoint] {

        let allowedJoints =
            role.relevantJoints

        return jointList.filter {

            allowedJoints.contains(
                $0.name
            )
        }
    }


    // =========================================================
    // MARK: - Joint Shape
    // =========================================================

    public func jointShape(
        for joint:
            VNHumanBodyPoseObservation.JointName
    ) -> JointShape {

        PoseBodyDefinitions.jointShape(
            for: joint
        )
    }


    // =========================================================
    // MARK: - Joint Color
    // =========================================================

    public func jointColor(
        for joint:
            VNHumanBodyPoseObservation.JointName
    ) -> Color {

        PoseBodyDefinitions.jointColor(
            for: joint,
            personIndex:
                personIndex
        )
    }
}


// =============================================================
// MARK: - Pose Model
// =============================================================

public final class PoseModel:
    ObservableObject {

    @Published
    public var detectedPeople:
        [DetectedPerson] = []


    @Published
    public var videoSize:
        CGSize =
        CGSize(
            width: 1920,
            height: 1080
        )


    public init(
        detectedPeople:
            [DetectedPerson] = [],

        videoSize:
            CGSize =
            CGSize(
                width: 1920,
                height: 1080
            )
    ) {

        self.detectedPeople =
            detectedPeople

        self.videoSize =
            videoSize
    }
}
