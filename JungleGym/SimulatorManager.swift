//
//  SimulatorManager.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-17.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import FBSimulatorControl

public class SimulatorManager {
    public enum Error: Swift.Error {
        case unableToCreateDeviceSet
        case invalidApplication
    }

    let control: FBSimulatorControl

    init() throws {
        let options = FBSimulatorManagementOptions()
        let config = FBSimulatorControlConfiguration(deviceSetPath: try SimulatorManager.deviceSetDirectory().path, options: options)
        let logger = FBControlCoreGlobalConfiguration.defaultLogger
        control = try FBSimulatorControl.withConfiguration(config, logger: logger)
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

    public func allocateSimulator() throws -> FBSimulator {
        let simulator = try control.pool.allocateSimulator(
            with: FBSimulatorConfiguration.withDeviceModel(.modeliPhone6),
            options: [.reuse, .create]
        ).await()

        if simulator.state != .booted {
            print("Booting Simulator \(simulator)")
            try simulator.boot().await()
        }

        return simulator
    }

    func launchApp(at url: URL, in simulator: FBSimulator) throws -> ProcessID {
        let infoPlistURL = url.appendingPathComponent("Info.plist")
        let infoPlistData = try Data(contentsOf: infoPlistURL)
        guard
            let infoPlist = try PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
            let bundleID = infoPlist["CFBundleIdentifier"] as? String
        else {
            throw Error.invalidApplication
        }

        let installedApplications = try simulator.installedApplications().await() as! [FBInstalledApplication]
        if !installedApplications.contains(where: { $0.bundle.bundleID == bundleID }) {
            try simulator.installApplication(withPath: url.path).await()
        }

        let outputConfiguration = try FBProcessOutputConfiguration(stdOut: FBProcessOutputToFileDefaultLocation, stdErr: FBProcessOutputToFileDefaultLocation)
        let launchConfiguration = FBApplicationLaunchConfiguration(bundleID: bundleID, bundleName: nil, arguments: [], environment: [:], waitForDebugger: true, output: outputConfiguration)
        return try simulator.launchApplication(launchConfiguration)
            .onQueue(.main, map: { processIDNumber in processIDNumber.intValue })
            .await() as! ProcessID
    }
}

public typealias ProcessID = Int