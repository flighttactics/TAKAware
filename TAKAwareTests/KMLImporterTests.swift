//
//  KMLImporterTests.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import CoreData
import Foundation
import SwiftTAK
import XCTest
@testable import TAKAware

final class KMLImporterTests: TAKAwareTestCase {
    var importer: KMLImporter!
    var lineStringURL: URL!
    var pointURL: URL!
    var polygonURL: URL!
    var linearRingURL: URL!
    
    let LINE_STRING = "KMLLineString"
    let POINT = "KMLPoint"
    let POLYGON = "KMLPolygon"
    let LINEAR_RING = "KMLLinearRing"
    
    override func setUpWithError() throws {
        let bundle = Bundle(for: Self.self)
        guard let lineStringURL = bundle.url(forResource: LINE_STRING, withExtension: "kml") else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open line string KML"])
        }
        self.lineStringURL = lineStringURL
        
        guard let pointURL = bundle.url(forResource: POINT, withExtension: "kml") else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open point KML"])
        }
        self.pointURL = pointURL
        
        guard let polygonURL = bundle.url(forResource: POLYGON, withExtension: "kml") else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open polygon KML"])
        }
        self.polygonURL = polygonURL
        
        guard let linearRingURL = bundle.url(forResource: LINEAR_RING, withExtension: "kml") else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open linear ring KML"])
        }
        self.linearRingURL = linearRingURL
    }
    
    func testCreatesDatabaseEntryForThisFile() async {
        let context = DataController.shared.backgroundContext
        importer = KMLImporter(archiveLocation: pointURL)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        context.performAndWait {
            let fetchCoT: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
            fetchCoT.predicate = NSPredicate(format: "filePath = %@", importer.savedLocation! as NSURL)
            let results = try? context.fetch(fetchCoT)
            let actual = results?.first
            XCTAssertNotNil(actual)
        }
    }
    
    func testImportPointKML() async throws {
        importer = KMLImporter(archiveLocation: pointURL)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        XCTAssertEqual(importer.kmlParser.placemarks.count, 1)
    }
    
    func testImportLineStringKML() async throws {
        importer = KMLImporter(archiveLocation: lineStringURL)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        XCTAssertEqual(importer.kmlParser.placemarks.count, 1)
    }
    
    func testImportPolygonKML() async throws {
        importer = KMLImporter(archiveLocation: polygonURL)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        XCTAssertEqual(importer.kmlParser.placemarks.count, 1)
    }
    
    func testImportLinearRingKML() async throws {
        importer = KMLImporter(archiveLocation: linearRingURL)
        let processResult = await importer.process()
        XCTAssertTrue(processResult)
        XCTAssertEqual(importer.kmlParser.placemarks.count, 1)
    }
}
