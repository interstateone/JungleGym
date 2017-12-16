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

    @IBOutlet weak var toolbarContainerView: NSView!
    var runButton: NSButton!
    var simulatorPopupButton: NSPopUpButton!
    var stateTextField: NSTextField!
    var simulatorPopupButtonWidth: NSLayoutConstraint!

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

    /// A playground window controller has at most one simulator at a time
    /// When a playground is first run, allocate an appropriate simulator in the pool
    /// When the playground is closed, free the simulator
    /// When a playground is run with a new simulator device type, free the current one and allocate a new appropriate simulator
    var simulator: FBSimulator?

    var session: ExecutionSession? {
        didSet {
            if session != nil {
                runButton.image = NSImage(named: .stop)
                runButton.keyEquivalent = "."
                runButton.keyEquivalentModifierMask = .command
            }
            else {
                runButton.image = NSImage(named: .run)
                runButton.keyEquivalent = "r"
                runButton.keyEquivalentModifierMask = .command
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

        setupToolbar()
        setupContentViews()
    }

    func prepareSimulatorToExecutePlayground() {
        guard let playground = playground else { return }
        let selectedConfiguration = simulatorManager.availableSimulatorConfigurations[simulatorPopupButton.indexOfSelectedItem]

        if let simulator = simulator,
           simulator.configuration == selectedConfiguration {
            do {
                try execute(playground, with: simulator)
            }
            catch {
                self.session = nil
                print(error)
            }
        }
        else {
            if let simulator = simulator {
                simulator.freeFromPool()
            }

            updateStatusMessage("Starting simulator...")
            simulatorManager.allocateSimulator(with: selectedConfiguration) { result in
                guard case let .success(simulator) = result else {
                    self.session = nil
                    self.simulator = nil
                    print(result.error!)
                    return
                }
                self.simulator = simulator

                do {
                    // Having troubles getting to the device property from Swift...
                    self.simulatorViewController.simulatorScreenScale = 3.0 // simulator.device.deviceType.mainScreenScale
                    if let initialSurface = try simulator.framebuffer().surface?.attach(self.simulatorViewController, on: DispatchQueue.main) {
                        self.simulatorViewController.didChange(initialSurface.takeUnretainedValue())
                    }

                    try self.execute(playground, with: simulator)
                }
                catch {
                    self.session = nil
                    print(error)
                }
            }
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(run(_:))?:
            return session == nil
        case #selector(stop(_:))?:
            return session != nil
        default:
            return true
        }
    }

    private func execute(_ playground: Playground, with simulator: FBSimulator) throws {
        let debugger = try Debugger()

        let session = ExecutionSession(simulator: simulator, debugger: debugger)
        session.delegate = self
        self.session = session

        session.execute(playground.contents)
    }

    private let measuringPopupButton = NSPopUpButton()

    /// sizeToFit will size for the widest menu item, but I want it to size for the _selected_ item
    /// Use a hidden button to calculate the correct frame
    private func updateSimulatorPopupButtonWidth() {
        measuringPopupButton.removeAllItems()
        measuringPopupButton.addItem(withTitle: simulatorPopupButton.selectedItem?.title ?? "")
        measuringPopupButton.sizeToFit()

        simulatorPopupButtonWidth.constant = measuringPopupButton.frame.width
    }

    private func updateStatusMessage(_ message: String) {
        guard let playground = playground else { return }
        stateTextField.stringValue = "\(playground.displayName ?? ""): \(message)"
    }

    private func setupToolbar() {
        let runButton = NSButton(image: NSImage(named: .run)!, target: self, action: #selector(runOrStop(sender:)))
        self.runButton = runButton
        runButton.keyEquivalent = "r"
        runButton.keyEquivalentModifierMask = .command
        runButton.bezelStyle = .texturedRounded
        runButton.sizeToFit()
        runButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        runButton.setContentCompressionResistancePriority(.required, for: .vertical)
        toolbarContainerView.addSubview(runButton, constraints: [
            runButton.leadingAnchor.constraint(equalTo: toolbarContainerView.leadingAnchor, constant: 1),
            runButton.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            runButton.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor)
        ])

        let simulatorPopupButton = NSPopUpButton(title: "", target: self, action: #selector(selectSimulator(sender:)))
        self.simulatorPopupButton = simulatorPopupButton
        simulatorPopupButton.bezelStyle = .texturedRounded
        toolbarContainerView.addSubview(simulatorPopupButton, constraints: [
            simulatorPopupButton.leadingAnchor.constraint(equalTo: runButton.trailingAnchor, constant: 8),
            simulatorPopupButton.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            simulatorPopupButton.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            simulatorPopupButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
        simulatorPopupButtonWidth = simulatorPopupButton.widthAnchor.constraint(equalToConstant: 100).with(priority: .defaultHigh)
        simulatorPopupButtonWidth.isActive = true

        let stateTextField = NSTextField(labelWithString: "")
        self.stateTextField = stateTextField
        stateTextField.isBezeled = true
        stateTextField.bezelStyle = .roundedBezel
        stateTextField.drawsBackground = true
        stateTextField.isEditable = false
        stateTextField.isSelectable = false
        toolbarContainerView.addSubview(stateTextField, constraints: [
            stateTextField.leadingAnchor.constraint(greaterThanOrEqualTo: simulatorPopupButton.trailingAnchor, constant: 8),
            stateTextField.centerXAnchor.constraint(equalTo: toolbarContainerView.centerXAnchor),
            stateTextField.centerYAnchor.constraint(equalTo: toolbarContainerView.centerYAnchor),
            stateTextField.widthAnchor.constraint(equalToConstant: 400).with(priority: .defaultHigh)
        ])

        simulatorPopupButton.removeAllItems()
        simulatorPopupButton.addItems(withTitles: simulatorManager.availableSimulatorConfigurations.map { $0.device.model.rawValue })
        simulatorPopupButton.selectItem(at: 0)

        // Seems to need to happen on the next run loop
        DispatchQueue.main.async {
            self.updateSimulatorPopupButtonWidth()
        }

        updateStatusMessage("")
    }

    private func setupContentViews() {
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
            prepareSimulatorToExecutePlayground()
        }
    }

    @IBAction
    func selectSimulator(sender: Any?) {
        updateSimulatorPopupButtonWidth()
    }

    @IBAction
    func run(_ sender: Any?) {
        guard session == nil else { return }
        prepareSimulatorToExecutePlayground()
    }

    @IBAction
    func stop(_ sender: Any?) {
        guard let session = session else { return }
        session.stop() { [weak self] in
            self?.session = nil
        }
    }
}

extension PlaygroundWindowController: EditorViewDelegate {
    func editorTextDidChange(_ text: String) {
        playground?.contents = text
    }
}

extension PlaygroundWindowController: ExecutionSessionDelegate {
    func stateChanged(to state: ExecutionSession.State) {
        updateStatusMessage(String(describing: state).capitalized)
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
