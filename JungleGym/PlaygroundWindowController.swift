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

    @IBOutlet weak var runButton: NSToolbarItem!
    @IBOutlet weak var simulatorPopupButton: NSToolbarItem!

    let playground = Playground()
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

    func executePlayground() {
        do {
            let session = try ExecutionSession()
            self.session = session

            let simulator = try session.prepare(with: playground.contents)

            session.delegate = editorViewController

            // Having troubles getting to the device property from Swift...
            simulatorViewController.simulatorScreenScale = 3.0 // simulator.device.deviceType.mainScreenScale
            if let initialSurface = try simulator.framebuffer().surface?.attach(simulatorViewController, on: DispatchQueue.main) {
                simulatorViewController.didChange(initialSurface.takeUnretainedValue())
            }

            try session.execute()
        }
        catch {
            session = nil
            print(error)
        }
    }
}

extension PlaygroundWindowController {
    @IBAction
    func executePlayground(sender: Any?) {
        executePlayground()
    }
}

extension NSStoryboard {
    static let main = NSStoryboard(name: .main, bundle: nil)
}

extension NSStoryboard.Name {
    static let main = NSStoryboard.Name(rawValue: "Main")
}
