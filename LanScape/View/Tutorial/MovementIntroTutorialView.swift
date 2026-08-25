//
//  MovementIntroTutorialView.swift
//  LanScape
//

import SwiftUI

struct MovementIntroTutorialView:
    View {

    @ObservedObject
    var tutorial:
        MovementIntroTutorial


    let step:
        PoseStep


    var body:
        some View {

        ZStack {

            // =================================================
            // DARK OVERLAY
            // =================================================

            Color.black
                .opacity(0.60)
                .ignoresSafeArea()


            // =================================================
            // EXISTING MOVEMENT GUIDE
            // =================================================

            PoseGuideOverlayView(

                step:
                    step,

                isMatching:
                    false
            )
            .ignoresSafeArea()


            // =================================================
            // CENTER INSTRUCTION
            // =================================================

            VStack {

                Spacer()


                Text(
                    tutorial
                        .currentPage
                        .instruction
                )
                .font(
                    .system(
                        size:
                            36,

                        weight:
                            .bold,

                        design:
                            .rounded
                    )
                )
                .foregroundColor(
                    .white
                )
                .multilineTextAlignment(
                    .center
                )
                .lineSpacing(
                    6
                )
                .padding(
                    .horizontal,
                    120
                )


                Spacer()
            }


            // =================================================
            // PAGE INDICATOR
            // =================================================

            VStack {

                HStack {

                    Spacer()


                    Text(
                        "\(tutorial.currentPage.rawValue + 1)/2"
                    )
                    .font(
                        .system(
                            size:
                                16,

                            weight:
                                .bold,

                            design:
                                .rounded
                        )
                    )
                    .foregroundColor(
                        .white
                    )
                    .padding(
                        .horizontal,
                        12
                    )
                    .padding(
                        .vertical,
                        7
                    )
                    .background(
                        Color.black.opacity(
                            0.45
                        )
                    )
                    .clipShape(
                        Capsule()
                    )
                    .padding(
                        .top,
                        20
                    )
                    .padding(
                        .trailing,
                        25
                    )
                }


                Spacer()
            }


            // =================================================
            // TIMER / AUTO-ADVANCE BADGE
            // =================================================

            VStack {

                Spacer()


                HStack {

                    Spacer()


                    Button {

                        tutorial.next()

                    } label: {

                        HStack(spacing: 8) {

                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .bold))

                            Text("\(tutorial.currentPage.buttonTitle) (\(tutorial.timeRemaining)s)")
                                .font(
                                    .system(
                                        size:
                                            16,

                                        weight:
                                            .bold,

                                        design:
                                            .rounded
                                    )
                                )
                        }
                        .foregroundColor(
                            .white
                        )
                        .padding(
                            .horizontal,
                            24
                        )
                        .padding(
                            .vertical,
                            12
                        )
                        .background(
                            Color.black.opacity(
                                0.55
                            )
                        )
                        .clipShape(
                            Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    Color.white.opacity(0.35),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color:
                                .black.opacity(
                                    0.3
                                ),

                            radius:
                                10,

                            x:
                                0,

                            y:
                                4
                        )
                    }
                    .padding(
                        .trailing,
                        40
                    )
                    .padding(
                        .bottom,
                        30
                    )
                }
            }
        }
    }
}
