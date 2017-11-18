//
//  Process.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-18.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation

public extension Process {
    func launchAndPrintStandardOutputAndError() {
        let outputPipe = Pipe()
        standardOutput = outputPipe
        let outputHandle = outputPipe.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify()

        let errorPipe = Pipe()
        standardError = errorPipe
        let errorHandle = errorPipe.fileHandleForReading
        errorHandle.waitForDataInBackgroundAndNotify()

        var outputObserver: NSObjectProtocol!
        outputObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputHandle, queue: nil) { notification in
            let data = outputHandle.availableData

            if !data.isEmpty {
                if let string = String(data: data, encoding: .utf8) {
                    print("STDOUT: " + string)
                }
                outputHandle.waitForDataInBackgroundAndNotify()
            }
            else {
                NotificationCenter.default.removeObserver(outputObserver)
            }
        }

        var errorObserver: NSObjectProtocol!
        errorObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorHandle, queue: nil) { notification in
            let data = errorHandle.availableData

            if !data.isEmpty {
                if let string = String(data: data, encoding: .utf8) {
                    print("STDERR: " + string)
                }
                errorHandle.waitForDataInBackgroundAndNotify()
            }
            else {
                NotificationCenter.default.removeObserver(errorObserver)
            }
        }

        launch()
    }
}
