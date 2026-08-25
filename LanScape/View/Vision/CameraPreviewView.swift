import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewControllerRepresentable {

    let session: AVCaptureSession

    func makeUIViewController(
        context: Context
    ) -> CameraPreviewViewController {

        let controller = CameraPreviewViewController()

        controller.session = session

        return controller
    }

    func updateUIViewController(
        _ uiViewController: CameraPreviewViewController,
        context: Context
    ) {

        uiViewController.session = session

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

    override func viewWillAppear(
        _ animated: Bool
    ) {

        super.viewWillAppear(animated)

        previewLayer?.frame = view.bounds

        updateOrientation()
    }

    // MARK: - Setup

    private func setupLayer() {

        guard previewLayer == nil else {
            return
        }

        let layer = AVCaptureVideoPreviewLayer()

        layer.videoGravity = .resizeAspectFill

        layer.session = session

        view.layer.insertSublayer(
            layer,
            at: 0
        )

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

        previewLayer?.frame = view.bounds

        updateOrientation()
    }

    // MARK: - Orientation

    func updateOrientation() {

        guard let connection = previewLayer?.connection else {
            return
        }

        // The app is locked to landscape.
        //
        // We intentionally use landscapeRight
        // everywhere so the camera, Vision and
        // overlay all use the same orientation.

        let orientation: AVCaptureVideoOrientation = .landscapeRight

        if connection.isVideoOrientationSupported {

            connection.videoOrientation = orientation
        }

        // FRONT CAMERA
        //
        // Mirror ONLY the preview.
        //
        // Vision receives the original,
        // non-mirrored camera image.

        if connection.isVideoMirroringSupported {

            connection.automaticallyAdjustsVideoMirroring = false

            connection.isVideoMirrored = true
        }
    }
}
