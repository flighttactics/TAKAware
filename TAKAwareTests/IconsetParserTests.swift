//
//  IconsetManagerTests.swift
//  TAKAware
//
//  Created by Cory Foy on 2/4/25.
//

import CoreData
import Foundation
import SQLite
import XCTest
@testable import TAKAware

final class IconsetParserTests: TAKAwareTestCase {
    let ICONSET_UID = "12a34567-1a23-1234-1abc-a1b2cdefg345"
    let iconsetZipFilename = "iconset-import-test"
    var iconsetZipUrl: URL!
    
    let ICONSET_XML = """
<iconset name="iconset-import-test" uid="12a34567-1a23-1234-1abc-a1b2cdefg345" skipResize="false" version="8">
    <iconset name="arrow_1.png" type2525b="a-u-G"/>
</iconset>
"""
    
    override func setUpWithError() throws {
        let bundle = Bundle(for: Self.self)
        guard let iconsetZipUrl = bundle.url(forResource: iconsetZipFilename, withExtension: "zip") else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open iconset test zip"])
        }
        self.iconsetZipUrl = iconsetZipUrl
    }
    
    override func tearDown() {
        TAKLogger.debug("***Clearing All Data")
        Task {
            IconDataController.shared.clearAll()
        }
        TAKLogger.debug("***Clearing All Data Complete")
    }
    
    // TODO: Copy SQLIte into LocalIconSet on startup
    func testParsingIconsetStoresIconset() async throws {
        let context = IconDataController.shared.backgroundContext
        let importer = IconsetImporter(iconsetPackage: iconsetZipUrl)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        context.performAndWait {
            let fetchIconset: NSFetchRequest<LocalIconSet> = LocalIconSet.fetchRequest()
            fetchIconset.predicate = NSPredicate(format: "name = %@", "iconset-import-test")
            let results = try? context.fetch(fetchIconset)
            let actual = results?.first
            XCTAssertNotNil(actual)
        }
    }
    
    func testParsingIconsetStoresIcons() async throws {
        let context = IconDataController.shared.backgroundContext
        let importer = IconsetImporter(iconsetPackage: iconsetZipUrl)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        context.performAndWait {
            let fetchIcon: NSFetchRequest<LocalIcon> = LocalIcon.fetchRequest()
            fetchIcon.predicate = NSPredicate(format: "iconset_uid = %@", ICONSET_UID)
            let results = try? context.fetch(fetchIcon)
            XCTAssertEqual(results?.count, 5)
        }
    }
    
    func testParsingAlreadyStoredIconsetFails() async throws {
        let importer1 = IconsetImporter(iconsetPackage: iconsetZipUrl)
        let processResult1 = await importer1.process()
        XCTAssertTrue(processResult1)
        
        let importer2 = IconsetImporter(iconsetPackage: iconsetZipUrl)
        let processResult2 = await importer2.process()
        XCTAssertFalse(processResult2)
    }
    
    func testImportingIconsetMakesAvailableToIconData() async throws {
        let defaultUnknownImg = UIImage(named: "sugp-----------")!
        let iconsetPath = "12a34567-1a23-1234-1abc-a1b2cdefg345/iconset-import-test/arrow_1.png"
        
        let importer = IconsetImporter(iconsetPackage: iconsetZipUrl)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        
        let actual = await IconData.iconFor(type2525: "a-u-G", iconsetPath: iconsetPath)
        XCTAssertNotEqual(defaultUnknownImg.pngData(), actual.icon.pngData())
    }
}
