//
//  PostcardMediaGenerator.swift
//  LanScape
//
//  Creates:
//  - final postcard UIImage from PencilKit + stamp
//  - five-image collage
//  - local MP4:
//      0s: postcard already at full size
//      0-3.8s: front stays still
//      3.8-4.8s: one flip
//      4.8-10s: all five images fill the entire back
//
//  Video is local only and shared through iOS Share Sheet.
//  There is NO GIF/ImageIO pipeline.
//

import Foundation
import UIKit
import PencilKit
import AVFoundation
import CoreVideo

struct PostcardMediaBundle {
    let postcardImage: UIImage
    let collageImage: UIImage
    let videoURL: URL
}

enum PostcardMediaError: LocalizedError {

    case invalidCanvasSize
    case failedToRenderPostcard
    case needFiveImages
    case invalidCollageImage
    case invalidPostcardImage
    case failedToCreateVideo
    case pixelBufferCreationFailed

    var errorDescription: String? {

        switch self {

        case .invalidCanvasSize:
            return "Ukuran postcard tidak valid."

        case .failedToRenderPostcard:
            return "Postcard tidak dapat dirender."

        case .needFiveImages:
            return "Dibutuhkan lima gambar."

        case .invalidCollageImage:
            return "Kelima gambar harus tersedia."

        case .invalidPostcardImage:
            return "Gambar postcard tidak valid."

        case .failedToCreateVideo:
            return "Video postcard tidak dapat dibuat."

        case .pixelBufferCreationFailed:
            return "Frame video tidak dapat dibuat."
        }
    }
}

final class PostcardMediaGenerator {

    static let shared = PostcardMediaGenerator()

    private init() {}

    // MARK: - Generate All Media

    @MainActor
    func generate(
        drawing: PKDrawing,
        canvasSize: CGSize,
        stamp: UIImage?,
        collageImages: [UIImage]
    ) async throws -> PostcardMediaBundle {

        guard canvasSize.width > 0,
              canvasSize.height > 0 else {
            throw PostcardMediaError.invalidCanvasSize
        }

        guard collageImages.count >= 5 else {
            throw PostcardMediaError.needFiveImages
        }

        let fiveImages =
            Array(
                collageImages.prefix(5)
            )

        guard fiveImages.allSatisfy({
            $0.size.width > 1 &&
            $0.size.height > 1 &&
            $0.cgImage != nil
        }) else {
            throw PostcardMediaError.invalidCollageImage
        }

        let postcardImage =
            renderPostcard(
                drawing: drawing,
                canvasSize: canvasSize,
                stamp: stamp
            )

        guard postcardImage.cgImage != nil else {
            throw PostcardMediaError.failedToRenderPostcard
        }

        let collageImage =
            makeCollage(
                images: fiveImages
            )

        let videoURL =
            try await makeOpenLetterVideo(
                postcardImage: postcardImage,
                collageImages: fiveImages
            )

        return PostcardMediaBundle(
            postcardImage: postcardImage,
            collageImage: collageImage,
            videoURL: videoURL
        )
    }

    // MARK: - Final Postcard UIImage

    @MainActor
    private func renderPostcard(
        drawing: PKDrawing,
        canvasSize: CGSize,
        stamp: UIImage?
    ) -> UIImage {

        let outputWidth =
            max(
                1400,
                min(
                    canvasSize.width * 2,
                    2800
                )
            )

        let outputHeight =
            max(
                900,
                min(
                    canvasSize.height * 2,
                    1900
                )
            )

        let outputSize =
            CGSize(
                width: outputWidth,
                height: outputHeight
            )

        let renderer =
            UIGraphicsImageRenderer(
                size: outputSize
            )

        return renderer.image { rendererContext in

            let context =
                rendererContext.cgContext

            UIColor.white.setFill()

            context.fill(
                CGRect(
                    origin: .zero,
                    size: outputSize
                )
            )

            let drawingImage =
                drawing.image(
                    from: CGRect(
                        origin: .zero,
                        size: canvasSize
                    ),
                    scale:
                        max(
                            outputWidth / canvasSize.width,
                            outputHeight / canvasSize.height
                        )
                )

            drawingImage.draw(
                in: CGRect(
                    origin: .zero,
                    size: outputSize
                )
            )

            if let stamp,
               stamp.size.width > 1,
               stamp.size.height > 1 {

                let stampWidth =
                    outputWidth * 0.17

                let stampAspect =
                    stamp.size.height /
                    stamp.size.width

                let stampHeight =
                    stampWidth * stampAspect

                let stampRect =
                    CGRect(
                        x:
                            outputWidth -
                            stampWidth -
                            45,
                        y: 35,
                        width: stampWidth,
                        height: stampHeight
                    )

                stamp.draw(
                    in: stampRect,
                    blendMode: .normal,
                    alpha: 1
                )
            }
        }
    }

    // MARK: - Five Image Collage

    @MainActor
    private func makeCollage(
        images: [UIImage]
    ) -> UIImage {

        let canvasSize =
            CGSize(
                width: 1200,
                height: 1600
            )

        let renderer =
            UIGraphicsImageRenderer(
                size: canvasSize
            )

        return renderer.image { rendererContext in

            let context =
                rendererContext.cgContext

            UIColor.white.setFill()

            context.fill(
                CGRect(
                    origin: .zero,
                    size: canvasSize
                )
            )

            let gap: CGFloat = 24
            let leftWidth = canvasSize.width * 0.41
            let rightWidth =
                canvasSize.width - leftWidth - gap

            let topHeight =
                canvasSize.height * 0.29
            let middleTopHeight =
                canvasSize.height * 0.29

            let bottomY =
                topHeight +
                middleTopHeight +
                gap * 2

            let bottomHeight =
                canvasSize.height -
                bottomY

            let leftColumn = CGRect(
                x: 0,
                y: 0,
                width: leftWidth,
                height:
                    topHeight
            )

            let leftMiddle = CGRect(
                x: 0,
                y:
                    topHeight + gap,
                width: leftWidth,
                height:
                    middleTopHeight
            )

            let topRight = CGRect(
                x:
                    leftWidth + gap,
                y: 0,
                width:
                    rightWidth,
                height:
                    topHeight +
                    middleTopHeight +
                    gap
            )

            let bottomLeft = CGRect(
                x: 0,
                y: bottomY,
                width:
                    canvasSize.width * 0.56 -
                    gap / 2,
                height:
                    bottomHeight
            )

            let bottomRight = CGRect(
                x:
                    canvasSize.width * 0.56 +
                    gap / 2,
                y: bottomY,
                width:
                    canvasSize.width * 0.44 -
                    gap / 2,
                height:
                    bottomHeight
            )

            let rects: [CGRect] = [
                leftColumn,
                leftMiddle,
                topRight,
                bottomLeft,
                bottomRight
            ]

            for index in 0..<5 {

                guard images[index].size.width > 1,
                      images[index].size.height > 1,
                      let image =
                        images[index].cgImage else {
                    continue
                }

                drawAspectFill(
                    image: image,
                    in: rects[index],
                    context: context
                )
            }
        }
    }

    private func drawAspectFill(
        image: CGImage,
        in rect: CGRect,
        context: CGContext
    ) {

        let imageWidth =
            CGFloat(image.width)

        let imageHeight =
            CGFloat(image.height)

        guard imageWidth > 0,
              imageHeight > 0 else {
            return
        }

        let imageRatio =
            imageWidth /
            imageHeight

        let rectRatio =
            rect.width /
            rect.height

        let drawRect: CGRect

        if imageRatio > rectRatio {

            let drawHeight =
                rect.height

            let drawWidth =
                drawHeight *
                imageRatio

            drawRect =
                CGRect(
                    x:
                        rect.midX -
                        drawWidth / 2,
                    y:
                        rect.midY -
                        drawHeight / 2,
                    width:
                        drawWidth,
                    height:
                        drawHeight
                )

        } else {

            let drawWidth =
                rect.width

            let drawHeight =
                drawWidth /
                imageRatio

            drawRect =
                CGRect(
                    x:
                        rect.midX -
                        drawWidth / 2,
                    y:
                        rect.midY -
                        drawHeight / 2,
                    width:
                        drawWidth,
                    height:
                        drawHeight
                )
        }

        context.saveGState()

        context.clip(
            to: rect
        )

        context.interpolationQuality =
            .high

        context.draw(
            image,
            in: drawRect
        )

        context.restoreGState()
    }

    // MARK: - Video

    private func makeOpenLetterVideo(
        postcardImage: UIImage,
        collageImages: [UIImage]
    ) async throws -> URL {

        guard postcardImage.cgImage != nil else {
            throw PostcardMediaError.invalidPostcardImage
        }

        guard collageImages.count >= 5,
              collageImages.prefix(5).allSatisfy({
                  $0.cgImage != nil &&
                  $0.size.width > 1 &&
                  $0.size.height > 1
              }) else {
            throw PostcardMediaError.invalidCollageImage
        }

        let outputURL =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "OpenLetter-\(UUID().uuidString).mp4"
                )

        try? FileManager.default
            .removeItem(
                at: outputURL
            )

        let videoSize =
            CGSize(
                width: 1920,
                height: 1080
            )

        let fps: Int32 = 30

        let writer =
            try AVAssetWriter(
                outputURL: outputURL,
                fileType: .mp4
            )

        let compression:
            [String: Any] = [

                AVVideoAverageBitRateKey:
                    12_000_000,

                AVVideoProfileLevelKey:
                    AVVideoProfileLevelH264HighAutoLevel,

                AVVideoExpectedSourceFrameRateKey:
                    fps,

                AVVideoMaxKeyFrameIntervalKey:
                    fps
            ]

        let settings:
            [String: Any] = [

                AVVideoCodecKey:
                    AVVideoCodecType.h264,

                AVVideoWidthKey:
                    Int(videoSize.width),

                AVVideoHeightKey:
                    Int(videoSize.height),

                AVVideoCompressionPropertiesKey:
                    compression
            ]

        let input =
            AVAssetWriterInput(
                mediaType: .video,
                outputSettings: settings
            )

        input.expectsMediaDataInRealTime =
            false

        let adaptor =
            AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [

                    kCVPixelBufferPixelFormatTypeKey as String:
                        Int(
                            kCVPixelFormatType_32BGRA
                        ),

                    kCVPixelBufferWidthKey as String:
                        Int(videoSize.width),

                    kCVPixelBufferHeightKey as String:
                        Int(videoSize.height),

                    kCVPixelBufferIOSurfacePropertiesKey as String:
                        [:]
                ]
            )

        guard writer.canAdd(input) else {
            throw PostcardMediaError.failedToCreateVideo
        }

        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error
                ?? PostcardMediaError.failedToCreateVideo
        }

        writer.startSession(
            atSourceTime: .zero
        )

        // 10 seconds at 30 FPS.
        //
        // Front is already at FULL SIZE from frame 1.
        // No initial zoom.
        let totalFrames = 300

        for frameIndex in 0..<totalFrames {

            while !input.isReadyForMoreMediaData {

                if Task.isCancelled {

                    input.markAsFinished()
                    writer.cancelWriting()

                    try? FileManager.default
                        .removeItem(
                            at: outputURL
                        )

                    throw CancellationError()
                }

                try await Task.sleep(
                    nanoseconds: 1_000_000
                )
            }

            let progress =
                CGFloat(frameIndex) /
                CGFloat(totalFrames - 1)

            let time =
                CMTime(
                    value:
                        CMTimeValue(frameIndex),
                    timescale:
                        fps
                )

            let buffer =
                try makeVideoPixelBuffer(
                    postcardImage:
                        postcardImage,
                    collageImages:
                        Array(
                            collageImages.prefix(5)
                        ),
                    size:
                        videoSize,
                    progress:
                        progress
                )

            guard adaptor.append(
                buffer,
                withPresentationTime:
                    time
            ) else {

                writer.cancelWriting()

                try? FileManager.default
                    .removeItem(
                        at: outputURL
                    )

                throw writer.error
                    ?? PostcardMediaError.failedToCreateVideo
            }
        }

        input.markAsFinished()

        await withCheckedContinuation {
            continuation in

            writer.finishWriting {
                continuation.resume()
            }
        }

        guard writer.status == .completed,
              FileManager.default.fileExists(
                  atPath: outputURL.path
              ) else {

            try? FileManager.default
                .removeItem(
                    at: outputURL
                )

            throw writer.error
                ?? PostcardMediaError.failedToCreateVideo
        }

        return outputURL
    }

    // MARK: - Video Frame

    private func makeVideoPixelBuffer(
        postcardImage: UIImage,
        collageImages: [UIImage],
        size: CGSize,
        progress: CGFloat
    ) throws -> CVPixelBuffer {

        var pixelBuffer:
            CVPixelBuffer?

        let attributes:
            [String: Any] = [

                kCVPixelBufferCGImageCompatibilityKey as String:
                    true,

                kCVPixelBufferCGBitmapContextCompatibilityKey as String:
                    true,

                kCVPixelBufferIOSurfacePropertiesKey as String:
                    [:]
            ]

        let status =
            CVPixelBufferCreate(
                kCFAllocatorDefault,
                Int(size.width),
                Int(size.height),
                kCVPixelFormatType_32BGRA,
                attributes as CFDictionary,
                &pixelBuffer
            )

        guard status == kCVReturnSuccess,
              let pixelBuffer else {

            throw
                PostcardMediaError
                    .pixelBufferCreationFailed
        }

        CVPixelBufferLockBaseAddress(
            pixelBuffer,
            []
        )

        defer {
            CVPixelBufferUnlockBaseAddress(
                pixelBuffer,
                []
            )
        }

        guard let baseAddress =
                CVPixelBufferGetBaseAddress(
                    pixelBuffer
                ) else {

            throw
                PostcardMediaError
                    .pixelBufferCreationFailed
        }

        let bytesPerRow =
            CVPixelBufferGetBytesPerRow(
                pixelBuffer
            )

        guard let context =
                CGContext(
                    data:
                        baseAddress,
                    width:
                        Int(size.width),
                    height:
                        Int(size.height),
                    bitsPerComponent:
                        8,
                    bytesPerRow:
                        bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                            .premultipliedFirst
                            .rawValue
                        |
                        CGBitmapInfo
                            .byteOrder32Little
                            .rawValue
                ) else {

            throw
                PostcardMediaError
                    .pixelBufferCreationFailed
        }

        // Background.
        context.setFillColor(
            UIColor(
                red: 0.94,
                green: 0.96,
                blue: 0.99,
                alpha: 1
            ).cgColor
        )

        context.fill(
            CGRect(
                origin: .zero,
                size: size
            )
        )

        guard let frontImage =
                postcardImage.cgImage else {

            throw
                PostcardMediaError
                    .invalidPostcardImage
        }

        let sourceWidth =
            CGFloat(frontImage.width)

        let sourceHeight =
            CGFloat(frontImage.height)

        guard sourceWidth > 0,
              sourceHeight > 0 else {

            throw
                PostcardMediaError
                    .invalidPostcardImage
        }

        let sourceRatio =
            sourceWidth /
            sourceHeight

        let videoRatio =
            size.width /
            size.height

        // Final postcard size.
        let cardWidth: CGFloat
        let cardHeight: CGFloat

        if sourceRatio > videoRatio {

            cardWidth =
                size.width * 0.80

            cardHeight =
                cardWidth /
                sourceRatio

        } else {

            cardHeight =
                size.height * 0.80

            cardWidth =
                cardHeight *
                sourceRatio
        }

        let center =
            CGPoint(
                x:
                    size.width / 2,
                y:
                    size.height / 2
            )

        // ---------------------------------------------------------
        // TIMELINE
        //
        // 0.00 - 0.05  subtle 0.5-second zoom: 94% -> 100%
        // 0.05 - 0.38  full-size front hold
        // 0.38 - 0.48  single flip
        // 0.48 - 1.00  full back + all five images
        //
        // The opening zoom is intentionally very small.
        // ---------------------------------------------------------

        if progress < 0.05 {

            // Tiny opening zoom only.
            // The postcard starts very close to its final size.
            let openingProgress =
                easeInOut(
                    progress / 0.05
                )

            let scale =
                0.94 +
                (0.06 * openingProgress)

            drawFront(
                context:
                    context,
                image:
                    frontImage,
                center:
                    center,
                width:
                    cardWidth * scale,
                height:
                    cardHeight * scale
            )

        } else if progress < 0.38 {

            // Full size after the short 0.5-second opening.
            drawFront(
                context:
                    context,
                image:
                    frontImage,
                center:
                    center,
                width:
                    cardWidth,
                height:
                    cardHeight
            )

        } else if progress < 0.48 {

            // -----------------------------------------------------
            // ONE FLIP
            // -----------------------------------------------------

            let flipProgress =
                easeInOut(
                    (progress - 0.38) /
                    0.10
                )

            let angle =
                CGFloat.pi *
                flipProgress

            let projectedWidth =
                max(
                    0.015,
                    abs(
                        cos(angle)
                    )
                )

            if flipProgress < 0.5 {

                // Front.
                drawFront(
                    context:
                        context,
                    image:
                        frontImage,
                    center:
                        center,
                    width:
                        cardWidth *
                        projectedWidth,
                    height:
                        cardHeight
                )

            } else {

                // Back.
                drawBack(
                    context:
                        context,
                    images:
                        collageImages,
                    center:
                        center,
                    width:
                        cardWidth *
                        projectedWidth,
                    height:
                        cardHeight
                )
            }

        } else {

            // -----------------------------------------------------
            // BACK
            //
            // ALL FIVE IMAGES ARE ALREADY LOADED AND VISIBLE.
            // THEY FILL THE COMPLETE BACK OF THE LETTER.
            // -----------------------------------------------------

            drawBack(
                context:
                    context,
                images:
                    collageImages,
                center:
                    center,
                width:
                    cardWidth,
                height:
                    cardHeight
            )
        }

        return pixelBuffer
    }

    // MARK: - Front

    private func drawFront(
        context: CGContext,
        image: CGImage,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {

        guard width > 1,
              height > 1 else {
            return
        }

        let rect =
            CGRect(
                x:
                    center.x -
                    width / 2,
                y:
                    center.y -
                    height / 2,
                width:
                    width,
                height:
                    height
            )

        context.saveGState()

        context.setShadow(
            offset:
                CGSize(
                    width: 0,
                    height: 18
                ),
            blur:
                30,
            color:
                UIColor.black
                    .withAlphaComponent(
                        0.22
                    )
                    .cgColor
        )

        context.interpolationQuality =
            .high

        context.draw(
            image,
            in: rect
        )

        context.restoreGState()
    }

    // MARK: - Back

    private func drawBack(
        context: CGContext,
        images: [UIImage],
        center: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {

        guard images.count >= 5,
              width > 1,
              height > 1 else {
            return
        }

        let cardRect =
            CGRect(
                x:
                    center.x -
                    width / 2,
                y:
                    center.y -
                    height / 2,
                width:
                    width,
                height:
                    height
            )

        context.saveGState()

        context.setShadow(
            offset:
                CGSize(
                    width: 0,
                    height: 18
                ),
            blur:
                30,
            color:
                UIColor.black
                    .withAlphaComponent(
                        0.22
                    )
                    .cgColor
        )

        // Back base.
        context.setFillColor(
            UIColor.white.cgColor
        )

        context.fill(
            cardRect
        )

        // ---------------------------------------------------------
        // FIVE IMAGES — FULL COVERAGE
        // ---------------------------------------------------------

        let gap: CGFloat = width * 0.018

        let leftWidth =
            width * 0.41

        let rightWidth =
            width -
            leftWidth -
            gap

        let topHeight =
            height * 0.29

        let middleHeight =
            height * 0.29

        let topRightHeight =
            topHeight +
            middleHeight +
            gap

        let bottomY =
            topRightHeight +
            gap

        let bottomHeight =
            height -
            bottomY

        let rects: [CGRect] = [

            // Image 1 — top left
            CGRect(
                x:
                    cardRect.minX,
                y:
                    cardRect.minY,
                width:
                    leftWidth,
                height:
                    topHeight
            ),

            // Image 2 — middle left
            CGRect(
                x:
                    cardRect.minX,
                y:
                    cardRect.minY +
                    topHeight +
                    gap,
                width:
                    leftWidth,
                height:
                    middleHeight
            ),

            // Image 3 — large top right
            CGRect(
                x:
                    cardRect.minX +
                    leftWidth +
                    gap,
                y:
                    cardRect.minY,
                width:
                    rightWidth,
                height:
                    topRightHeight
            ),

            // Image 4 — large bottom left
            CGRect(
                x:
                    cardRect.minX,
                y:
                    cardRect.minY +
                    bottomY,
                width:
                    width * 0.56 -
                    gap / 2,
                height:
                    bottomHeight
            ),

            // Image 5 — bottom right
            CGRect(
                x:
                    cardRect.minX +
                    width * 0.56 +
                    gap / 2,
                y:
                    cardRect.minY +
                    bottomY,
                width:
                    width * 0.44 -
                    gap / 2,
                height:
                    bottomHeight
            )
        ]

        for index in 0..<5 {

            guard let image =
                    images[index].cgImage else {
                continue
            }

            drawImageAspectFill(
                context:
                    context,
                image:
                    image,
                in:
                    rects[index]
            )
        }

        // Very subtle outside edge.
        context.setStrokeColor(
            UIColor.black
                .withAlphaComponent(
                    0.10
                )
                .cgColor
        )

        context.setLineWidth(2)

        context.stroke(
            cardRect
        )

        context.restoreGState()
    }

    private func drawImageAspectFill(
        context: CGContext,
        image: CGImage,
        in rect: CGRect
    ) {

        let imageWidth =
            CGFloat(image.width)

        let imageHeight =
            CGFloat(image.height)

        guard imageWidth > 0,
              imageHeight > 0 else {
            return
        }

        let imageRatio =
            imageWidth /
            imageHeight

        let rectRatio =
            rect.width /
            rect.height

        let drawRect: CGRect

        if imageRatio > rectRatio {

            let drawHeight =
                rect.height

            let drawWidth =
                drawHeight *
                imageRatio

            drawRect =
                CGRect(
                    x:
                        rect.midX -
                        drawWidth / 2,
                    y:
                        rect.midY -
                        drawHeight / 2,
                    width:
                        drawWidth,
                    height:
                        drawHeight
                )

        } else {

            let drawWidth =
                rect.width

            let drawHeight =
                drawWidth /
                imageRatio

            drawRect =
                CGRect(
                    x:
                        rect.midX -
                        drawWidth / 2,
                    y:
                        rect.midY -
                        drawHeight / 2,
                    width:
                        drawWidth,
                    height:
                        drawHeight
                )
        }

        context.saveGState()

        context.clip(
            to: rect
        )

        context.interpolationQuality =
            .high

        context.draw(
            image,
            in:
                drawRect
        )

        context.restoreGState()
    }

    // MARK: - Easing

    private func easeInOut(
        _ value: CGFloat
    ) -> CGFloat {

        let t =
            max(
                0,
                min(
                    1,
                    value
                )
            )

        return
            t < 0.5
            ? 2 * t * t
            : 1 -
                pow(
                    -2 * t + 2,
                    2
                ) / 2
    }
}
