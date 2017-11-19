//
//  AppDelegate.swift
//  JungleGymStub
//
//  Created by Brandon Evans on 2017-11-16.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Darwin
import Foundation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let liveViewManager = LiveViewManager()
    var needsIndefiniteExecution = false

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // This is temporary so that the app doesn't crash
        // Once the debugger is set up to evaluate the playground expression, the live view manager will have installed a window before this method returns
        window = UIWindow()
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()

        application.isStatusBarHidden = true

        registerForPlaygroundSupportNotifications()
        enqueueRunLoopBlock()

        return true
    }

    @objc
    func finishExecutionNotification(_ notification: Notification) {
        // Communicate back to the host over a socket
        // DVTPlaygroundCommunicationSender.shared.send(data: nil, identifier: "DVTPlaygroundShouldFinishExecution", version: 1, completionBlock: { error in })
    }

    @objc
    func liveViewDidChangeNotification(_ notification: Notification) {
        if let newLiveView = notification.userInfo?["PlaygroundPageLiveView"] as? UIView {
            liveViewManager.viewController = nil
            liveViewManager.view = newLiveView
        }
        else if let newLiveViewController = notification.userInfo?["PlaygroundPageLiveViewController"] as? UIViewController {
            liveViewManager.view = nil
            liveViewManager.viewController = newLiveViewController
        }
        else {
            liveViewManager.view = nil
            liveViewManager.viewController = nil
        }
    }

    @objc
    func needsIndefiniteExecutionChangedNotification(_ notification: Notification) {
        if let needsIndefiniteExecution = notification.userInfo?["PlaygroundPageNeedsIndefiniteExecution"] as? Bool {
            self.needsIndefiniteExecution = needsIndefiniteExecution
        }
    }

    func registerForPlaygroundSupportNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(needsIndefiniteExecutionChangedNotification(_:)), name: .needsIndefiniteExecutionDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(liveViewDidChangeNotification(_:)), name: .liveViewDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishExecutionNotification(_:)), name: .finishExecution, object: nil)
    }

    func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    func finishExecution() {
        unregisterNotifications()
        _playgroundExecutionWillFinish()
        // DVTFinishPlaygroundCommunication()
        exit(0)
    }

    func enqueueRunLoopBlock() {
        let runLoop = CFRunLoopGetCurrent()
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.commonModes.rawValue) {
            self._executePlayground()
            fflush(stdout)
            fflush(stderr)
            // DVTExecutePlaygroundDidFinish()
            if !self.needsIndefiniteExecution {
                self.finishExecution()
            }
        }
    }

    // Deliberate no-ops, these are used only as symbols for breakpoints
    @inline(never)
    func _executePlayground() {}
    @inline(never)
    func _playgroundExecutionWillFinish() {}
}

extension Notification.Name {
    static let needsIndefiniteExecutionDidChange = Notification.Name(rawValue: "PlaygroundPageNeedsIndefiniteExecutionDidChangeNotification")
    static let liveViewDidChange = Notification.Name(rawValue: "PlaygroundPageLiveViewDidChangeNotification")
    static let finishExecution = Notification.Name(rawValue: "PlaygroundPageFinishExecutionNotification")
}
