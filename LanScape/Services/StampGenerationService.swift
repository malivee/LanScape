//
//  StampGenerationService.swift
//  LanScape
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//


//
//  StampGenerationService.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import Foundation
import UIKit
import PencilKit
import Vision
import FoundationModels
import ImagePlayground

@available(iOS 26.0, *)
@MainActor
final class StampGenerationService {

    // MARK: - Services

    private let promptService =
        StampPromptService()

    private let imageGenerator =
        StampImageGenerator()


    // MARK: - Generate Stamp

    func generateStamp(
        from drawing: PKDrawing,
        canvasSize: CGSize
    ) async throws -> UIImage {

        print("")
        print("========================================")
        print("🎨 STAMP GENERATION STARTED")
        print("========================================")


        // =============================================================
        // STEP 1
        // PENCILKIT → VISION
        // =============================================================

        print("")
        print("📝 STEP 1: READING HANDWRITING")
        print("----------------------------------------")


        let recognizedMessage =
            try await recognizeHandwriting(
                from: drawing,
                canvasSize: canvasSize
            )


        let cleanedMessage =
            recognizedMessage
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )


        print("Recognized message:")
        print(cleanedMessage)


        guard !cleanedMessage.isEmpty else {

            throw StampGenerationError.emptyMessage
        }


        // =============================================================
        // STEP 2
        // FOUNDATION MODELS
        // =============================================================

        print("")
        print("🧠 STEP 2: UNDERSTANDING MESSAGE")
        print("----------------------------------------")


        let visualPrompt =
            try await promptService.generatePrompt(
                from: cleanedMessage
            )


        print("")
        print("Generated visual prompt:")
        print(visualPrompt)


        // =============================================================
        // STEP 3
        // IMAGE PLAYGROUND
        // =============================================================

        print("")
        print("🖼️ STEP 3: GENERATING STAMP")
        print("----------------------------------------")


        let stamp =
            try await imageGenerator.generateImage(
                prompt: visualPrompt
            )


        // =============================================================
        // COMPLETE
        // =============================================================

        print("")
        print("========================================")
        print("✅ STAMP GENERATION COMPLETE")
        print("========================================")


        return stamp
    }


    // MARK: - Recognize Handwriting

    private func recognizeHandwriting(
        from drawing: PKDrawing,
        canvasSize: CGSize
    ) async throws -> String {

        guard !drawing.strokes.isEmpty else {

            throw StampGenerationError.emptyMessage
        }


        guard canvasSize.width > 0,
              canvasSize.height > 0 else {

            throw StampGenerationError.noImageGenerated
        }


        // =============================================================
        // RENDER PKDRAWING
        // =============================================================

        let image =
            drawing.image(
                from: CGRect(
                    origin: .zero,
                    size: canvasSize
                ),
                scale: 2.0
            )


        guard let cgImage =
                image.cgImage else {

            throw StampGenerationError.noImageGenerated
        }


        // =============================================================
        // VISION
        // =============================================================

        return try await recognizeText(
            from: cgImage
        )
    }


    // MARK: - Vision OCR

    private func recognizeText(
        from cgImage: CGImage
    ) async throws -> String {

        try await withCheckedThrowingContinuation {
            continuation in

            let request =
                VNRecognizeTextRequest {

                    request,
                    error in


                    // =================================================
                    // ERROR
                    // =================================================

                    if let error {

                        continuation.resume(
                            throwing: error
                        )

                        return
                    }


                    // =================================================
                    // RESULTS
                    // =================================================

                    guard let observations =
                            request.results
                            as? [
                                VNRecognizedTextObservation
                            ] else {

                        continuation.resume(
                            returning: ""
                        )

                        return
                    }


                    // Vision returns text regions.
                    //
                    // Sort from top to bottom and
                    // left to right so the handwriting
                    // remains in the correct order.

                    let sortedObservations =
                        observations.sorted {

                            first,
                            second in

                            let firstBox =
                                first.boundingBox

                            let secondBox =
                                second.boundingBox


                            let verticalDifference =
                                abs(
                                    firstBox.midY -
                                    secondBox.midY
                                )


                            // Same line
                            if verticalDifference < 0.03 {

                                return firstBox.minX <
                                    secondBox.minX
                            }


                            // Top to bottom
                            return firstBox.midY >
                                secondBox.midY
                        }


                    let recognizedText =
                        sortedObservations
                            .compactMap {

                                observation in

                                observation
                                    .topCandidates(1)
                                    .first?
                                    .string
                            }
                            .joined(
                                separator: " "
                            )


                    continuation.resume(
                        returning:
                            recognizedText
                    )
                }


            // =========================================================
            // VISION SETTINGS
            // =========================================================

            request.recognitionLevel =
                .accurate

            request.usesLanguageCorrection =
                true


            // Indonesian and English.
            //
            // Vision will try to recognize
            // handwriting using these languages.

            if #available(iOS 18.0, *) {

                request.recognitionLanguages = [
                    "id-ID",
                    "en-US"
                ]
            }


            // =========================================================
            // IMAGE HANDLER
            // =========================================================

            let handler =
                VNImageRequestHandler(
                    cgImage: cgImage,
                    options: [:]
                )


            // =========================================================
            // PERFORM VISION OFF MAIN THREAD
            // =========================================================

            DispatchQueue.global(
                qos: .userInitiated
            ).async {

                do {

                    try handler.perform([
                        request
                    ])

                } catch {

                    continuation.resume(
                        throwing: error
                    )
                }
            }
        }
    }
}
