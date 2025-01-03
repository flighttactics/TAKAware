//
//  TAKTrackerTestCase.swift
//  TAKTrackerTests
//
//  Created by Cory Foy on 10/10/23.
//

import CoreData
import Foundation
import XCTest
@testable import TAKAware

class TAKAwareTestCase : XCTestCase {
    override class func setUp() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }
}

class TAKAwareDataTestCase : TAKAwareTestCase {
    override class func tearDown() {
        TAKLogger.debug("***Clearing All Data")
        Task {
            await DataController.shared.clearAll()
        }
        TAKLogger.debug("***Clearing All Data Complete")
    }
}
