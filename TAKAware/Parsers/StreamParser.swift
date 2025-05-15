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
    static let PB_MAGIC_BYTE: UInt8 = 0xbf // 191
    static let MAGIC_BYTE_HEADER_POSITION = 0
    static let PB_MSG_LENGTH_HEADER_POSITION = 1
    static let MAGIC_BYTE_OR_MSG_HEADER_POSITION = 2
    static let MESH_MSG_HEADER_POSITION = 3
    var currentDataStream: Data = Data()
    
    func parseProtobuf(dataStream: Data) -> Array<COTEvent> {
        // Flow is either [MAGIC_BYTE, 1, MAGIC_BYTE, message]
        // or [MAGIC_BYTE, varint, message]
        // let messageLength = dataStream[StreamParser.PB_MSG_LENGTH_HEADER_POSITION]
        
        if dataStream.count < 3 {
            TAKLogger.error("[StreamParser] Attempted to process protobuf with less than 3 bytes")
            return []
        }
        
        var pbMsg = dataStream.dropFirst(2) // Skip the magic byte and the message length
        
        // TODO: Validate against the message length rather than rely on the mesh logic here
        if pbMsg.first == StreamParser.PB_MAGIC_BYTE {
            pbMsg = pbMsg.dropFirst()
        }

        do {
            let decodedInfo = try Atakmap_Commoncommo_Protobuf_V1_TakMessage(serializedBytes: pbMsg)
            return [TAKProtoToSwiftTAKConverter(protobufMessage: decodedInfo).convertToSwiftTAK()]
        } catch {
            TAKLogger.error("[StreamParser] Unable to parse Protobuf \(error)")
            return []
        }
    }
    
    func parseXml(dataStream: Data?) -> Array<String> {
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
    
    func processProtobuf(dataStream: Data, forceArchive: Bool = false) {
        let events = parseProtobuf(dataStream: dataStream)
        for cotEvent in events {
            switch(cotEvent.eventType) {
            case .ATOM, .BIT:
                parseAtom(cotEvent: cotEvent, rawXml: "", forceArchive: forceArchive)
            case .CUSTOM:
                parseCustom(cotEvent: cotEvent, rawXml: "")
            case .TASKING:
                parseTask(cotEvent: cotEvent, rawXml: "")
            default:
                TAKLogger.debug("[StreamParser] Unknown CoT Event received \(cotEvent.type)")
            }
        }
    }
    
    func processXml(dataStream: Data, forceArchive: Bool = false) {
        let events = parseXml(dataStream: dataStream)
        for xmlEvent in events {
            guard let cotEvent = cotParser.parse(xmlEvent) else {
                continue
            }
            switch(cotEvent.eventType) {
            case .ATOM, .BIT:
                parseAtom(cotEvent: cotEvent, rawXml: xmlEvent, forceArchive: forceArchive)
            case .CUSTOM:
                parseCustom(cotEvent: cotEvent, rawXml: xmlEvent)
            case .TASKING:
                parseTask(cotEvent: cotEvent, rawXml: xmlEvent)
            default:
                TAKLogger.debug("[StreamParser] Unknown CoT Event received \(cotEvent.type)")
            }
        }
    }
    
    func parseCoTStream(dataStream: Data?, forceArchive: Bool = false) {
        guard let dataStream = dataStream else { return }
        if dataStream.first == StreamParser.PB_MAGIC_BYTE {
            processProtobuf(dataStream: dataStream, forceArchive: forceArchive)
        } else {
            processXml(dataStream: dataStream, forceArchive: forceArchive)
        }
    }
}
