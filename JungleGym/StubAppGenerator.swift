//
//  StubAppGenerator.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-18.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation

public class StubAppGenerator {
    /// Creates a code-signed app bundle with a stub binary, unless it already exists
    ///
    /// - Parameter name: The name of the app bundle. Don't include the file extension
    /// - Parameter directoryURL: The directory to create the app bundle in
    /// - Returns: URL to the created app bundle
    /// - Throws: Errors during app bundle creation
    static func createStubApp(named name: String, in directoryURL: URL) throws -> URL {
        let fileManager = FileManager.default

        // Make a folder in the directory for the app bundle
        let appBundleURL = directoryURL.appendingPathComponent("\(name).app")

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: appBundleURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            return appBundleURL
        }

        try fileManager.createDirectory(at: appBundleURL, withIntermediateDirectories: true, attributes: nil)

        // Copy the stub binary
        let stubBinarySource = Bundle.main.resourceURL!.appendingPathComponent("JungleGymStub") // If _this_ fails, just crash
        let stubBinaryDestination = appBundleURL.appendingPathComponent("JungleGymStub")
        try fileManager.copyItem(at: stubBinarySource, to: stubBinaryDestination)

        // Create Info.plist
        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        let infoPlist: [String: Any] = [
            "CFBundleExecutable": "JungleGymStub",
            "CFBundleIdentifier": "ca.brandonevans.JungleGymStub",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleName": "JungleGymStub",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "LSRequiresIPhoneOS": true,
            "UIRequiredDeviceCapabilities": ["armv7"],
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait"]
        ]
        let infoPlistData = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .binary, options: PropertyListSerialization.WriteOptions())
        try infoPlistData.write(to: infoPlistURL)

        // Create PkgInfo
        let pkgInfoURL = appBundleURL.appendingPathComponent("PkgInfo")
        let pkgInfo = "APPL????"
        try pkgInfo.write(to: pkgInfoURL, atomically: true, encoding: .utf8)

        // Codesign the bundle
        let codesignProcess = Process()
        codesignProcess.arguments = ["--force", "--sign", "-", appBundleURL.path]
        codesignProcess.environment = ["CODESIGN_ALLOCATE": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate"]
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.currentDirectoryURL = directoryURL

        codesignProcess.launchAndPrintStandardOutputAndError()
        codesignProcess.waitUntilExit()

        return appBundleURL
    }
}
