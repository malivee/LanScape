//
//  UIImage+Normalize.swift
//  LanScape
//

import UIKit

extension UIImage {
    /// Returns a new UIImage with normalized .up orientation, eliminating any EXIF rotation or flipped orientation issues
    func normalizedUp() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
