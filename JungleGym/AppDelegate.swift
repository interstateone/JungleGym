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
        guard
            let window = NSApplication.shared.windows.first,
            let windowController = window.windowController as? PlaygroundWindowController
        else { return }

        windowController.playground = Playground(contents: """
        import UIKit
        import PlaygroundSupport

        let view = UIView()
        view.frame = UIScreen.main.bounds
        view.backgroundColor = .white
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Is it safe?"
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        PlaygroundPage.current.liveView = view
        """)
    }
}
