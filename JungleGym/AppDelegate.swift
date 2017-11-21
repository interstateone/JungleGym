//
//  AppDelegate.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa
import LLDBWrapper
import FBSimulatorControl

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let executionSession = try ExecutionSession()
            let simulator = try executionSession.prepare(with: """
                import UIKit
                import PlaygroundSupport
                let view = UIView()
                view.backgroundColor = .red
                view.alpha = 0
                view.frame = UIScreen.main.bounds
                PlaygroundPage.current.liveView = view
                UIView.animate(withDuration: 2.0) { view.alpha = 1 }
            """)
            try executionSession.execute()

            guard let viewController = NSApplication.shared.windows.first?.contentViewController as? SimulatorViewController else { return }
            // Having troubles getting to the device property from Swift...
            viewController.simulatorScreenScale = 2.0 // simulator.device.deviceType.mainScreenScale
            if let initialSurface = try simulator.framebuffer().surface?.attach(viewController, on: DispatchQueue.main) {
                viewController.didChange(initialSurface.takeUnretainedValue())
            }
        }
        catch {
            print(error)
        }
    }
}

