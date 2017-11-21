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
            let simulatorManager = try SimulatorManager()
            let simulator = try simulatorManager.allocateSimulator()
            let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ca.brandonevans.JungleGym")
            let appURL = try StubAppGenerator.createStubApp(named: "stub", in: temporaryDirectory)
            print(appURL)
            let pid = try simulatorManager.launchApp(at: appURL, in: simulator)
            print(pid)

            LLDBGlobals.initializeLLDBWrapper()

            let debugger = try Debugger()
            debugger.addBreakpoint(named: "_executePlayground") { process, _, _ in
                print("TODO: evaluate playground expression")
                guard
                    let process = process,
                    let frame = process.allThreads.first?.allFrames.flatMap({ $0 }).first
                else { return true }

                if process.state != .running {
                    print("---")
                    print("State: \(process.state)")
                    print(process.allThreads.first?.allFrames.flatMap { $0 }.first?.lineEntry ?? "")
                    print(process.allThreads.first?.allFrames.flatMap { $0 }.first?.functionName ?? "")
                }

                let expression = """
                import UIKit
                import PlaygroundSupport
                let view = UIView()
                view.backgroundColor = .red
                view.alpha = 0
                view.frame = UIScreen.main.bounds
                PlaygroundPage.current.liveView = view
                UIView.animate(withDuration: 2.0) { view.alpha = 1 }
                """
                let result = debugger.evaluate(expression: expression, in: frame)
                if let error = result?.error, error.error != 0 {
                    print("Error evaluating expression: " + error.string)
                }
                else if let result = result {
                    print(result.valueExpression)
                }

                _ = process.continue()
                return true
            }
            debugger.addBreakpoint(named: "_playgroundExecutionWillFinish") { process, _, _ in
                print("TODO: tidy up")
                _ = process?.continue()
                return true
            }
            try debugger.attach(to: pid)

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

