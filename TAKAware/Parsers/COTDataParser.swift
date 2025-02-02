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
    
    func parseCustom(cotEvent: COTEvent, rawXml: String, forceArchive: Bool = false, dataPackageFile: DataPackageFile? = nil) {
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
            
            let cotShouldArchive = cotEvent.cotDetail?.childNodes.contains(where: { $0 is COTArchive }) ?? false

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
            mapPointData.archived = if(forceArchive) { true } else { cotShouldArchive }
            mapPointData.visible = true
            mapPointData.rawXml = rawXml
            mapPointData.videoURL = cotVideoURL ?? nil
            if dataPackageFile != nil {
                dataPackageFile?.cotData = mapPointData
            }

            do {
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
        }
    }
    
    func parseAtom(cotEvent: COTEvent, rawXml: String, forceArchive: Bool = false, dataPackageFile: DataPackageFile? = nil) {
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
            
            let cotShouldArchive = cotEvent.cotDetail?.childNodes.contains(where: { $0 is COTArchive }) ?? false
            let callsign = cotEvent.cotDetail?.cotContact?.callsign ?? "UNKNOWN"
            let phone = cotEvent.cotDetail?.cotContact?.phone
            let role = cotEvent.cotDetail?.cotGroup?.role
            let team = cotEvent.cotDetail?.cotGroup?.name

            mapPointData.callsign = callsign
            mapPointData.latitude = Double(cotEvent.cotPoint?.lat ?? "0.0") ?? 0.0
            mapPointData.longitude = Double(cotEvent.cotPoint?.lon ?? "0.0") ?? 0.0
            mapPointData.phone = phone
            mapPointData.team = team
            mapPointData.role = role
            mapPointData.remarks = cotEvent.cotDetail?.cotRemarks?.message ?? ""
            mapPointData.cotType = cotEvent.type
            mapPointData.icon = cotEvent.cotDetail?.cotUserIcon?.iconsetPath ?? ""
            mapPointData.iconColor = cotEvent.cotDetail?.cotColor?.argb.description ?? ""
            mapPointData.startDate = cotEvent.start
            mapPointData.updateDate = cotEvent.time
            mapPointData.staleDate = cotEvent.stale
            mapPointData.archived = if(forceArchive) { true } else { cotShouldArchive }
            mapPointData.visible = true
            mapPointData.rawXml = rawXml
            mapPointData.videoURL = cotVideoURL ?? nil
            
            if dataPackageFile != nil {
                dataPackageFile?.cotData = mapPointData
            }

            do {
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
            }
        }
    }
}
