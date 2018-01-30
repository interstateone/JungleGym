//
//  Layout.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-12-10.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import AppKit

extension NSLayoutConstraint {
    func with(priority: NSLayoutConstraint.Priority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension NSView {
    func addSubview(_ subview: NSView, constraints: [NSLayoutConstraint]) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate(constraints)
    }
}
