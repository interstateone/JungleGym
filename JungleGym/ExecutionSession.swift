//
//  ExecutionSession.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-20.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import FBSimulatorControl
import LLDBWrapper
import Result

public protocol ExecutionSessionDelegate: class {
    func stateChanged(to state: ExecutionSession.State)
}

public class ExecutionSession {
    public enum State {
        case waiting, preparing, ready, executing, finished
    }

    public struct Error: Swift.Error {
        let reason: String
        static let invalidState: (State, State) -> Error = { from, to in Error(reason: "Unable to transition from \(from) to \(to)") }
    }

    var state = State.waiting {
        didSet {
            delegate?.stateChanged(to: state)
        }
    }

    let simulator: FBSimulator
    var debugger: Debugger?
    weak var delegate: ExecutionSessionDelegate?

    public init(simulator: FBSimulator) {
        self.simulator = simulator
    }

    func prepare(with expression: String) throws {
        guard case .waiting = state else { throw Error.invalidState(state, .preparing) }
        state = .preparing

        LLDBGlobals.initializeLLDBWrapper()

        let debugger = try Debugger()
        self.debugger = debugger
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
            // The stub should notify the host of this, but this will do until a communication mechanism is in place
            self.state = .finished
            return true
        }

        state = .ready
    }

    func execute(_ completion: ((Result<Void, AnyError>) -> Void)? = nil) {
        guard
            case .ready = state,
            let debugger = debugger
        else {
            Result(error: AnyError(Error.invalidState(state, .executing)))
                .perform(completion, on: .main)
            return
        }

        state = .executing

        switch Result(attempt: { () -> URL in
            let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ca.brandonevans.JungleGym")
            return try StubAppGenerator.createStubApp(named: "stub", in: temporaryDirectory)
        }) {
        case let .success(appURL):
            print(appURL)
            simulator.launchApp(at: appURL) { result in
                result
                .flatMap { pid in
                    Result(attempt: {
                        print(pid)
                        try debugger.attach(to: pid)
                    })
                }
                .perform(completion, on: .main)
            }
        case let .failure(error):
            Result(error: AnyError(error))
                .perform(completion, on: .main)
        }
    }
}
