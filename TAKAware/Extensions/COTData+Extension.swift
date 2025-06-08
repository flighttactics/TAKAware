//
//  COTData+Extension.swift
//  TAKAware
//
//  Created by Cory Foy on 6/8/25.
//

import CoreData

extension COTData {
    @objc public var baseCotType: String? {
        get {
            switch(String((cotType ?? "a-U").prefix(3)).lowercased()) {
            case "a-f":
                "Friendly"
            case "a-h":
                "Hostile"
            case "a-n":
                "Neutral"
            default:
                "Unknown"
            }
        }
    }
}
