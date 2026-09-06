//
//  StampGenerationError.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import Foundation

enum StampGenerationError: LocalizedError {

    case emptyMessage
    case emptyResponse
    case foundationModelUnavailable
    case englishLocaleUnavailable
    case noAvailableStyle
    case noImageGenerated
    case viewControllerNotFound


    var errorDescription: String? {

        switch self {

        case .emptyMessage:

            return """
            Please write a postcard message first.
            """


        case .emptyResponse:

            return """
            Foundation Models returned an empty response.
            """


        case .foundationModelUnavailable:

            return """
            Foundation Models is currently unavailable.

            Please make sure Apple Intelligence
            is enabled and the model is ready.
            """


        case .englishLocaleUnavailable:

            return """
            English is not supported by the
            Foundation Model on this device.
            """


        case .noAvailableStyle:

            return """
            No image generation style is available.
            """


        case .noImageGenerated:

            return """
            No image was generated.
            """


        case .viewControllerNotFound:

            return """
            Unable to open Image Playground.
            """
        }
    }
}
