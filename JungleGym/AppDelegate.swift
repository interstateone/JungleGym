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
            guard
                let window = NSApplication.shared.windows.first,
                let windowController = window.windowController as? PlaygroundWindowController
            else { return }

            let executionSession = try ExecutionSession()
            windowController.session = executionSession

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

            executionSession.delegate = windowController.editorViewController
            // Having troubles getting to the device property from Swift...
            windowController.simulatorViewController.simulatorScreenScale = 2.0 // simulator.device.deviceType.mainScreenScale
            if let initialSurface = try simulator.framebuffer().surface?.attach(windowController.simulatorViewController, on: DispatchQueue.main) {
                windowController.simulatorViewController.didChange(initialSurface.takeUnretainedValue())
            }

            try executionSession.execute()
        }
        catch {
            print(error)
        }
    }
}

