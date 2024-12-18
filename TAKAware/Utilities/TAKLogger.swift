//
//  TAKLogger.debug.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/30/23.
//

import Foundation
import UIKit

class TAKLogger: NSObject {
    static func debug(_ message: String) {
        message.enumerateLines { (line, _) in
            NSLog(line)
        }
    }
    
    static func info(_ message: String) {
        NSLog(message)
    }
    
    static func error(_ message: String) {
        NSLog(message)
    }
}
