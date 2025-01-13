//
//  DataPackageManagerTests.swift
//  TAKAware
//
//  Created by Cory Foy on 1/10/25.
//

import Foundation
import SwiftTAK
import XCTest
import ZIPFoundation
import CoreData
@testable import TAKAware

final class DataPackageManagerTests: TAKAwareTestCase {
    func testParsesJSONResponseToDataPackages() {
        let packageManager = DataPackageManager()
        let jsonString = """
{
  "version": "3",
  "type": "Files",
  "data": [
    {
      "User": "takawareuser",
      "Keywords": "missionpackage",
      "Size": "4MB",
      "Groups": "TestGroup",
      "Expiration": "none",
      "Time": "2024-09-27 15:34:00.417",
      "Creator": "",
      "Hash": "f76dcb8105291b22f53b3705f79b02d727ec61f277ea4241875b21545ad6aa2a",
      "MimeType": "application/x-zip-compressed",
      "Name": "TestDP1.zip"
    }
    ]
}
"""
        packageManager.storeDataPackageResponse(Data(jsonString.utf8))
        XCTAssertEqual("TestDP1.zip", packageManager.dataPackages.first?.name)
    }
    
    func testOnlyIncludesLatestPackageWhenDuplicateNames() {
        let packageManager = DataPackageManager()
        let jsonString = """
{
  "version": "3",
  "type": "Files",
  "data": [
    {
      "User": "takawareuser",
      "Keywords": "missionpackage",
      "Size": "4MB",
      "Groups": "TestGroup",
      "Expiration": "none",
      "Time": "2024-09-27 15:34:00.417",
      "Creator": "",
      "Hash": "f76dcb8105291b22f53b3705f79b02d727ec61f277ea4241875b21545ad6aa2a",
      "MimeType": "application/x-zip-compressed",
      "Name": "TestDP1.zip"
    },
    {
      "User": "takawareuser",
      "Keywords": "missionpackage",
      "Size": "4MB",
      "Groups": "TestGroup",
      "Expiration": "none",
      "Time": "2024-10-02 12:34:00.417",
      "Creator": "",
      "Hash": "g85dcb8105293c98f53b3705f79b02d727ec72g277ea4241875b21545ad6bc7z",
      "MimeType": "application/x-zip-compressed",
      "Name": "TestDP1.zip"
    }
    ]
}
"""
        packageManager.storeDataPackageResponse(Data(jsonString.utf8))
        XCTAssertEqual(1, packageManager.dataPackages.count)
        XCTAssertEqual("g85dcb8105293c98f53b3705f79b02d727ec72g277ea4241875b21545ad6bc7z", packageManager.dataPackages.first?.hash)
    }
    
    func testOnlyIncludesLatestPackageWhenDuplicateNamesAndLatestComesFirst() {
        let packageManager = DataPackageManager()
        let jsonString = """
{
  "version": "3",
  "type": "Files",
  "data": [
    {
      "User": "takawareuser",
      "Keywords": "missionpackage",
      "Size": "4MB",
      "Groups": "TestGroup",
      "Expiration": "none",
      "Time": "2024-10-02 12:34:00.417",
      "Creator": "",
      "Hash": "g85dcb8105293c98f53b3705f79b02d727ec72g277ea4241875b21545ad6bc7z",
      "MimeType": "application/x-zip-compressed",
      "Name": "TestDP1.zip"
    },
    {
      "User": "takawareuser",
      "Keywords": "missionpackage",
      "Size": "4MB",
      "Groups": "TestGroup",
      "Expiration": "none",
      "Time": "2024-09-27 15:34:00.417",
      "Creator": "",
      "Hash": "f76dcb8105291b22f53b3705f79b02d727ec61f277ea4241875b21545ad6aa2a",
      "MimeType": "application/x-zip-compressed",
      "Name": "TestDP1.zip"
    }
    ]
}
"""
        packageManager.storeDataPackageResponse(Data(jsonString.utf8))
        XCTAssertEqual(1, packageManager.dataPackages.count)
        XCTAssertEqual("g85dcb8105293c98f53b3705f79b02d727ec72g277ea4241875b21545ad6bc7z", packageManager.dataPackages.first?.hash)
    }
}
