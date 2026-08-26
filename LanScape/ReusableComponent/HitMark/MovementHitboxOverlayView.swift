import SwiftUI

struct MovementHitboxOverlayView: View {

    let hitboxes:
        [MovementHitbox]

    let results:
        [HitboxResult]

    let viewSize:
        CGSize


    var body: some View {

        ZStack {

            ForEach(hitboxes) { hitbox in

                let result =
                    results.first {
                        $0.hitbox.id ==
                        hitbox.id
                    }

                hitboxView(

                    hitbox:
                        hitbox,

                    isHit:
                        result?.isHit ?? false
                )
            }
        }
        .allowsHitTesting(false)
    }


    // =========================================================
    // MARK: - Hitbox View
    // =========================================================

    @ViewBuilder
    private func hitboxView(

        hitbox:
            MovementHitbox,

        isHit:
            Bool

    ) -> some View {

        let radius =
            hitbox.normalizedRadius
            *
            min(
                viewSize.width,
                viewSize.height
            )


        ZStack {

            // -------------------------------------------------
            // Outer glow
            // -------------------------------------------------

            Circle()
                .fill(
                    hitbox.color.opacity(
                        isHit
                        ? 0.40
                        : 0.16
                    )
                )
                .frame(
                    width:
                        radius * 2,

                    height:
                        radius * 2
                )
                .blur(
                    radius:
                        isHit ? 8 : 4
                )


            // -------------------------------------------------
            // Main hitbox
            // -------------------------------------------------

            Circle()
                .fill(
                    hitbox.color.opacity(
                        isHit
                        ? 0.35
                        : 0.12
                    )
                )
                .frame(
                    width:
                        radius * 2,

                    height:
                        radius * 2
                )
                .overlay {

                    Circle()
                        .stroke(
                            isHit
                            ? Color.green
                            : hitbox.color,

                            lineWidth:
                                isHit
                                ? 7
                                : 4
                        )
                }


            // -------------------------------------------------
            // Center
            // -------------------------------------------------

            Circle()
                .fill(
                    isHit
                    ? Color.white
                    : hitbox.color
                )
                .frame(
                    width:
                        radius * (
                            isHit
                            ? 0.55
                            : 0.42
                        ),

                    height:
                        radius * (
                            isHit
                            ? 0.55
                            : 0.42
                        )
                )


            // -------------------------------------------------
            // Checkmark
            // -------------------------------------------------

            if isHit {

                Image(
                    systemName:
                        "checkmark"
                )
                .font(
                    .system(
                        size:
                            radius * 0.45,

                        weight:
                            .black
                    )
                )
                .foregroundColor(
                    .green
                )
            }
        }
        .position(

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
        .shadow(

            color:
                hitbox.color.opacity(
                    isHit
                    ? 0.9
                    : 0.5
                ),

            radius:
                isHit
                ? 18
                : 8
        )
        .animation(
            .easeInOut(
                duration: 0.12
            ),
            value: isHit
        )
    }
}
