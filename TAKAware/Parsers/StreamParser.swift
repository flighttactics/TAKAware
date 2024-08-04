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
    var dataContext = DataController.shared.cotDataContainer.newBackgroundContext()
    var cotParser: COTXMLParser = COTXMLParser()
    
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
            guard var cotEvent = cotParser.parse(xmlEvent) else {
                continue
            }
            
            let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
            fetchUser.predicate = NSPredicate(format: "cotUid = %@", cotEvent.uid as String)
            
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
            mapPointData.rawXml = xmlEvent
            mapPointData.videoURL = cotVideoURL ?? nil

            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
            
        }
    }
}
