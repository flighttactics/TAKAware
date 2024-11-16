//
//  COTDataParser.swift
//  TAKAware
//
//  Created by Cory Foy on 11/14/24.
//

import CoreData
import Foundation
import SwiftTAK
import SWXMLHash

class COTDataParser: NSObject {
    var dataContext = DataController.shared.backgroundContext
    var cotParser: COTXMLParser = COTXMLParser()
    
    func parseAtom(cotEvent: COTEvent, rawXml: String) {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "cotUid = %@", cotEvent.uid as String)

        dataContext.perform {
            let results = try? self.dataContext.fetch(fetchUser)
            
            let mapPointData: COTData!

            if results?.count == 0 {
                mapPointData = COTData(context: self.dataContext)
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
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
        }
    }
}
