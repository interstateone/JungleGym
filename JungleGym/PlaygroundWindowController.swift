//
//  SessionViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-20.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa
import LLDBWrapper
import FBSimulatorControl

class PlaygroundWindowController: NSWindowController {
    var splitViewController: NSSplitViewController!
    var editorViewController: EditorViewController!
    var simulatorViewController: SimulatorViewController!

    @IBOutlet weak var runButton: NSToolbarItem!
    @IBOutlet weak var simulatorPopupButton: NSPopUpButton!
    @IBOutlet weak var stateTextField: NSTextField!

    override var document: AnyObject? {
        didSet {
            if isWindowLoaded {
                editorViewController.contents = playground?.contents ?? ""
                stateTextField.stringValue = playground?.displayName ?? ""
            }
        }
    }
    var playground: Playground? {
        return document as? Playground
    }

    var simulatorManager: SimulatorManager!
    var session: ExecutionSession? {
        didSet {
            if session != nil {
                runButton.image = NSImage(named: .stop)
            }
            else {
                runButton.image = NSImage(named: .run)
            }
        }
    }

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
        editorViewController.contents = playground?.contents ?? ""
        editorViewController.delegate = self

        simulatorViewController = NSStoryboard.main.instantiateController(withIdentifier: .simulatorViewController) as! SimulatorViewController
        let simulatorItem = NSSplitViewItem(viewController: simulatorViewController)
        simulatorItem.canCollapse = false
        simulatorViewController.view.translatesAutoresizingMaskIntoConstraints = false
        simulatorViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        splitViewController.splitViewItems = [editorItem, simulatorItem]

        simulatorPopupButton.removeAllItems()
        simulatorPopupButton.addItems(withTitles: simulatorManager.availableSimulatorConfigurations.map { $0.device.model.rawValue })
        simulatorPopupButton.selectItem(at: 0)

        // Seems to need to happen on the next run loop
        DispatchQueue.main.async {
            self.updateSimulatorPopupButtonWidth()
        }

        stateTextField.stringValue = playground?.displayName ?? ""
    }

    func executePlayground() {
        guard let playground = playground else { return }

        let selectedConfiguration = simulatorManager.availableSimulatorConfigurations[simulatorPopupButton.indexOfSelectedItem]
        simulatorManager.allocateSimulator(with: selectedConfiguration) { result in
            guard case let .success(simulator) = result else {
                self.session = nil
                print(result.error!)
                return
            }

            do {
                LLDBGlobals.initializeLLDBWrapper()
                let debugger = try Debugger()

                let session = ExecutionSession(simulator: simulator, debugger: debugger)
                session.delegate = self
                self.session = session

                // Having troubles getting to the device property from Swift...
                self.simulatorViewController.simulatorScreenScale = 3.0 // simulator.device.deviceType.mainScreenScale
                if let initialSurface = try simulator.framebuffer().surface?.attach(self.simulatorViewController, on: DispatchQueue.main) {
                    self.simulatorViewController.didChange(initialSurface.takeUnretainedValue())
                }

                session.execute(playground.contents)
            }
            catch {
                self.session = nil
                print(error)
            }
        }
    }

    private let measuringPopupButton = NSPopUpButton()

    /// sizeToFit will size for the widest menu item, but I want it to size for the _selected_ item
    /// Use a hidden button to calculate the correct frame
    private func updateSimulatorPopupButtonWidth() {
        measuringPopupButton.removeAllItems()
        measuringPopupButton.addItem(withTitle: simulatorPopupButton.selectedItem?.title ?? "")
        measuringPopupButton.sizeToFit()

        simulatorPopupButton.frame = NSRect(
            origin: simulatorPopupButton.frame.origin,
            size: measuringPopupButton.frame.size
        )
    }
}

extension PlaygroundWindowController {
    @IBAction
    func runOrStop(sender: Any?) {
        if let session = session {
            session.stop() { [weak self] in
                self?.session = nil
            }
        }
        else {
            executePlayground()
        }
    }

    @IBAction
    func selectSimulator(sender: Any?) {
        updateSimulatorPopupButtonWidth()
    }
}

extension PlaygroundWindowController: EditorViewDelegate {
    func editorTextDidChange(_ text: String) {
        playground?.contents = text
    }
}

extension PlaygroundWindowController: ExecutionSessionDelegate {
    func stateChanged(to state: ExecutionSession.State) {
        guard let playground = playground else { return }

        stateTextField.stringValue = "\(playground.displayName ?? ""): \(String(describing: state).capitalized)"
    }
}

extension NSStoryboard {
    static let main = NSStoryboard(name: .main, bundle: nil)
}

extension NSStoryboard.Name {
    static let main = NSStoryboard.Name(rawValue: "Main")
}

extension NSStoryboard.SceneIdentifier {
    static let playgroundWindowController = NSStoryboard.SceneIdentifier(rawValue: String(describing: PlaygroundWindowController.self))
}

extension NSImage.Name {
    static let run = NSImage.Name(rawValue: "Run")
    static let stop = NSImage.Name(rawValue: "Stop")
}
