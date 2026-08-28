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

        let isSquare = hitbox.shape == .square
        let size = radius * 2
        let cornerRadius: CGFloat = isSquare ? 18 : 0

        ZStack {

            // -------------------------------------------------
            // Outer glow
            // -------------------------------------------------

            if isSquare {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        hitbox.color.opacity(
                            isHit ? 0.60 : 0.40
                        )
                    )
                    .frame(
                        width: size * 1.35,
                        height: size * 1.35
                    )
                    .blur(
                        radius:
                            isHit ? 12 : 8
                    )
            } else {
                Circle()
                    .fill(
                        hitbox.color.opacity(
                            isHit ? 0.60 : 0.40
                        )
                    )
                    .frame(
                        width: size * 1.35,
                        height: size * 1.35
                    )
                    .blur(
                        radius:
                            isHit ? 12 : 8
                    )
            }


            // -------------------------------------------------
            // Main hitbox rim & translucent backing
            // -------------------------------------------------

            if isSquare {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        hitbox.color.opacity(
                            isHit ? 0.40 : 0.20
                        )
                    )
                    .frame(
                        width: size,
                        height: size
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isHit
                                ? Color.green
                                : hitbox.color,

                                lineWidth:
                                    isHit ? 6 : 4.5
                            )
                            .shadow(
                                color: (isHit ? Color.green : hitbox.color).opacity(0.8),
                                radius: 6
                            )
                    }
            } else {
                Circle()
                    .fill(
                        hitbox.color.opacity(
                            isHit ? 0.40 : 0.20
                        )
                    )
                    .frame(
                        width: size,
                        height: size
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                isHit
                                ? Color.green
                                : hitbox.color,

                                lineWidth:
                                    isHit ? 6 : 4.5
                            )
                            .shadow(
                                color: (isHit ? Color.green : hitbox.color).opacity(0.8),
                                radius: 6
                            )
                    }
            }


            // -------------------------------------------------
            // Center Core
            // -------------------------------------------------

            let centerRatio: CGFloat = isHit ? 0.65 : 0.56
            let centerSize = size * centerRatio * 0.5

            if isSquare {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isHit
                        ? Color.white
                        : Color.white.opacity(0.88)
                    )
                    .frame(
                        width: centerSize,
                        height: centerSize
                    )
                    .shadow(
                        color: Color.white.opacity(0.9),
                        radius: 6
                    )
            } else {
                Circle()
                    .fill(
                        isHit
                        ? Color.white
                        : Color.white.opacity(0.88)
                    )
                    .frame(
                        width: centerSize,
                        height: centerSize
                    )
                    .shadow(
                        color: Color.white.opacity(0.9),
                        radius: 6
                    )
            }


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
                            radius * 0.50,

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
