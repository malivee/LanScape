import SwiftUI
@preconcurrency import AVFoundation
import UIKit

struct CameraPreviewView: UIViewControllerRepresentable {

    let session: AVCaptureSession
    var onOrientationChanged: ((AVCaptureVideoOrientation) -> Void)? = nil

    func makeUIViewController(
        context: Context
    ) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        controller.session = session
        controller.onOrientationChanged = onOrientationChanged
        return controller
    }

    func updateUIViewController(
        _ uiViewController: CameraPreviewViewController,
        context: Context
    ) {
        uiViewController.session = session
        uiViewController.onOrientationChanged = onOrientationChanged
        uiViewController.updatePreview()
    }
}

// MARK: - Camera Preview Controller

final class CameraPreviewViewController: UIViewController {

    var session: AVCaptureSession? {
        didSet {
            updatePreview()
        }
    }

    var onOrientationChanged: ((AVCaptureVideoOrientation) -> Void)?

    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOrientation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previewLayer?.frame = view.bounds
        updateOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.previewLayer?.frame = self.view.bounds
            self.updateOrientation()
        })
    }

    // MARK: - Setup

    private func setupLayer() {
        guard previewLayer == nil else { return }

        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        layer.session = session

        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    // MARK: - Update

    func updatePreview() {
        if previewLayer == nil {
            setupLayer()
        }

        if previewLayer?.session !== session {
            previewLayer?.session = session
        }

        if previewLayer?.frame != view.bounds {
            previewLayer?.frame = view.bounds
            updateOrientation()
        }
    }

    // MARK: - Orientation

    func updateOrientation() {
        guard let connection = previewLayer?.connection else {
            return
        }

        var activeOrientation: AVCaptureVideoOrientation = .landscapeLeft
        if let windowScene = view.window?.windowScene {
            switch windowScene.interfaceOrientation {
            case .landscapeRight:
                activeOrientation = .landscapeRight
            case .landscapeLeft:
                activeOrientation = .landscapeLeft
            default:
                activeOrientation = .landscapeLeft
            }
        }

        if #available(iOS 17.0, *) {
            let angle: CGFloat = (activeOrientation == .landscapeRight) ? 180 : 0
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        } else {
            if connection.isVideoOrientationSupported {
                if connection.videoOrientation != activeOrientation {
                    connection.videoOrientation = activeOrientation
                }
            }
        }

        // FRONT CAMERA: Mirror preview horizontally
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }

        onOrientationChanged?(activeOrientation)
    }
}
