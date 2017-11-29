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

    var playground = Playground(contents: "") {
        didSet {
            if isWindowLoaded {
                editorViewController.contents = playground.contents
            }
        }
    }
    var simulatorManager: SimulatorManager!
    var session: ExecutionSession?

    override func windowDidLoad() {
        do {
            simulatorManager = try SimulatorManager()
        }
        catch {
            // NSAlert, exit
            assertionFailure(error.localizedDescription)
        }

        splitViewController = NSSplitViewController()
        splitViewController.view.wantsLayer = true
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        splitViewController.splitView.dividerStyle = .paneSplitter
        contentViewController = splitViewController

        editorViewController = NSStoryboard.main.instantiateController(withIdentifier: .editorViewController) as! EditorViewController
        let editorItem = NSSplitViewItem(viewController: editorViewController)
        editorItem.canCollapse = false
        editorItem.holdingPriority = NSLayoutConstraint.Priority(rawValue: 251)
        editorViewController.view.translatesAutoresizingMaskIntoConstraints = false
        editorViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        editorViewController.contents = playground.contents
        editorViewController.delegate = self

        simulatorViewController = NSStoryboard.main.instantiateController(withIdentifier: .simulatorViewController) as! SimulatorViewController
        let simulatorItem = NSSplitViewItem(viewController: simulatorViewController)
        simulatorItem.canCollapse = false
        simulatorViewController.view.translatesAutoresizingMaskIntoConstraints = false
        simulatorViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        splitViewController.splitViewItems = [editorItem, simulatorItem]
    }

    func executePlayground() {
        simulatorManager.allocateSimulator() { result in
            guard case let .success(simulator) = result else {
                self.session = nil
                print(result.error!)
                return
            }

            do {
                let session = ExecutionSession(simulator: simulator)
                self.session = session

                try session.prepare(with: self.playground.contents)

                session.delegate = self.editorViewController

                // Having troubles getting to the device property from Swift...
                self.simulatorViewController.simulatorScreenScale = 3.0 // simulator.device.deviceType.mainScreenScale
                if let initialSurface = try simulator.framebuffer().surface?.attach(self.simulatorViewController, on: DispatchQueue.main) {
                    self.simulatorViewController.didChange(initialSurface.takeUnretainedValue())
                }

                session.execute()
            }
            catch {
                self.session = nil
                print(error)
            }
        }
    }
}

extension PlaygroundWindowController {
    @IBAction
    func executePlayground(sender: Any?) {
        executePlayground()
    }
}

extension PlaygroundWindowController: EditorViewDelegate {
    func editorTextDidChange(_ text: String) {
        playground.contents = text
    }
}

extension NSStoryboard {
    static let main = NSStoryboard(name: .main, bundle: nil)
}

extension NSStoryboard.Name {
    static let main = NSStoryboard.Name(rawValue: "Main")
}
