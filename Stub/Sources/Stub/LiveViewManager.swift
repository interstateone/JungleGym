//
//  LiveViewManager.swift
//  JungleGymStub
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import UIKit

class LiveViewManager {
    var window: UIWindow? {
        didSet {
            guard window != oldValue else { return }

            if let window = window {
                window.makeKeyAndVisible()
                sendLiveViewAvailable()
            }
            else {
                sendLiveViewDismissed()
            }
        }
    }

    var viewController: UIViewController? {
        didSet {
            guard viewController != oldValue else { return }

            if let viewController = viewController {
                view = nil
                window = windowForPresentingLiveViewController(viewController)
            }
            else {
                window = nil
            }
        }
    }

    var view: UIView? {
        didSet {
            guard view != oldValue else { return }

            if let view = view {
                viewController = nil
                window = windowForPresentingLiveView(view)
            }
            else {
                window = nil
            }
        }
    }

    func sendLiveViewDismissed() {
        let properties: [String : Any] = ["date": Date(), "dismissed": true]
        /*let data*/ _ = try? PropertyListSerialization.data(fromPropertyList: properties, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions(bitPattern: 0))
        // DVTPlaygroundCommunicationSender.shared.send(data: data, identifier: "XCPLiveView", version: "XCPLiveView", completion: { error in })
    }

    func sendLiveViewAvailable() {
        guard
            let view = view ?? viewController?.view,
            let window = window
        else { return }

        let properties: [String : Any] = [
            "date": Date(),
            "width": view.bounds.width,
            "height": view.bounds.height,
            "windowX": window.frame.origin.x,
            "windowY": window.frame.origin.y,
            "screenScale": window.screen.scale
        ]
        /*let data*/ _ = try? PropertyListSerialization.data(fromPropertyList: properties, format: PropertyListSerialization.PropertyListFormat.binary, options: PropertyListSerialization.WriteOptions(bitPattern: 0))
        // DVTPlaygroundCommunicationSender.shared.send(data: data, identifier: "XCPLiveView", version: "XCPLiveView", completion: { error in })
    }

    func windowForPresentingLiveViewController(_ viewController: UIViewController) -> UIWindow {
        let window = windowForHostingLiveView()
        let size = viewController.preferredContentSize
        window.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        window.rootViewController = viewController
        return window
    }

    func windowForPresentingLiveView(_ view: UIView) -> UIWindow {
        let window = windowForHostingLiveView()
        window.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        window.addSubview(view)
        return window
    }

    func windowForHostingLiveView() -> UIWindow {
        let window = UIWindow()
        window.screen = UIScreen.main
        window.backgroundColor = .black
        window.isOpaque = true
        return window
    }
}
