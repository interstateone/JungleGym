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
        case waiting, preparing, ready, executing, stopping, finished
    }

    public var state = State.waiting {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.stateChanged(to: self.state)
            }
        }
    }

    public let simulator: FBSimulator
    private let debugger: Debugger

    public weak var delegate: ExecutionSessionDelegate?

    public init(simulator: FBSimulator, debugger: Debugger) {
        self.simulator = simulator
        self.debugger = debugger
    }

    public func execute(_ expression: String, completion: ((Result<Void, AnyError>) -> Void)? = nil) {
        switch Result(attempt: { () -> URL in
            try prepare(with: expression)
            state = .executing

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
                        try self.debugger.attach(to: pid)
                    })
                }
                .perform(completion, on: .main)
            }
        case let .failure(error):
            Result(error: AnyError(error))
                .perform(completion, on: .main)
        }
    }

    public func stop(completion: (() -> Void)? = nil) {
        state = .stopping
        simulator.killApplication(withBundleID: "ca.brandonevans.JungleGymStub").onQueue(.main, map: { _ -> Void in
            self.teardown()
            completion?()
        })
    }

    // MARK: - Private

    private func prepare(with expression: String) throws {
        guard case .waiting = state else { throw Error.invalidState(state, .preparing) }
        state = .preparing

        debugger.addBreakpoint(named: "_executePlayground") { process, _, _ in
            print("TODO: evaluate playground expression")
            guard
                let process = process,
                let frame = process.allThreads.first?.allFrames.compactMap({ $0 }).first
                else { return true }

            if process.state != .running {
                print("---")
                print("State: \(process.state)")
                print(process.allThreads.first?.allFrames.compactMap { $0 }.first?.lineEntry ?? "")
                print(process.allThreads.first?.allFrames.compactMap { $0 }.first?.functionName ?? "")
            }

            let result = self.debugger.evaluate(expression: expression, in: frame)
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
            self.state = .stopping
            self.teardown()
            return true
        }

        state = .ready
    }

    private func teardown() {
        debugger.deleteAllBreakpoints()
        debugger.detach()
        state = .finished
    }

    // MARK: -

    public struct Error: Swift.Error {
        let reason: String
        static let invalidState: (State, State) -> Error = { from, to in Error(reason: "Unable to transition from \(from) to \(to)") }
    }
}
