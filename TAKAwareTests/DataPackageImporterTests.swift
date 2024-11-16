//
//  DataPackageImporterTests.swift
//  TAKAware
//
//  Created by Cory Foy on 11/14/24.
//

import Foundation
import SwiftTAK
import XCTest
import ZIPFoundation
import CoreData
@testable import TAKAware

final class DataPackageImporterTests: TAKAwareTestCase {
    var parser:TAKDataPackageImporter? = nil
    var archiveURL:URL? = nil

    override func setUpWithError() throws {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.COT_DATA_PACKAGE_NAME, withExtension: "zip")
        parser = TAKDataPackageImporter.init(fileLocation: archiveURL!)
    }
    
    func testImportsCoTMarkersToMap() throws {
        let uid = "5a5185fe-eb27-4b11-99ae-df04d54db10f"
        let context = DataController.shared.backgroundContext
        parser!.parse()
        context.performAndWait {
            let fetchCoT: NSFetchRequest<COTData> = COTData.fetchRequest()
            fetchCoT.predicate = NSPredicate(format: "cotUid = %@", uid)
            let results = try? context.fetch(fetchCoT)
            XCTAssertNotNil(results?.first)
        }
    }
    
    func testTagsImportedMarkersAsBeingWithThisDataPackage() {
        
    }
}
