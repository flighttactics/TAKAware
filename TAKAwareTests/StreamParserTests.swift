//
//  StreamParserTests.swift
//  TAKTrackerTests
//
//  Created by Cory Foy on 7/6/24.
//

import Foundation
import XCTest
import SWXMLHash
import SwiftProtobuf
import SwiftTAK
@testable import TAKAware

final class StreamParserTests: TAKAwareTestCase {
    
    let event1 = "<?xml version=\"1.0\"><event uid=\"1\"></event>"
    let event2 = "<?xml version=\"1.0\"><event uid=\"2\"></event>"
    let parser = StreamParser()
    
    func testSplitOnEventClosureCreatesCorrectNumberOfEvents() {
        let eventStream = Data("\(event1)\(event2)".utf8)
        let events = parser.parseXml(dataStream: eventStream)
        TAKLogger.debug(String(describing: events))
        XCTAssertEqual(2, events.count, "Parser did not split properly")
    }
    
    func testSplitOnEventClosureIncludesClosureElement() {
        let eventStream = Data("\(event1)\(event2)".utf8)
        let events = parser.parseXml(dataStream: eventStream)
        XCTAssertEqual(event1, String(events[0]), "Parser split did not match event1")
        XCTAssertEqual(event2, String(events[1]), "Parser split did not match event2")
    }
    
    func testParsingWithSingleEventReturnsSingleNode() {
        let eventStream = Data("\(event1)".utf8)
        let events = parser.parseXml(dataStream: eventStream)
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
    
    func testParsesByBuildingFromMultipleStrings() throws {
        let eventPartial1 = Data("<?xml version=\"1.0\"><event uid=\"1\">".utf8)
        let eventPartial2 =  Data("</event><?xml version=\"1.0\"><event uid=".utf8)
        let eventPartial3 =  Data("\"2\"></event>".utf8)
        let initialEventsEmpty = parser.parseXml(dataStream: eventPartial1)
        XCTAssertEqual(0, initialEventsEmpty.count, "Parser parsed invalid XML")
        let firstEventCrossed = parser.parseXml(dataStream: eventPartial2)
        XCTAssertEqual(1, firstEventCrossed.count, "Parser missed first event")
        XCTAssertEqual(event1, String(firstEventCrossed[0]), "Parser split did not match event1")
        let secondEventCrossed = parser.parseXml(dataStream: eventPartial3)
        XCTAssertEqual(1, secondEventCrossed.count, "Parser missed second event")
        XCTAssertEqual(event2, String(secondEventCrossed[0]), "Parser split did not match event2")
    }
    
    func testParsesTaskMissionChangeEvent() throws {
        let xml = """
<event version="2.0" uid="62d88822-1426-40c6-b30d-e440f2c56daa" type="t-x-m-c" how="h-g-i-g-o" time="2024-07-28T17:48:03Z" start="2024-07-28T17:48:03Z" stale="2024-07-28T17:53:03Z"><point lat="0" lon="0" hae="0" ce="9999999" le="9999999"/><detail></detail></event>
"""
        let cotParser: COTXMLParser = COTXMLParser()
        let taskedEventXml = parser.parseXml(dataStream: Data(xml.utf8)).first
        XCTAssertNotNil(taskedEventXml)
        let taskedEvent = cotParser.parse(taskedEventXml!)
        XCTAssertEqual(taskedEvent?.eventType, .TASKING)
    }
    
//    func testUnknownBug() throws {
//        let cot = """
//<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
//<event version='2.0' uid='MXY292' type='a-f-A-C-F' how='m-g' time='2025-02-13T20:59:01Z' start='2025-02-13T20:59:01Z' stale='2025-02-13T21:09:01Z'><contact callsign='MXY292'/><point lat='33.3405647277832' lon='-79.75859832763672' hae='10972.933430870518' ce='9999999.0' le='9999999.0'/></event>
//"""
//        let cotData = Data(cot.utf8)
//        let unknownEvent = parser.parse(dataStream: cotData)
//        let cotParser = COTXMLParser()
//        print("    ")
//        print("************")
//        debugPrint(cotParser.parse(unknownEvent.first!))
//        print("************")
//        print("    ")
//        //parser.parseAtom(cotEvent: unknownEvent.first!, rawXml: cot)
//    }
    
    func testParsesProtobufMeshIntoEvents() throws {
        let cotUid = UUID().uuidString
        var pbTAKMessage = Atakmap_Commoncommo_Protobuf_V1_TakMessage()
        var pbTAKEvent = Atakmap_Commoncommo_Protobuf_V1_CotEvent()
        var dataMessage = Data()
        dataMessage.append(contentsOf: [StreamParser.PB_MAGIC_BYTE, 1, StreamParser.PB_MAGIC_BYTE]) // Mesh header
        pbTAKEvent.uid = cotUid
        pbTAKMessage.cotEvent = pbTAKEvent
        let pbMessageData = try pbTAKMessage.serializedData()
        dataMessage.append(pbMessageData)
        let events = parser.parseProtobuf(dataStream: dataMessage)
        XCTAssertEqual(1, events.count, "Parser did not handle protobuf properly")
        XCTAssertEqual(cotUid, events.first?.uid, "Event UID did not match expected")
    }
    
    func testParsesProtobufStreamIntoEvents() throws {
        let cotUid = UUID().uuidString
        var pbTAKMessage = Atakmap_Commoncommo_Protobuf_V1_TakMessage()
        var pbTAKEvent = Atakmap_Commoncommo_Protobuf_V1_CotEvent()
        var dataMessage = Data()
        dataMessage.append(contentsOf: [StreamParser.PB_MAGIC_BYTE, 1]) // Stream header
        pbTAKEvent.uid = cotUid
        pbTAKMessage.cotEvent = pbTAKEvent
        let pbMessageData = try pbTAKMessage.serializedData()
        dataMessage.append(pbMessageData)
        let events = parser.parseProtobuf(dataStream: dataMessage)
        XCTAssertEqual(1, events.count, "Parser did not handle protobuf properly")
        XCTAssertEqual(cotUid, events.first?.uid, "Event UID did not match expected")
    }
    
    func testParseFileDownload() throws {
        /*
         <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
         <event version=\"2.0\" uid=\"59f920ce-43c8-4e02-b9ef-a1639d4c96a1\" type=\"b-f-t-r\" how=\"h-e\" time=\"2025-06-04T21:45:20Z\" start=\"2025-06-04T21:45:20Z\" stale=\"2025-06-04T21:45:30Z\" access=\"Undefined\">
         <point lat=\"36.046997\" lon=\"-79.176799\" hae=\"174.4675914\" ce=\"9.9350462\" le=\"NaN\"/>
         <detail>
             <fileshare
                 filename=\"BingHybrid.xml.zip\"
                 senderUrl=\"https://137.118.181.203:8443/Marti/sync/content?hash=6f083c3b6b19aa8233ef8907b2eab241f96987f328c19c6193428d210659a1d2\"
                 sizeInBytes=\"938\"
                 sha256=\"6f083c3b6b19aa8233ef8907b2eab241f96987f328c19c6193428d210659a1d2\"
                 senderUid=\"ANDROID-07b42ddf9728082d\"
                 senderCallsign=\"USCP-HQ-UASMONITOR\"
                 name=\"BingHybrid.xml\"/>
             <ackrequest
                 uid=\"aedbfc35-a1a3-46dd-9759-45e2c88e7d4c\"
                 ackrequested=\"true\"
                 tag=\"BingHybrid.xml\"/>
             <_flow-tags_ TAK-Server-7e38d7c8805a4306bc5ab0a61ffec77d=\"2025-06-04T21:45:20Z\"/>
         </detail>
         </event>
         */
    }
}
