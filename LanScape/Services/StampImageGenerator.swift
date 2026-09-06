//
//  StampImageGenerator.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//


//
//  StampImageGenerator.swift
//  LanScape
//

import UIKit
import ImagePlayground

@available(iOS 26.0, *)
@MainActor
final class StampImageGenerator {

    func generateImage(
        prompt: String
    ) async throws -> UIImage {

        let cleanedPrompt =
            prompt.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedPrompt.isEmpty else {
            throw StampGenerationError.emptyMessage
        }

        print("================================")
        print("🎨 IMAGE GENERATION STARTED")
        print("================================")

        print("📝 Prompt:")
        print(cleanedPrompt)


        // =============================================================
        // IMAGE CREATOR
        // =============================================================

        let creator =
            try await ImageCreator()


        let availableStyles =
            creator.availableStyles


        print("🎨 Available styles:")

        for style in availableStyles {
            print(style)
        }


        guard !availableStyles.isEmpty else {

            print("❌ No styles available.")

            throw StampGenerationError
                .noAvailableStyle
        }


        // =============================================================
        // SELECT STYLE
        // =============================================================

        let style =
            availableStyles.first(
                where: {
                    $0 == .illustration
                }
            )
            ??
            availableStyles.first(
                where: {
                    $0 == .sketch
                }
            )
            ??
            availableStyles.first!


        print("🎨 Selected style:")
        print(style)


        // =============================================================
        // CONCEPT
        // =============================================================

        let concepts: [
            ImagePlaygroundConcept
        ] = [
            .text(cleanedPrompt)
        ]


        print(
            "🚀 Requesting image from ImageCreator..."
        )


        let images =
            creator.images(
                for: concepts,
                style: style,
                limit: 1
            )


        // =============================================================
        // GENERATE
        // =============================================================

        do {

            for try await generatedImage
                in images {

                print("================================")
                print(
                    "✅ IMAGE GENERATED SUCCESSFULLY"
                )
                print("================================")


                return UIImage(
                    cgImage:
                        generatedImage.cgImage
                )
            }

        } catch {

            print("================================")
            print("❌ IMAGE GENERATION FAILED")
            print("================================")

            print(error)

            throw error
        }


        throw StampGenerationError
            .noImageGenerated
    }
}