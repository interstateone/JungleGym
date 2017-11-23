//
//  StubAppGenerator.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-18.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa
import CoreGraphics

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

        // Add launch images
        struct LaunchImage {
            let name: String
            let size: CGSize
            let scale: CGFloat
            let suffix: String?
            static let _4inch = LaunchImage(name: "Default", size: CGSize(width: 320, height: 568), scale: 2, suffix: "-568h")
            static let _4_7inch = LaunchImage(name: "Default", size: CGSize(width: 375, height: 667), scale: 2, suffix: "-667h")
            static let _5_5inch = LaunchImage(name: "Default", size: CGSize(width: 414, height: 736), scale: 3, suffix: "-736h")
            static let _5_8inch = LaunchImage(name: "Default", size: CGSize(width: 375, height: 812), scale: 3, suffix: "-812h")
            static let all: [LaunchImage] = [._4inch, ._4_7inch, ._5_5inch, ._5_8inch]
        }
        for image in LaunchImage.all {
            let launchImageURL = appBundleURL.appendingPathComponent(String(format: "%@%@@%.0fx.png", image.name, image.suffix ?? "", image.scale))
            let image = NSImage.imageOfSize(CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale), color: .black)
            try image?.pngData?.write(to: launchImageURL)
        }

        // Create Info.plist
        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        let infoPlist: [String: Any] = [
            "CFBundleExecutable": "JungleGymStub",
            "CFBundleIdentifier": "ca.brandonevans.JungleGymStub",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleName": "JungleGymStub",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleSupportedPlatforms": ["iphonesimulator"],
            "CFBundleVersion": "1",
            "LSBackgroundOnly": true,
            "LSRequiresIPhoneOS": true,
            "UIDeviceFamily": [1, 2],
            "UILaunchImages": LaunchImage.all.map { image in
                [
                    "UILaunchImageName": "\(image.name)\(image.suffix ?? "")",
                    "UILaunchImageMinimumOSVersion": "8.0",
                    "UILaunchImageSize": String(format: "{%.0f, %.0f}", image.size.width, image.size.height)
                ]
            },
            "UIRequiredDeviceCapabilities": ["armv7"],
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait"],
            "UIStatusBarHidden": true,
            "UIViewControllerBasedStatusBarAppearance": false
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

extension NSImage {
    static func imageOfSize(_ size: CGSize, color: NSColor) -> NSImage? {
        let rect = CGRect(origin: .zero, size: size)
        let context = CGContext(data: nil, width: Int(rect.size.width), height: Int(rect.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: NSColorSpace.genericRGB.cgColorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
        context.setFillColor(NSColor.white.cgColor)
        context.fill(rect)
        guard let imageRef = context.makeImage() else { return nil }
        return NSImage(cgImage: imageRef, size: rect.size)
    }

    var pngData: Data? {
        lockFocus()
        let bitmapRep = NSBitmapImageRep(focusedViewRect: CGRect(origin: .zero, size: size))
        unlockFocus()
        return bitmapRep?.representation(using: .png, properties: [:])
    }
}
