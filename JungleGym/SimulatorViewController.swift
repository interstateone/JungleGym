//
//  ViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa
import FBSimulatorControl

class SimulatorViewController: NSViewController, FBFramebufferSurfaceConsumer {
    var simulatorScreenScale: CGFloat = 1.0

    // MARK: - FBFramebufferSurfaceConsumer

    public func didChange(_ surface: IOSurfaceRef?) {
        guard let surface = surface else { return }
        view.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        let layer = CALayer()
        layer.contents = surface
        layer.frame = CGRect(x: 0, y: 0, width: CGFloat(IOSurfaceGetWidth(surface)) / simulatorScreenScale, height: CGFloat(IOSurfaceGetHeight(surface)) / simulatorScreenScale)
        view.layer?.addSublayer(layer)
    }

    public func didReceiveDamage(_ rect: CGRect) {
        // Borrowed from Chromium: https://chromium.googlesource.com/chromium/src/+/d00ca3fc285e05c0c9a995b101740b630fd14355/content/common/gpu/image_transport_surface_calayer_mac.mm#81
        _ = view.layer?.perform(Selector(("setContentsChanged")))
    }

    public let consumerIdentifier: String = "ca.brandonevans.JungleGym.\(String(describing: SimulatorViewController.self))"
}

extension NSStoryboard.SceneIdentifier {
    static let simulatorViewController = NSStoryboard.SceneIdentifier(rawValue: String(describing: SimulatorViewController.self))
}
