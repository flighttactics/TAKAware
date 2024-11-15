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
    
    func parse(dataStream: Data?) -> Array<String> {
        guard let data = dataStream else { return [] }
        let str = String(decoding: data, as: UTF8.self)
        return str.components(separatedBy: StreamParser.STREAM_DELIMTER)
            .filter { !$0.isEmpty }
            .map { "\($0)\(StreamParser.STREAM_DELIMTER)" }
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
            default:
                TAKLogger.debug("[StreamParser] Non-Atom CoT Event received \(cotEvent.type)")
            }
            
        }
    }
}
