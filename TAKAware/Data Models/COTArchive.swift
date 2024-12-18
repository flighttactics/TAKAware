//
//  COTArchive.swift
//  TAKAware
//
//  Created by Cory Foy on 7/28/24.
//

import Foundation
import SwiftTAK

public struct COTArchive : COTNode, Equatable {
    
    public func toXml() -> String {
        return COTXMLHelper.generateXML(nodeName: "archive", attributes: [:], message: "")
    }
    
    public static func == (lhs: COTArchive, rhs: COTArchive) -> Bool {
        return true
    }
}
