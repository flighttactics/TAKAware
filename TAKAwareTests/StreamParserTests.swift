//
//  StreamParserTests.swift
//  TAKTrackerTests
//
//  Created by Cory Foy on 7/6/24.
//

import Foundation
import XCTest
import SWXMLHash
@testable import TAKAware

final class StreamParserTests: TAKAwareTestCase {
    
    let event1 = "<?xml version=\"1.0\"><event uid=\"1\"></event>"
    let event2 = "<?xml version=\"1.0\"><event uid=\"2\"></event>"
    let parser = StreamParser()
    
    func testSplitOnEventClosureCreatesCorrectNumberOfEvents() {
        let eventStream = Data("\(event1)\(event2)".utf8)
        let events = parser.parse(dataStream: eventStream)
        TAKLogger.debug(String(describing: events))
        XCTAssertEqual(2, events.count, "Parser did not split properly")
    }
    
    func testSplitOnEventClosureIncludesClosureElement() {
        let eventStream = Data("\(event1)\(event2)".utf8)
        let events = parser.parse(dataStream: eventStream)
        XCTAssertEqual(event1, String(events[0]), "Parser split did not match event1")
        XCTAssertEqual(event2, String(events[1]), "Parser split did not match event2")
    }
    
    func testParsingWithSingleEventReturnsSingleNode() {
        let eventStream = Data("\(event1)".utf8)
        let events = parser.parse(dataStream: eventStream)
        XCTAssertEqual(1, events.count, "Parser did not split properly")
        XCTAssertEqual(event1, String(events[0]), "Parser split did not match event1")
    }
    
    func testParsingStreamWithArchiveElement() throws {
        let xml = """
<event version="2.0" uid="9d98e8b2-aa5a-4a3b-8bac-be90085a6e10" type="a-u-A" how="h-g-i-g-o" time="2024-07-28T17:48:03Z" start="2024-07-28T17:48:03Z" stale="2024-07-28T17:53:03Z" access="Undefined"><point lat="36.0889256" lon="-79.1702288" hae="168.559" ce="9999999.0" le="9999999.0"/><detail><contact callsign="Local Airport"/><status readiness="true"/><archive/><usericon iconsetpath="f7f71666-8b28-4b57-9fbb-e38e61d33b79/Google/airports.png"/><link uid="ANDROID-07b42ddf9728082d" production_time="2024-07-28T14:37:48.934Z" type="a-f-G-U-C" parent_callsign="ORG-SORS-CFOY-S24" relation="p-p"/><precisionlocation altsrc="DTED0"/><remarks/><color argb="-1"/><archive/><_flow-tags_ TAK-Server-7e38d7c8805a4306bc5ab0a61ffec77d="2024-07-28T17:48:03Z"/></detail></event>
"""
        let parsed = XMLHash.parse(xml)
        XCTAssertFalse(parsed["event"]["detail"]["archive"].description.isEmpty)
        XCTAssertTrue(parsed["event"]["detail"]["blahblah"].description.isEmpty)
    }
}
