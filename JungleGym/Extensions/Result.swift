//
//  Result.swift
//  JungleGym
//
//  Created by Brandon Evans on 2017-11-28.
//  Copyright © 2017 Brandon Evans. All rights reserved.
//

import Foundation
import Result

extension Result {
    /// Useful for bouncing a Result back to queue A after performing work on queue B
    func perform(_ f: ((Result<Value, Error>) -> Void)?, on queue: DispatchQueue) {
        queue.async { f?(self) }
    }
}
