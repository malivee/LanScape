//
//  CameraPreviewView.swift
//  LanScape
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var onOrientationChanged: ((AVCaptureVideoOrientation) -> Void)? = nil

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.onOrientationChanged = onOrientationChanged
        view.updateOrientation()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
        uiView.onOrientationChanged = onOrientationChanged
        uiView.updateOrientation()
    }
}

// MARK: - Native Direct Preview Layer View (Dynamic Orientation, Never Flipped)
final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var onOrientationChanged: ((AVCaptureVideoOrientation) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        videoPreviewLayer.videoGravity = .resizeAspectFill
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationNotification),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleOrientationNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.updateOrientation()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateOrientation()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            updateOrientation()
        }
    }

    func updateOrientation() {
        guard let connection = videoPreviewLayer.connection else { return }

        let targetOrientation = resolveActiveOrientation()

        if connection.isVideoOrientationSupported && connection.videoOrientation != targetOrientation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            connection.videoOrientation = targetOrientation
            CATransaction.commit()
        }

        // FRONT CAMERA: Always mirror so user sees mirror reflection
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }

        onOrientationChanged?(targetOrientation)
    }

    private func resolveActiveOrientation() -> AVCaptureVideoOrientation {
        // 1. Resolve from current UIWindowScene
        if let windowScene = self.window?.windowScene {
            switch windowScene.interfaceOrientation {
            case .landscapeRight:
                return .landscapeRight
            case .landscapeLeft:
                return .landscapeLeft
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                break
            }
        }

        // 2. Resolve from all connected scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                switch windowScene.interfaceOrientation {
                case .landscapeRight:
                    return .landscapeRight
                case .landscapeLeft:
                    return .landscapeLeft
                case .portrait:
                    return .portrait
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                default:
                    break
                }
            }
        }

        // 3. Fallback based on physical device orientation
        // Note: UIDevice.landscapeLeft means device is tilted left -> interface is landscapeRight!
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return .landscapeLeft
        }
    }
}
