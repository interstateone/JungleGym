//
//  Debugger.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-19.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import LLDBWrapper

public class Debugger {
    public enum Error: Swift.Error {
        case unableToSetupDebugger
        case unableToAttachToProcess
    }

    private let debugger: LLDBDebugger
    private let listener: LLDBListener
    private let target: LLDBTarget
    private var breakpoints: [LLDBBreakpoint] = []

    public init() throws {
        guard
            let debugger = LLDBDebugger(),
            let listener = LLDBListener(name: "JungleGymListener"),
            let target = debugger.createTarget(withFilename: "")
        else {
            throw Error.unableToSetupDebugger
        }

        self.debugger = debugger
        self.listener = listener
        self.target = target
        debugger.async = true

        debugger.handleCommand("settings set target.use-all-compiler-flags 1")

        let frameworkSearchPathURLs = [
            // PlaygroundSupport
            URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/")
        ]
        debugger.handleCommand("settings set target.swift-framework-search-paths ''")
        for searchPathURL in frameworkSearchPathURLs {
            debugger.handleCommand("settings append target.swift-framework-search-paths '\(searchPathURL.path)'")
        }
    }

    public func addBreakpoint(named name: String, callback: ((LLDBProcess?, LLDBThread?, LLDBBreakpointLocation?) -> Bool)? = nil) {
        guard let breakpoint = target.createBreakpoint(byName: name) else { return }
        breakpoint.isEnabled = true
        if let callback = callback {
            breakpoint.callback = callback
        }
        breakpoints.append(breakpoint)
    }

    public func attach(to pid: ProcessID) throws {
        var error: LLDBError?
        guard
            let process = target.attachToProcess(withID: UInt64(pid), error: &error),
            // Error may be non-nil but with a code of 0 and string of "success" 🙄
            error == nil || error?.error == 0
        else {
            throw Error.unableToAttachToProcess
        }

        _ = process.addListener(listener, eventMask: [LLDBProcess.BroadcastBit.StateChanged, .Interrupt, .STDOUT])
        DispatchQueue.debuggerEvents.async {
            var done = false
            while !done {
                _ = self.listener.waitForEvent(10)

                if [LLDBStateType.crashed, .detached, .exited].contains(process.state) {
                    done = true
                }

                DispatchQueue.main.async {
                    print("---")
                    print("State: " + self.debugger.string(of: process.state))
                    if process.state != .running {
                        print(process.allThreads.first?.allFrames.flatMap { $0 }.first?.lineEntry ?? "")
                        print(process.allThreads.first?.allFrames.flatMap { $0 }.first?.functionName ?? "")
                    }
                }
            }

            let standardOutputData = process.readFromStandardOutput()
            if let standardOutput = String(data: standardOutputData, encoding: .utf8) {
                print("---")
                print(standardOutput)
            }
        }

        if process.state == .stopped {
            // Paused after attaching, continuing
            process.continue()
        }
    }

    @discardableResult
    public func evaluate(expression: String, in frame: LLDBFrame) -> LLDBValue? {
        guard let options = LLDBExpressionOptions() else { return nil }
        options.setLanguage(.swift)
        options.ignoreBreakpoints = false
        options.autoApplyFixIts = false
        options.unwindOnError = false
        options.trapExceptions = false
        options.timeoutInMicroseconds = 0
        options.stopOthers = false
        // Need to sort out DVTPlaygroundCommunication before using this
        options.setPlaygroundTransformEnabled(false)

        return frame.evaluateExpression(expression, options: options)
    }
}

extension DispatchQueue {
    static let debuggerEvents = DispatchQueue(label: "ca.brandonevans.JungleGym.debuggerEvents", qos: .background)
}
