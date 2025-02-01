//
//  StreamParser.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/6/24.
//

import CoreData
import Foundation
import SwiftTAK
import SWXMLHash

class StreamParser: COTDataParser {
    
    static let STREAM_DELIMTER = "</event>"
    static let PB_MAGIC_BYTE: UInt8 = 0xbf
    var currentDataStream: Data = Data()
    
    func parse(dataStream: Data?) -> Array<String> {
        var events: [String] = []
        guard let data = dataStream else { return events }
        currentDataStream.append(data)
        var str = String(decoding: currentDataStream, as: UTF8.self)
        while str.contains(StreamParser.STREAM_DELIMTER) {
            let splitEvent = str.split(separator: StreamParser.STREAM_DELIMTER, maxSplits: 1)
            let cotEvent = splitEvent.first!
            var restOfString = ""
            if splitEvent.count > 1 {
                restOfString = String(splitEvent.last!)
            }
            events.append("\(cotEvent)\(StreamParser.STREAM_DELIMTER)")
            str = restOfString
        }
        currentDataStream = Data(str.utf8)
        return events
    }
    
    func parseCoTStream(dataStream: Data?) {
        guard let dataStream = dataStream else { return }

        let events = parse(dataStream: dataStream)
        for xmlEvent in events {
            guard let cotEvent = cotParser.parse(xmlEvent) else {
                continue
            }
            switch(cotEvent.eventType) {
            case .ATOM, .BIT:
                parseAtom(cotEvent: cotEvent, rawXml: xmlEvent)
            case .CUSTOM:
                parseCustom(cotEvent: cotEvent, rawXml: xmlEvent)
            default:
                TAKLogger.debug("[StreamParser] Non-Atom CoT Event received \(cotEvent.type)")
            }
            
        }
    }
}
