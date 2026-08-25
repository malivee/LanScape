import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewControllerRepresentable {
    let session: AVCaptureSession
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        controller.session = session
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewViewController, context: Context) {
        uiViewController.session = session
        uiViewController.updatePreview()
    }
}

final class CameraPreviewViewController: UIViewController {
    var session: AVCaptureSession? {
        didSet {
            updatePreview()
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayer()
    }
    
    private func setupLayer() {
        guard previewLayer == nil else { return }
        let layer = AVCaptureVideoPreviewLayer()
        layer.session = session
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        self.previewLayer = layer
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
    
    func updatePreview() {
        if previewLayer == nil {
            setupLayer()
        }
        if previewLayer?.session != session {
            previewLayer?.session = session
        }
        previewLayer?.frame = view.bounds
        updateOrientation()
    }
    
    func updateOrientation() {
        guard let connection = previewLayer?.connection else { return }
        
        let interfaceOrientation: UIInterfaceOrientation
        if let windowScene = view.window?.windowScene ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            interfaceOrientation = windowScene.interfaceOrientation
        } else {
            interfaceOrientation = .portrait
        }
        
        let videoOrientation: AVCaptureVideoOrientation
        switch interfaceOrientation {
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        default:
            videoOrientation = .portrait
        }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = videoOrientation
        }
        
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
    }
}
