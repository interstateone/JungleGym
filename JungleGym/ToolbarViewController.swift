//
//  ToolbarViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2018-01-30.
//  Copyright © 2018 Brandon Evans. All rights reserved.
//

import AppKit

protocol ToolbarDelegate: class {
    func runOrStop()
    func selectSimulator(at index: Int)
}

final class ToolbarViewController: NSViewController {
    @IBOutlet var runButton: NSButton!
    @IBOutlet var simulatorPopupButton: NSPopUpButton!
    @IBOutlet var stateTextField: NSTextField!
    @IBOutlet var simulatorPopupButtonWidth: NSLayoutConstraint!

    weak var delegate: ToolbarDelegate?

    struct State {
        var running: Bool = false
        var status: String = ""
        var simulators: [String] = []
        var selectedSimulatorIndex: Int = 0
    }

    var state: State = State() {
        didSet {
            if !oldValue.running && state.running {
                runButton.image = NSImage(named: .stop)
                runButton.keyEquivalent = "."
                runButton.keyEquivalentModifierMask = .command
            }
            else if oldValue.running && !state.running {
                runButton.image = NSImage(named: .run)
                runButton.keyEquivalent = "r"
                runButton.keyEquivalentModifierMask = .command
            }

            stateTextField.stringValue = state.status

            if oldValue.simulators != state.simulators || state.simulators.isEmpty {
                updateSimulators()
            }

            if oldValue.selectedSimulatorIndex != state.selectedSimulatorIndex {
                updateSimulatorPopupButtonWidth()
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

        simulatorPopupButtonWidth.constant = measuringPopupButton.frame.width
    }

    private func updateSimulators() {
        simulatorPopupButton.removeAllItems()
        simulatorPopupButton.addItems(withTitles: state.simulators)
        simulatorPopupButton.selectItem(at: state.selectedSimulatorIndex)
    }
}

extension ToolbarViewController {
    @IBAction
    func runOrStop(sender: Any?) {
        delegate?.runOrStop()
    }

    @IBAction
    func selectSimulator(sender: Any?) {
        updateSimulatorPopupButtonWidth()
        state.selectedSimulatorIndex = simulatorPopupButton.indexOfSelectedItem
        delegate?.selectSimulator(at: simulatorPopupButton.indexOfSelectedItem)
    }
}

extension NSImage.Name {
    static let run = NSImage.Name(rawValue: "Run")
    static let stop = NSImage.Name(rawValue: "Stop")
}

extension NSStoryboard.SceneIdentifier {
    static let toolbarViewController = NSStoryboard.SceneIdentifier(rawValue: String(describing: ToolbarViewController.self))
}
