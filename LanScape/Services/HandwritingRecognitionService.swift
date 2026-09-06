//
//  HandwritingRecognitionService.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import Foundation
import UIKit
import PencilKit
import Vision

@MainActor
final class HandwritingRecognitionService {

    // MARK: - Recognize PencilKit Drawing

    func recognizeText(
        from drawing: PKDrawing,
        canvasSize: CGSize
    ) async throws -> String {

        guard !drawing.strokes.isEmpty else {

            throw HandwritingRecognitionError.emptyDrawing
        }


        guard canvasSize.width > 0,
              canvasSize.height > 0 else {

            throw HandwritingRecognitionError.invalidCanvasSize
        }


        print("========================================")
        print("📝 HANDWRITING RECOGNITION")
        print("========================================")


        // =============================================================
        // RENDER PKDRAWING → UIImage
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

            throw HandwritingRecognitionError
                .invalidImage
        }


        // =============================================================
        // VISION
        // =============================================================

        let recognizedText =
            try await recognizeText(
                from: cgImage
            )


        print("========================================")
        print("✅ HANDWRITING RECOGNIZED")
        print("========================================")

        print(recognizedText)


        return recognizedText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }


    // MARK: - Vision Recognition

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


                    let strings =
                        observations.compactMap {

                            observation in

                            observation
                                .topCandidates(1)
                                .first?
                                .string
                        }


                    let result =
                        strings.joined(
                            separator: " "
                        )


                    continuation.resume(
                        returning: result
                    )
                }


            // =========================================================
            // RECOGNITION SETTINGS
            // =========================================================

            request.recognitionLevel =
                .accurate

            request.usesLanguageCorrection =
                true


            // Indonesian + English
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


            // Vision can take some time,
            // so don't block the main thread.

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


// MARK: - Errors

enum HandwritingRecognitionError:
    LocalizedError {

    case emptyDrawing

    case invalidCanvasSize

    case invalidImage


    var errorDescription: String? {

        switch self {

        case .emptyDrawing:

            return """
            Belum ada tulisan.
            Silakan tulis pesan terlebih dahulu.
            """


        case .invalidCanvasSize:

            return """
            Ukuran area tulisan tidak valid.
            """


        case .invalidImage:

            return """
            Tulisan tidak dapat diproses menjadi gambar.
            """
        }
    }
}
