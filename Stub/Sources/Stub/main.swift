//
//  main.swift
//  JungleGymStub
//
//  Created by Brandon Evans on 2017-11-19.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import UIKit

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)  
        .bindMemory(  
            to: UnsafeMutablePointer<Int8>.self,  
            capacity: Int(CommandLine.argc)
        ),
    nil,
    NSStringFromClass(AppDelegate.self)
)

