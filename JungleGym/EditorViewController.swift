//
//  EditorViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-20.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {
    @IBOutlet weak var stateLabel: NSTextField!
}

extension EditorViewController: ExecutionSessionDelegate {
    func stateChanged(to state: ExecutionSession.State) {
        stateLabel.stringValue = "\(state)"
    }
}

extension NSStoryboard.SceneIdentifier {
    static let editorViewController = NSStoryboard.SceneIdentifier(rawValue: String(describing: EditorViewController.self))
}
