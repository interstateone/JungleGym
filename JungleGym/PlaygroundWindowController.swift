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
    var toolbarViewController: ToolbarViewController!

    @IBOutlet weak var toolbarContainerView: NSView!

    override var document: AnyObject? {
        didSet {
            if isWindowLoaded {
                editorViewController.contents = playground?.contents ?? ""
                toolbarViewController.state.status = playground?.displayName ?? ""
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

    var selectedSimulatorConfiguration: FBSimulatorConfiguration?

    var session: ExecutionSession? {
        didSet {
            toolbarViewController.state.running = session != nil
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

        setupContentViews()

        toolbarViewController.state.simulators = simulatorManager.availableSimulatorConfigurations.map { $0.device.model.rawValue }
        updateStatusMessage("")
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

    func prepareSimulatorToExecutePlayground() {
        guard
            let playground = playground,
            let selectedConfiguration = selectedSimulatorConfiguration
        else { return }

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
                    self.simulatorViewController.simulatorScreenScale = simulator.mainScreenScale
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

    private func execute(_ playground: Playground, with simulator: FBSimulator) throws {
        let debugger = try Debugger()

        let session = ExecutionSession(simulator: simulator, debugger: debugger)
        session.delegate = self
        self.session = session

        session.execute(playground.contents)
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

        toolbarViewController = NSStoryboard.main.instantiateController(withIdentifier: .toolbarViewController) as! ToolbarViewController
        toolbarViewController.delegate = self
        toolbarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarContainerView.addSubview(toolbarViewController.view, constraints: [
            toolbarViewController.view.leadingAnchor.constraint(equalTo: toolbarContainerView.leadingAnchor),
            toolbarViewController.view.trailingAnchor.constraint(equalTo: toolbarContainerView.trailingAnchor),
            toolbarViewController.view.topAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            toolbarViewController.view.bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor)
        ])
    }

    private func updateStatusMessage(_ message: String) {
        guard let playground = playground else { return }
        toolbarViewController.state.status = "\(playground.displayName ?? ""): \(message)"
    }
}

extension PlaygroundWindowController {
    // MARK: Menu Actions

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

extension PlaygroundWindowController: ToolbarDelegate {
    func runOrStop() {
        if let session = session {
            session.stop() { [weak self] in
                self?.session = nil
            }
        }
        else {
            prepareSimulatorToExecutePlayground()
        }
    }

    func selectSimulator(at index: Int) {
        selectedSimulatorConfiguration = simulatorManager.availableSimulatorConfigurations[index]
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
