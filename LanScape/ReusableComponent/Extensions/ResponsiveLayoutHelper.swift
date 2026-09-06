//
//  ResponsiveLayoutHelper.swift
//  LanScape
//

import SwiftUI
import UIKit

extension UIDevice {
    /// Check whether the current device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Check whether the current device is an iPhone
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

/// Helper function to return device-specific layout values
func responsiveVal<T>(phone: T, pad: T) -> T {
    UIDevice.isIPad ? pad : phone
}

/// Helper function to interpolate values based on screen width/height
func scaledMetric(base: CGFloat, minVal: CGFloat, maxVal: CGFloat, current: CGFloat, targetBase: CGFloat) -> CGFloat {
    let ratio = current / targetBase
    let scaled = base * ratio
    return max(minVal, min(maxVal, scaled))
}
