//
//  EditorViewController.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-20.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Cocoa

protocol EditorViewDelegate: class {
    func editorTextDidChange(_ text: String)
}

class EditorViewController: NSViewController {
    @IBOutlet private weak var scrollView: NSScrollView!
    @IBOutlet private weak var textView: NSTextView!
    @IBOutlet private weak var stateLabel: NSTextField!

    private var rulerView: RulerView?
    private var syntaxHighligher: SwiftSyntaxHighlighter?

    weak var delegate: EditorViewDelegate?

    var contents: String {
        get {
            return textView.string
        }
        set {
            textView.string = newValue
            rulerView?.invalidateLineIndices()
            rulerView?.needsDisplay = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.textContainerInset = NSSize(width: 0, height: 1)
        textView.font = NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: NSText.didChangeNotification, object: textView)

        rulerView = RulerView(scrollView: scrollView, orientation: .verticalRuler)
        scrollView?.verticalRulerView = rulerView
        scrollView?.hasHorizontalRuler = false
        scrollView?.hasVerticalRuler = true
        scrollView?.rulersVisible = true

        syntaxHighligher = SwiftSyntaxHighlighter(textStorage: textView.textStorage!, textView: textView, scrollView: scrollView!)
    }

    @objc
    func textDidChange(_ notification: Notification) {
        delegate?.editorTextDidChange(textView.string)
    }
}

extension EditorViewController: ExecutionSessionDelegate {
    func stateChanged(to state: ExecutionSession.State) {
        stateLabel.stringValue = "\(state)"
    }
}

extension NSStoryboard.SceneIdentifier {
    static let editorViewController = NSStoryboard.SceneIdentifier(rawValue: String(describing: EditorViewController.self))
}
