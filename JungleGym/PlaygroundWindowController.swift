//
//  SessionViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-20.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa

class PlaygroundWindowController: NSWindowController {
    var splitViewController: NSSplitViewController!
    var editorViewController: EditorViewController!
    var simulatorViewController: SimulatorViewController!

    var session: ExecutionSession?

    override func windowDidLoad() {
        splitViewController = NSSplitViewController()
        splitViewController.view.wantsLayer = true
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        splitViewController.splitView.dividerStyle = .paneSplitter
        contentViewController = splitViewController

        editorViewController = NSStoryboard.main.instantiateController(withIdentifier: .editorViewController) as! EditorViewController
        let editorItem = NSSplitViewItem(viewController: editorViewController)
        editorItem.canCollapse = false
        editorViewController.view.translatesAutoresizingMaskIntoConstraints = false
        editorViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        simulatorViewController = NSStoryboard.main.instantiateController(withIdentifier: .simulatorViewController) as! SimulatorViewController
        let simulatorItem = NSSplitViewItem(viewController: simulatorViewController)
        simulatorItem.canCollapse = false
        simulatorViewController.view.translatesAutoresizingMaskIntoConstraints = false
        simulatorViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        splitViewController.splitViewItems = [editorItem, simulatorItem]
    }
}

extension NSStoryboard {
    static let main = NSStoryboard(name: .main, bundle: nil)
}

extension NSStoryboard.Name {
    static let main = NSStoryboard.Name(rawValue: "Main")
}
