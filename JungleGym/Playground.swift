//
//  Playground.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-23.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa

public class Playground: NSDocument {
    public var contents = """
        import UIKit
        import PlaygroundSupport

        let view = UIView()
        view.frame = UIScreen.main.bounds
        view.backgroundColor = .white
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Is it safe?"
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        PlaygroundPage.current.liveView = view
        """
    private var xcplaygroundContents = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <playground version='5.0' target-platform='ios'>
            <timeline fileName='timeline.xctimeline'/>
        </playground>
        """
    private var packageFileWrapper: FileWrapper?

    public override init() {
        super.init()
    }

    public init(contents: String) {
        self.contents = contents
        super.init()
    }

    public override class var autosavesInPlace: Bool {
        return true
    }

    public override func makeWindowControllers() {
        let windowController = NSStoryboard.main.instantiateController(withIdentifier: .playgroundWindowController) as! NSWindowController
        self.addWindowController(windowController)
    }

    // MARK: - Reading and Writing

    public override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        let childWrappers = fileWrapper.fileWrappers ?? [:]
        if let contentsFileWrapper = childWrappers[FileNames.contents],
           let contentsData = contentsFileWrapper.regularFileContents {
            self.contents = String(data: contentsData, encoding: .utf8) ?? ""
        }
        if let xcplaygroundFileWrapper = childWrappers[FileNames.xcplayground],
           let xcplaygroundData = xcplaygroundFileWrapper.regularFileContents {
            self.xcplaygroundContents = String(data: xcplaygroundData, encoding: .utf8) ?? ""
        }

        self.packageFileWrapper = fileWrapper
    }

    public override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let fileWrapper = packageFileWrapper ?? FileWrapper(directoryWithFileWrappers: [:])
        packageFileWrapper = fileWrapper
        let childWrappers = fileWrapper.fileWrappers ?? [:]

        if let contentsFileWrapper = childWrappers[FileNames.contents] {
            fileWrapper.removeFileWrapper(contentsFileWrapper)
        }
        let contentsData = contents.data(using: .utf8) ?? Data()
        let contentsFileWrapper = FileWrapper(regularFileWithContents: contentsData)
        contentsFileWrapper.preferredFilename = FileNames.contents
        fileWrapper.addFileWrapper(contentsFileWrapper)

        if let xcplaygroundFileWrapper = childWrappers[FileNames.xcplayground] {
            fileWrapper.removeFileWrapper(xcplaygroundFileWrapper)
        }
        let xcplaygroundData = xcplaygroundContents.data(using: .utf8) ?? Data()
        let xcplaygroundFileWrapper = FileWrapper(regularFileWithContents: xcplaygroundData)
        xcplaygroundFileWrapper.preferredFilename = FileNames.xcplayground
        fileWrapper.addFileWrapper(xcplaygroundFileWrapper)

        return fileWrapper
    }

    // MARK: -

    struct FileNames {
        static let contents = "Contents.swift"
        static let xcplayground = "contents.xcplayground"
    }
}
