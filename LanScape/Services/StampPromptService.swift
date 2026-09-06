//
//  StampPromptService.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//


//
//  StampPromptService.swift
//  LanScape
//

import Foundation
import FoundationModels

@available(iOS 26.0, *)
@MainActor
final class StampPromptService {

    func generatePrompt(
        from message: String
    ) async throws -> String {

        let cleanedMessage =
            message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedMessage.isEmpty else {
            throw StampGenerationError.emptyMessage
        }

        print("========================================")
        print("STAMP PROMPT REQUEST")
        print("========================================")

        let instructions = """
        Create an English visual concept for a
        commemorative postage stamp based on the
        user's postcard message.

        Your task is to transform the meaning of the
        postcard message into a concise visual
        description that can be directly used by
        an image generator.

        IMPORTANT:

        - Do not copy the postcard message.
        - Do not repeat the postcard message.
        - Do not summarize the postcard message.
        - Do not provide explanations or analysis.
        - Do not provide historical facts.
        - Do not provide dates or chronology.
        - Do not create a story or narrative.
        - Do not explain why visual elements were chosen.
        - Focus only on what should be visible
          in the generated image.
        - Use visual elements that represent the
          main meaning of the postcard message.
        - Make the description concise and specific.
        - Use approximately 2–3 sentences.
        - The visual description MUST be written
          entirely in English.
        - Return ONLY the English visual description.

        The final image MUST NOT contain:

        - people
        - human figures
        - human faces
        - portraits
        - soldiers
        - historical figures
        - children
        - weapons
        - violence
        - blood
        - gore
        - combat

        Represent the message using visual elements
        such as:

        - objects
        - landscapes
        - architecture
        - vehicles
        - landmarks
        - flowers
        - animals
        - symbolic objects
        - historical environments

        If the postcard message describes a historical
        event, do not depict people, soldiers,
        weapons, battles, or violence.

        Instead, represent the historical meaning
        through objects, architecture, vehicles,
        environments, landmarks, or peaceful symbolic
        elements.

        The result should look like a beautiful
        commemorative postage stamp.

        Include:

        - vintage postage stamp aesthetic
        - decorative perforated border
        - detailed engraved illustration
        - aged paper texture
        - nostalgic mood
        - respectful composition

        Return ONLY the English visual description.

        Do not include any explanation, title,
        quotation marks, or additional text.
        """

        let session =
            LanguageModelSession(
                instructions: instructions
            )

        do {

            let response =
                try await session.respond(
                    to: cleanedMessage
                )

            let visualPrompt =
                response.content
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard !visualPrompt.isEmpty else {
                throw StampGenerationError.emptyResponse
            }

            print("========================================")
            print("✅ GENERATED VISUAL PROMPT")
            print("========================================")
            print(visualPrompt)

            return visualPrompt

        } catch {

            print("========================================")
            print("❌ FOUNDATION MODELS FAILED")
            print("========================================")
            print(error)

            throw error
        }
    }
}