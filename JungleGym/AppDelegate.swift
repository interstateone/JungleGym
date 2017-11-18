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
            // This needs to be created by this process in order to remain sandboxed
            let appURL = URL(fileURLWithPath: "/Users/brandon/Projects/JungleGym/sign-test/stub.app")
            let pid = try simulatorManager.launchApp(at: appURL, in: simulator)
            print(pid)
        }
        catch {
            print(error)
        }
    }
}

