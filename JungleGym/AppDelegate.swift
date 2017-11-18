//
//  AppDelegate.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let simulatorManager = try SimulatorManager()
            let simulator = try simulatorManager.allocateSimulator()
            let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ca.brandonevans.JungleGym")
            let appURL = try StubAppGenerator.createStubApp(named: "stub", in: temporaryDirectory)
            print(appURL)
            let pid = try simulatorManager.launchApp(at: appURL, in: simulator)
            print(pid)
        }
        catch {
            print(error)
        }
    }
}

