//
//  PoseTrackingView.swift
//  LanScape
//

import SwiftUI
import UIKit
import AVFoundation

struct PoseTrackingView: View {

    // =========================================================
    // MARK: - Services
    // =========================================================

    @StateObject
    private var visionService = VisionService()

    @StateObject
    private var tutorialController = TutorialController()

    // =========================================================
    // MARK: - Environment
    // =========================================================

    @Environment(\.dismiss)
    private var dismiss

    // =========================================================
    // MARK: - Body
    // =========================================================

    var body: some View {
        ZStack {
            // =================================================
            // CAMERA
            // =================================================
            CameraPreviewView(
                session: visionService.captureSession,
                onOrientationChanged: { newOrientation in
                    visionService.updateVideoOrientation(newOrientation)
                }
            )
            .ignoresSafeArea()

            // =================================================
            // SKELETON / 8-JOINT OVERLAY (4 per player)
            // =================================================
            PoseSkeletonOverlayView(
                detectedPeople: visionService.poseModel.detectedPeople,
                videoSize: visionService.poseModel.videoSize
            )
            .ignoresSafeArea()

            // =================================================
            // GAME FLOW / PHASES
            // =================================================
            if !tutorialController.hasStarted {
                // Player Setup & Countdown Phase
                tutorialPhase
            } else {
                // Live 8-Joint Tracking Phase
                trackingPhase
            }

            // =================================================
            // DEBUG CONTROLS
            // =================================================
            testControlsOverlay
        }
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
    }

    // =========================================================
    // MARK: - Tutorial / Player Setup Phase
    // =========================================================

    @ViewBuilder
    private var tutorialPhase: some View {
        GeometryReader { geometry in
            TutorialOverlayView(
                tutorial: tutorialController,
                detectedPeople: visionService.poseModel.detectedPeople,
                videoSize: visionService.poseModel.videoSize,
                viewSize: geometry.size
            )
        }
        .ignoresSafeArea()
    }

    // =========================================================
    // MARK: - Active Tracking Phase
    // =========================================================

    @ViewBuilder
    private var trackingPhase: some View {
        ZStack {
            // Center Divider
            CenterDividerLineView()
                .ignoresSafeArea()

            // Header & Tracking HUD
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Close / Exit Button
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)

                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // HUD showing status & joint counts for Player 1 & Player 2
                let p1 = visionService.poseModel.detectedPeople.first { $0.personIndex == 0 }
                let p2 = visionService.poseModel.detectedPeople.first { $0.personIndex == 1 }

                PoseStatusHudView(
                    p1JointCount: p1?.filteredJointList.count ?? 0,
                    p2JointCount: p2?.filteredJointList.count ?? 0,
                    isP1Detected: p1 != nil,
                    isP2Detected: p2 != nil
                )
                .padding(.top, 8)

                Spacer()
            }
        }
    }

    // =========================================================
    // MARK: - Appear / Disappear
    // =========================================================

    private func handleAppear() {
        forceLandscape()
        tutorialController.reset()
        visionService.startSession()
    }

    private func handleDisappear() {
        visionService.stopSession()
    }

    // =========================================================
    // MARK: - Landscape Orientation
    // =========================================================

    private func forceLandscape() {
        UIDevice.current.setValue(
            UIInterfaceOrientation.landscapeLeft.rawValue,
            forKey: "orientation"
        )

        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            if #available(iOS 16.0, *) {
                let preferences = UIWindowScene.GeometryPreferences.iOS(
                    interfaceOrientations: .landscape
                )
                windowScene.requestGeometryUpdate(preferences) { error in
                    print("Landscape rotation error:", error.localizedDescription)
                }
            }
        }

        UIViewController.attemptRotationToDeviceOrientation()
    }

    // =========================================================
    // MARK: - Debug Overlay
    // =========================================================

    #if DEBUG
    private var testControlsOverlay: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Menu {
                    Button("1. Player Setup") {
                        tutorialController.debugSetStep(.playerSetup)
                    }

                    Button("2. Countdown 3") {
                        tutorialController.debugSetStep(.countdown3)
                    }

                    Button("3. Start Tracking (Skip)") {
                        tutorialController.debugSkipToStarted()
                    }

                    Divider()

                    Button("Reset Everything") {
                        tutorialController.reset()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "ladybug")
                        Text(debugPhaseName)
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var debugPhaseName: String {
        if tutorialController.hasStarted {
            return "Live Tracking"
        }
        return tutorialController.currentStep.title
    }
    #else
    private var testControlsOverlay: some View {
        EmptyView()
    }
    #endif
}

// =============================================================
// MARK: - Preview
// =============================================================

#Preview("Pose Tracking View") {
    PoseTrackingView()
        .previewInterfaceOrientation(.landscapeLeft)
}
