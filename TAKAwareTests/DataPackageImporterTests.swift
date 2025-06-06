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

final class DataPackageImporterTests: TAKAwareDataTestCase {
    var parser:TAKDataPackageImporter!
    var archiveURL:URL? = nil

    override func setUpWithError() throws {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.COT_DATA_PACKAGE_NAME, withExtension: "zip")
        parser = TAKDataPackageImporter.init(fileLocation: archiveURL!)
    }
    
    func testRecognizesSubfolder() {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.COT_DATA_PACKAGE_SUBFOLDER_NAME, withExtension: "zip")
        parser = TAKDataPackageImporter.init(fileLocation: archiveURL!)
        parser.parse()
        XCTAssertEqual("datapackage", parser.parser?.packageContents.rootFolder)
    }
    
    func testCreatesDatabaseEntryForThisPackageFromSubfolder() {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.COT_DATA_PACKAGE_SUBFOLDER_NAME, withExtension: "zip")
        parser = TAKDataPackageImporter.init(fileLocation: archiveURL!)
        let uid = "sf772639-f6f2-4bcc-88b5-1d841d91cd14"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchCoT: NSFetchRequest<DataPackage> = DataPackage.fetchRequest()
            fetchCoT.predicate = NSPredicate(format: "dataPackageUid = %@", uid)
            let results = try? context.fetch(fetchCoT)
            XCTAssertNotNil(results?.first)
        }
    }
    
    func testLoadsCoTMarkersRawXmlFromSubfolder() throws {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.COT_DATA_PACKAGE_SUBFOLDER_NAME, withExtension: "zip")
        parser = TAKDataPackageImporter.init(fileLocation: archiveURL!)
        let uid = "04ab9212-2e6d-499e-9ef3-98572954d5ea"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchCoT: NSFetchRequest<COTData> = COTData.fetchRequest()
            fetchCoT.predicate = NSPredicate(format: "cotUid = %@", uid)
            let results = try? context.fetch(fetchCoT)
            XCTAssertNotNil(results?.first)
            XCTAssertTrue(results?.first?.rawXml != nil)
        }
    }
    
    func testImportsCoTMarkersToMap() throws {
        let expectation = XCTestExpectation(description: "Parse package async")
        let uid = "5a5185fe-eb27-4b11-99ae-df04d54db10f"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchCoT: NSFetchRequest<COTData> = COTData.fetchRequest()
            //fetchCoT.predicate = NSPredicate(format: "cotUid = %@", uid)
            let results = try? context.fetch(fetchCoT)
            XCTAssertNotNil(results?.first)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCreatesDatabaseEntryForThisPackage() {
        let uid = "dc772639-f6f2-4bcc-88b5-1d841d91cd14"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchCoT: NSFetchRequest<DataPackage> = DataPackage.fetchRequest()
            fetchCoT.predicate = NSPredicate(format: "dataPackageUid = %@", uid)
            let results = try? context.fetch(fetchCoT)
            XCTAssertNotNil(results?.first)
        }
    }
    
    func testImportKmlFileStoresAndImports() {
        let kmlFileName = "blue-course.kml"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
            fetchKml.predicate = NSPredicate(format: "fileName = %@", kmlFileName)
            let results = try? context.fetch(fetchKml)
            XCTAssertNotNil(results?.first)
        }
    }
    
    func testImportKmlFileStoresADataPackageFile() async {
        await DataController.shared.clearAll()
        let kmlFileName = "blue-course.kml"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchDPFile: NSFetchRequest<DataPackageFile> = DataPackageFile.fetchRequest()
            fetchDPFile.predicate = NSPredicate(format: "name = %@", kmlFileName)
            let results = try? context.fetch(fetchDPFile)
            XCTAssertNotNil(results?.first)
        }
    }
    
    func testImportKmlFileDoesNotStoreAsCoT() async throws {
        await DataController.shared.clearAll()
        let kmlFileName = "blue-course.kml"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchDPFile: NSFetchRequest<DataPackageFile> = DataPackageFile.fetchRequest()
            fetchDPFile.predicate = NSPredicate(format: "name = %@", kmlFileName)
            let results = try? context.fetch(fetchDPFile)
            let actual = results?.first
            if actual != nil {
                XCTAssertFalse(actual!.isCoT)
            } else {
                XCTFail("No Records Found")
            }
        }
    }
    
    func testImportKmzFileStoresAndImports() {
        let kmzFileName = "startmap.kmz"
        let context = DataController.shared.backgroundContext
        parser.parse()
        context.performAndWait {
            let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
            fetchKml.predicate = NSPredicate(format: "fileName = %@", kmzFileName)
            let results = try? context.fetch(fetchKml)
            XCTAssertNotNil(results?.first)
        }
    }
}
