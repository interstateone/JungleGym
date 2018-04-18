//
//  SimulatorManager.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-17.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import FBSimulatorControl
import Result

public class SimulatorManager {
    public enum Error: Swift.Error {
        case unableToCreateDeviceSet
    }

    private let control: FBSimulatorControl
    public let availableSimulatorConfigurations: [FBSimulatorConfiguration]

    public init() throws {
        let options = FBSimulatorManagementOptions()
        let config = FBSimulatorControlConfiguration(deviceSetPath: try SimulatorManager.deviceSetDirectory().path, options: options)
        let logger = FBControlCoreGlobalConfiguration.defaultLogger
        control = try FBSimulatorControl.withConfiguration(config, logger: logger)
        availableSimulatorConfigurations = FBSimulatorConfiguration.allAvailableDefaultConfigurations(with: logger)
            .filter { $0.os.families.isSubset(of: [
                NSNumber(value: FBControlCoreProductFamily.familyiPhone.rawValue),
                NSNumber(value: FBControlCoreProductFamily.familyiPad.rawValue)
            ]) }
    }

    deinit {
        control.set.allSimulators.filter { $0.state == .booted }.forEach { $0.shutdown() }
    }

    // create a new set in app support dir
    static func deviceSetDirectory() throws -> URL {
        let executableName = Bundle.main.infoDictionary?["CFBundleExecutable"] as! String // If _this_ fails, let's just crash

        guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            throw Error.unableToCreateDeviceSet
        }

        let url = URL(fileURLWithPath: path)
            .appendingPathComponent(executableName)
            .appendingPathComponent("Simulators")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

        return url
    }

    public func allocateSimulator(with configuration: FBSimulatorConfiguration, completion: ((Result<FBSimulator, AnyError>) -> Void)? = nil) {
        DispatchQueue.simulatorManager.async {
            Result(attempt: {
                let simulator = try self.control.pool.allocateSimulator(
                    with: configuration,
                    options: [.reuse, .create]
                ).await()

                if simulator.state != .booted {
                    print("Booting Simulator \(simulator)")
                    let config = FBSimulatorBootConfiguration.default.withOptions([.enableDirectLaunch, .verifyUsable])
                    try simulator.boot(with: config).await()
                }

                return simulator
            })
            .perform(completion, on: .main)
        }
    }
}

extension FBSimulator {
    public enum Error: Swift.Error {
        case invalidApplication
    }

    public func launchApp(at url: URL, completion: ((Result<ProcessID, AnyError>) -> Void)? = nil) {
        DispatchQueue.simulatorManager.async {
            Result(attempt: {
                let bundleID = try self.bundleID(of: url)

                let installedApplications = try self.installedApplications().await() as! [FBInstalledApplication]
                if installedApplications.contains(where: { $0.bundle.bundleID == bundleID }) {
                    try self.uninstallApplication(withBundleID: bundleID).await()
                }

                try self.installApplication(withPath: url.path).await()

                let outputConfiguration = try FBProcessOutputConfiguration(stdOut: FBProcessOutputToFileDefaultLocation, stdErr: FBProcessOutputToFileDefaultLocation)
                let launchConfiguration = FBApplicationLaunchConfiguration(bundleID: bundleID, bundleName: nil, arguments: [], environment: self.environmentVariables, waitForDebugger: true, output: outputConfiguration)

                _ = try? self.killApplication(withBundleID: bundleID).await()

                return try self.launchApplication(launchConfiguration)
                    .onQueue(.main, map: { processIDNumber in processIDNumber.intValue })
                    .await() as! ProcessID
            })
            .perform(completion, on: .main)
        }
    }

    private func bundleID(of url: URL) throws -> String {
        let infoPlistURL = url.appendingPathComponent("Info.plist")
        let infoPlistData = try Data(contentsOf: infoPlistURL)
        guard
            let infoPlist = try PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
            let bundleID = infoPlist["CFBundleIdentifier"] as? String
        else {
            throw Error.invalidApplication
        }

        return bundleID
    }

    /// From ProcessInfo.processInfo.environment in a real playground
    private var environmentVariables: [String: String] {
        return [
            "DYLD_ROOT_PATH": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot",
            "DYLD_LIBRARY_PATH": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator",
            "DYLD_FALLBACK_FRAMEWORK_PATH": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks",
            "DYLD_FALLBACK_LIBRARY_PATH": "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib",
            "DYLD_FRAMEWORK_PATH": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks"
        ]
    }
}

public typealias ProcessID = Int

extension DispatchQueue {
    static let simulatorManager = DispatchQueue(label: "ca.brandonevans.JungleGym.simulator-manager", qos: .userInitiated, attributes: DispatchQueue.Attributes(rawValue: 0), autoreleaseFrequency: .inherit, target: nil)
}
