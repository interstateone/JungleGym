//
//  RulerView.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-27.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//
//  Based on NoodleLineNumberView.m
//  Created by Paul Kim on 9/28/08.
//  Copyright (c) 2008 Noodlesoft, LLC. All rights reserved.
//

import Cocoa

class RulerView: NSRulerView {

    private struct Layout {
        static let minimumWidth: CGFloat = 30
        static let leftPadding: CGFloat = 10
        static let rightPadding: CGFloat = 5
    }

    private var _lineIndices: [Int]? {
        didSet {
            // Not a good idea to resize the view during calculations (which can happen during display)
            DispatchQueue.main.async() {
                let newThickness = self.calculateRulerWidth()
                if abs(self.ruleThickness - newThickness) > 1 {
                    self.ruleThickness = newThickness.rounded(.up)
                    self.needsDisplay = true
                }
            }
        }
    }
    var lineIndices: [Int]? {
        get {
            if _lineIndices == nil {
                calculateLines()
            }
            return _lineIndices
        }
    }

    override var isOpaque: Bool { return false }

    var textView: NSTextView? { return clientView as? NSTextView }
    override var clientView: NSView? {
        willSet {
            let center = NotificationCenter.default
            if let oldView = clientView as? NSTextView, oldView != newValue {
                center.removeObserver(self, name: NSText.didChangeNotification, object: oldView)
                center.removeObserver(self, name: NSView.boundsDidChangeNotification, object: oldView)
            }

            center.addObserver(self, selector: #selector(RulerView.textDidChange(_:)), name: NSText.didChangeNotification, object: newValue)
            newValue?.postsFrameChangedNotifications = true
            center.addObserver(self, selector: #selector(RulerView.frameDidChange(_:)), name: NSView.frameDidChangeNotification, object: newValue)
            invalidateLineIndices()
        }
    }

    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation:orientation)
        clientView = scrollView?.documentView
        ruleThickness = Layout.minimumWidth
        needsDisplay = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func frameDidChange(_ notification: Notification) {
        needsDisplay = true
    }

    @objc
    func textDidChange(_ notification: Notification) {
        invalidateLineIndices()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        drawHashMarksAndLabels(in: dirtyRect)
    }

    func invalidateLineIndices() {
        _lineIndices = nil
    }

    func lineNumberForCharacterIndex(index: Int) -> Int {
        var left = 0, right = lineIndices!.count
        while right - left > 1 {
            let mid = (left + right) / 2
            let lineIndex = lineIndices![mid]
            if index < lineIndex {
                right = mid
            } else if index > lineIndex {
                left = mid
            } else {
                return mid + 1
            }
        }
        return left + 1
    }

    func calculateRulerWidth() -> CGFloat {
        let numberOfLines = lineIndices?.count ?? 0
        let numberOfDigits = Int(log10(Double(numberOfLines))) + 1
        let lineNumberWidth = (String(repeating: "8", count: numberOfDigits) as NSString).size(withAttributes: textAttributes()).width
        return max(Layout.leftPadding + lineNumberWidth + Layout.rightPadding, Layout.minimumWidth)
    }

    func calculateLines() {
        guard let textView = textView else { return }

        var lineIndices = [Int]()
        let text = textView.string as NSString
        let textLength = text.length
        var totalLines = 0
        var charIndex = 0
        repeat {
            lineIndices.append(charIndex)
            charIndex = text.lineRange(for: NSMakeRange(charIndex, 0)).upperBound
            totalLines += 1
        } while charIndex < textLength

        // Check for trailing return
        var lineEndIndex = 0, contentEndIndex = 0
        let lastObject = lineIndices[lineIndices.count - 1]
        text.getLineStart(nil, end: &lineEndIndex, contentsEnd: &contentEndIndex, for: NSMakeRange(lastObject, 0))
        if contentEndIndex < lineEndIndex {
            lineIndices.append(lineEndIndex)
        }

        _lineIndices = lineIndices
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView else { return }

        // Background
        let docRect = convert(clientView!.bounds, from: clientView)
        let y = docRect.origin.y
        let height = docRect.size.height
        let width = bounds.size.width
        NSColor(calibratedRed: 0.969, green: 0.969, blue: 0.969, alpha: 1).set()
        NSRect(x: 0, y: y, width: width, height: height).fill()

        // Seperator
        NSColor(calibratedRed: 0.902, green: 0.902, blue: 0.902, alpha: 1).set()
        var line = NSBezierPath()

        line = NSBezierPath()
        line.move(to: NSPoint(x: width - 0.5, y: y))
        line.line(to: NSPoint(x: width - 0.5, y: y + height))
        line.lineWidth = 1
        line.stroke()

        let layoutManager = textView.layoutManager
        let container = textView.textContainer
        let nullRange = NSRange(location: NSNotFound, length: 0)
        var lineRectCount = 0

        let textVisibleRect = scrollView!.contentView.bounds
        let rulerBounds = bounds
        let textInset = textView.textContainerInset.height

        let glyphRange = layoutManager!.glyphRange(forBoundingRect: textVisibleRect, in: container!)
        let charRange = layoutManager!.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let startChange = lineNumberForCharacterIndex(index: charRange.location)
        let endChange = lineNumberForCharacterIndex(index: charRange.upperBound)
        for lineNumber in startChange...endChange {
            let charIndex = lineIndices![lineNumber - 1]
            let lineRectsForRange = layoutManager!.rectArray(
                forCharacterRange: NSRange(location: charIndex, length: 0),
                withinSelectedCharacterRange: nullRange,
                in: container!,
                rectCount: &lineRectCount)
            if lineRectCount > 0 {
                let ypos = textInset + lineRectsForRange![0].minY - textVisibleRect.minY
                let labelText = NSString(format: "%ld", lineNumber)
                let labelSize = labelText.size(withAttributes: textAttributes())

                let lineNumberRect = NSRect(x: rulerBounds.width - labelSize.width - Layout.rightPadding,
                                            y: ypos + (lineRectsForRange![0].height - labelSize.height) / 2,
                                            width: rulerBounds.width - (Layout.leftPadding + Layout.rightPadding),
                                            height: lineRectsForRange![0].height)

                labelText.draw(in: lineNumberRect, withAttributes: textAttributes())
            }

            // We are past the visible range
            if charIndex > charRange.upperBound {
                break
            }
        }
    }

    func textAttributes() -> [NSAttributedStringKey: AnyObject] {
        return [
            NSAttributedStringKey.font: NSFont.labelFont(ofSize: NSFont.systemFontSize(for: .mini)),
            NSAttributedStringKey.foregroundColor: NSColor(calibratedWhite: 0.42, alpha: 1)
        ]
    }
}
