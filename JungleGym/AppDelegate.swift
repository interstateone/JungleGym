//
//  AppDelegate.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa
import LLDBWrapper

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
                print(view)
                view.backgroundColor = .red
                view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                PlaygroundPage.current.liveView = view
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
        }
        catch {
            print(error)
        }
    }
}

