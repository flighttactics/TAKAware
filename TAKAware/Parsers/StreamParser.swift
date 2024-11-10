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

class StreamParser: NSObject {
    
    static let STREAM_DELIMTER = "</event>"
    var dataController = DataController.shared
    var cotParser: COTXMLParser = COTXMLParser()
    
    func parse(dataStream: Data?) -> Array<String> {
        guard let data = dataStream else { return [] }
        let str = String(decoding: data, as: UTF8.self)
        return str.components(separatedBy: StreamParser.STREAM_DELIMTER)
            .filter { !$0.isEmpty }
            .map { "\($0)\(StreamParser.STREAM_DELIMTER)" }
    }
    
    func parseAtom(cotEvent: COTEvent, rawXml: String) {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "cotUid = %@", cotEvent.uid as String)
        
        dataController.persistentContainer.performBackgroundTask { (dataContext) in
            dataContext.mergePolicy = NSMergePolicy.overwrite
            let results = try? dataContext.fetch(fetchUser)
            
            let mapPointData: COTData!
            
            if results?.count == 0 {
                mapPointData = COTData(context: dataContext)
                mapPointData.id = UUID()
                mapPointData.cotUid = cotEvent.uid
             } else {
                 mapPointData = results?.first
             }
            
            let cotVideoURL: URL? = URL(string: cotEvent.cotDetail?.cotVideo?.url ?? "")

            mapPointData.callsign = cotEvent.cotDetail?.cotContact?.callsign ?? "UNKNOWN"
            mapPointData.latitude = Double(cotEvent.cotPoint?.lat ?? "0.0") ?? 0.0
            mapPointData.longitude = Double(cotEvent.cotPoint?.lon ?? "0.0") ?? 0.0
            mapPointData.remarks = cotEvent.cotDetail?.cotRemarks?.message ?? ""
            mapPointData.cotType = cotEvent.type
            mapPointData.icon = cotEvent.cotDetail?.cotUserIcon?.iconsetPath ?? ""
            mapPointData.iconColor = cotEvent.cotDetail?.cotColor?.argb.description ?? ""
            mapPointData.startDate = cotEvent.start
            mapPointData.updateDate = cotEvent.time
            mapPointData.staleDate = cotEvent.stale
            mapPointData.archived = ((cotEvent.cotDetail?.childNodes.contains(where: { $0 is COTArchive })) != nil)
            mapPointData.rawXml = rawXml
            mapPointData.videoURL = cotVideoURL ?? nil

            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
        }
    }
    
    func parseBit(cotEvent: COTEvent, rawXml: String) {
        let fetchMarker: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchMarker.predicate = NSPredicate(format: "cotUid = %@", cotEvent.uid as String)
        
        dataController.persistentContainer.performBackgroundTask { (dataContext) in
            dataContext.mergePolicy = NSMergePolicy.overwrite
            let results = try? dataContext.fetch(fetchMarker)
            
            let mapPointData: COTData!
            
            if results?.count == 0 {
                mapPointData = COTData(context: dataContext)
                mapPointData.id = UUID()
                mapPointData.cotUid = cotEvent.uid
             } else {
                 mapPointData = results?.first
             }

            mapPointData.callsign = cotEvent.cotDetail?.cotContact?.callsign ?? "UNKNOWN"
            mapPointData.latitude = Double(cotEvent.cotPoint?.lat ?? "0.0") ?? 0.0
            mapPointData.longitude = Double(cotEvent.cotPoint?.lon ?? "0.0") ?? 0.0
            mapPointData.remarks = cotEvent.cotDetail?.cotRemarks?.message ?? ""
            mapPointData.cotType = cotEvent.type
            mapPointData.icon = cotEvent.cotDetail?.cotUserIcon?.iconsetPath ?? ""
            mapPointData.iconColor = cotEvent.cotDetail?.cotColor?.argb.description ?? ""
            mapPointData.startDate = cotEvent.start
            mapPointData.updateDate = cotEvent.time
            mapPointData.staleDate = cotEvent.stale
            mapPointData.archived = ((cotEvent.cotDetail?.childNodes.contains(where: { $0 is COTArchive })) != nil)
            mapPointData.rawXml = rawXml

            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
        }
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
