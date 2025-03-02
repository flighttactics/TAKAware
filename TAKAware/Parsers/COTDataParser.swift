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
    
    func downloadMissionContent(missionGuid: String, fileHash: String) {
        TAKLogger.debug("[COTDataParser] downloadMissionContent not yet implemented")
    }
    
    func removeMissionContent(missionGuid: String, fileHash: String) {
        TAKLogger.debug("[COTDataParser] removeMissionContent not yet implemented")
    }
    
    func parseMissionXml(rawXml: String) {
        let cot = XMLHash.parse(rawXml)
        let missionNode = cot["event"]["detail"]["mission"]
        if missionNode.element != nil {
            let missionName = missionNode.element!.allAttributes["name"]?.text ?? "UNKNOWN MISSION"
            let missionGuid = missionNode.element!.allAttributes["guid"]?.text ?? UUID().uuidString
            let missionChangesNode = missionNode["MissionChanges"]
            
            if missionChangesNode.element != nil {
                missionChangesNode["MissionChange"].all.forEach { missionChange in
                    let contentUidNode = missionChange["contentUid"]
                    let contentHashNode = missionChange["contentHash"]
                    // CREATE_MISSION, DELETE_MISSION, ADD_CONTENT, REMOVE_CONTENT, CREATE_DATA_FEED, DELETE_DATA_FEED
                    let addType = missionChange["type"].element?.text ?? "ADD_CONTENT"
                    if addType == "ADD_CONTENT" {
                        /*
                         <MissionChange><contentUid>A4F2E606-A1AF-4FA3-AB97-211DA9DEF357</contentUid><creatorUid>F8C5D325-7B71-48E1-B148-F00E62387BEC</creatorUid><isFederatedChange>false</isFederatedChange><missionName>FT-Test4</missionName><timestamp>2025-02-28T03:41:24.579Z</timestamp><type>ADD_CONTENT</type><details type="a-u-G" callsign="CP-HQ-Foy-iTAK.27.224010" iconsetPath="COT_MAPPING_2525B/a-u/a-u-G" color="-1"><location lat="36.04872578747775" lon="-79.17847949231503"/></details></MissionChange>
                         */
                        if contentUidNode.element != nil {
                            let cotDetailsNode = missionChange["details"]
                            if let cotDetailsElement = cotDetailsNode.element {
                                let cotType = cotDetailsElement.value(ofAttribute: "type") ?? "a-u-G"
                                let cotCallsign = cotDetailsElement.value(ofAttribute: "callsign") ?? "UNKNOWN"
                                let cotIconsetPath = cotDetailsElement.value(ofAttribute: "iconsetPath") ?? ""
                                let cotColor = cotDetailsElement.value(ofAttribute: "color") ?? "-1"
                                var lat = "0.0"
                                var lon = "0.0"
                                if let locationNode = cotDetailsNode["location"].element {
                                    lat = locationNode.value(ofAttribute: "lat") ?? "0.0"
                                    lon = locationNode.value(ofAttribute: "lon") ?? "0.0"
                                }
                                // TODO: Link to the Data Sync mission, fool!
                                dataContext.perform {
                                    
                                    let fetchMission: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
                                    fetchMission.predicate = NSPredicate(format: "name = %@", missionName)
                                    let missionResults = try? self.dataContext.fetch(fetchMission)
                                    
                                    if let storedMission = missionResults?.first {
                                        let cotData = COTData(context: self.dataContext)
                                        cotData.id = UUID()
                                        cotData.cotType = cotType
                                        cotData.callsign = cotCallsign
                                        cotData.icon = cotIconsetPath
                                        cotData.iconColor = cotColor
                                        cotData.cotUid = contentUidNode.element?.text ?? UUID().uuidString
                                        cotData.latitude = Double(lat) ?? 0.0
                                        cotData.longitude = Double(lon) ?? 0.0
                                        
                                        let dsMissionItem = DataSyncMissionItem(context: self.dataContext)
                                        dsMissionItem.id = UUID()
                                        dsMissionItem.cotUid = cotData.id
                                        dsMissionItem.uid = contentUidNode.element!.text
                                        dsMissionItem.missionUUID = storedMission.id
                                        dsMissionItem.isCOT = true
                                        
                                        do {
                                            try self.dataContext.save()
                                        } catch {
                                            TAKLogger.error("[COTDataParser] Invalid Data Context Save \(error)")
                                        }
                                    }
                                }
                            } else {
                                TAKLogger.debug("[COTDataParser] Found a contentUid node without details. Skipping.")
                            }
                        } else if contentHashNode.element != nil {
                            downloadMissionContent(missionGuid: missionGuid, fileHash: contentHashNode.element!.text)
                        } else {
                            // Is this a contentResource?
                            /*
                             <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<event how=\"h-g-i-g-o\" type=\"t-x-m-c\" version=\"2.0\" uid=\"dbb0f332-9eca-40c2-b98e-f5ffed1eac26\" start=\"2025-03-01T03:34:07Z\" time=\"2025-03-01T03:34:07Z\" stale=\"2025-03-01T03:34:27Z\"><point ce=\"9999999\" le=\"9999999\" hae=\"0\" lat=\"0\" lon=\"0\"/><detail><mission type=\"CHANGE\" tool=\"public\" name=\"FT-Test4\" guid=\"606acd50-4dc5-46e9-86ba-6f64e14f3796\" authorUid=\"F8C5D325-7B71-48E1-B148-F00E62387BEC\"><MissionChanges><MissionChange><contentResource><creatorUid>F8C5D325-7B71-48E1-B148-F00E62387BEC</creatorUid><expiration>-1</expiration><groupVector>000</groupVector><hash>2be3118b8c1e71b719b2372513010271f27634b8dbc59f6581b58f742b5c1ee9</hash><mimeType>application/octet-stream</mimeType><name>20250301_033326.jpeg</name><size>4625737</size><submissionTime>2025-03-01T03:34:06.706Z</submissionTime><submitter>cory.foy.iphone</submitter><uid>37F38D33-E6E6-C8E6-9045-1027181C8AED</uid></contentResource><creatorUid>F8C5D325-7B71-48E1-B148-F00E62387BEC</creatorUid><isFederatedChange>false</isFederatedChange><missionName>FT-Test4</missionName><timestamp>2025-03-01T03:34:07.309Z</timestamp><type>ADD_CONTENT</type></MissionChange>
                             */
                            TAKLogger.debug("[COTDataParser] Neither UID nor Hash present. Skipping.")
                        }
                    } else if addType == "REMOVE_CONTENT" {
                        /*
                         <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<event how=\"h-g-i-g-o\" type=\"t-x-m-c\" version=\"2.0\" uid=\"0aa18f7a-d819-4b41-8a70-9b7161269f3a\" start=\"2025-03-01T03:32:19Z\" time=\"2025-03-01T03:32:19Z\" stale=\"2025-03-01T03:32:39Z\"><point ce=\"9999999\" le=\"9999999\" hae=\"0\" lat=\"0\" lon=\"0\"/><detail><mission type=\"CHANGE\" tool=\"public\" name=\"FT-Test4\" guid=\"606acd50-4dc5-46e9-86ba-6f64e14f3796\" authorUid=\"F8C5D325-7B71-48E1-B148-F00E62387BEC\"><MissionChanges><MissionChange><contentUid>0686809D-7376-4C55-AE50-A7C260528F5B</contentUid><creatorUid>F8C5D325-7B71-48E1-B148-F00E62387BEC</creatorUid><isFederatedChange>false</isFederatedChange><missionName>FT-Test4</missionName><timestamp>2025-03-01T03:32:19.490Z</timestamp><type>REMOVE_CONTENT</type><details type=\"a-h-A\" callsign=\"test hostile house\" iconsetPath=\"COT_MAPPING_2525B/a-h/a-h-A\" color=\"-1\"><location lat=\"36.04925419158478\" lon=\"-79.1764794146616\"/></details></MissionChange></MissionChanges></mission></detail></event>
                         */
                        if contentUidNode.element != nil {
                            let cotDetailsNode = missionChange["details"]
                            if cotDetailsNode.element != nil {
                                dataContext.perform {
                                    let cotUid = contentUidNode.element?.text ?? UUID().uuidString
                                    
                                    let fetchDSItem: NSFetchRequest<DataSyncMissionItem> = DataSyncMissionItem.fetchRequest()
                                    fetchDSItem.predicate = NSPredicate(format: "uid = %@", cotUid as String)
                                    let dataSyncItemResults = try? self.dataContext.fetch(fetchDSItem)
                                    
                                    let fetchCot: NSFetchRequest<COTData> = COTData.fetchRequest()
                                    fetchCot.predicate = NSPredicate(format: "cotUid = %@", cotUid as String)
                                    let results = try? self.dataContext.fetch(fetchCot)
                                    
                                    if results?.count == 0 && dataSyncItemResults?.count == 0 {
                                        TAKLogger.debug("[COTDataParser] Delete request received for a CoT message not locally stored. Skipping")
                                    } else {
                                        do {
                                            if let cotData = results?.first {
                                                TAKLogger.debug("[COTDataParser] Removing item from COTDB")
                                                self.dataContext.delete(cotData)
                                            }
                                            if let dsData = dataSyncItemResults?.first {
                                                TAKLogger.debug("[COTDataParser] Removing item from DataSync DB")
                                                self.dataContext.delete(dsData)
                                            }
                                            try self.dataContext.save()
                                        } catch {
                                            TAKLogger.error("[COTDataParser] Invalid Data Context Save \(error)")
                                        }
                                    }
                                }
                            } else {
                                TAKLogger.debug("[COTDataParser] Found a contentUid node without details. Skipping.")
                            }
                        } else if contentHashNode.element != nil {
                            removeMissionContent(missionGuid: missionGuid, fileHash: contentHashNode.element!.text)
                        } else {
                            TAKLogger.debug("[COTDataParser] Neither UID nor Hash present during Data Sync change \(addType). Skipping.")
                        }
                    } else {
                        TAKLogger.debug("[COTDataParser] Data Sync request to \(addType) not yet implemented")
                        return
                    }
                }
            }
            
            return
        }
    }
    
    func parseTask(cotEvent: COTEvent, rawXml: String) {
        // Content changes will specify either a hash or uid, not both
        if cotEvent.type.starts(with: "t-x-m-c") { // mission change
            parseMissionXml(rawXml: rawXml)
        } else if cotEvent.type == "t-x-d-d" { // item delete
            
        } else if cotEvent.type == "t-x-m-d" { // mission delete
            
        } else {
            TAKLogger.debug("[COTDataParser] unhandled tasking event received \(cotEvent.type)")
            TAKLogger.debug("[COTDataParser] \(rawXml)")
        }
        // should have mission guid in link
        // t-x-d-d is delete event
        // t-x-m-n is mission created
        // t-x-m-c is mission change
        // t-x-takp-v is version request
        /*
         case LOG:                { cotType = "t-x-m-c-l"; break; }
         case KEYWORD:            { cotType = "t-x-m-c-k"; break; }
         case UID_KEYWORD:        { cotType = "t-x-m-c-k-u"; break; }
         case RESOURCE_KEYWORD:    { cotType = "t-x-m-c-k-c"; break; }
         case METADATA:            { cotType = "t-x-m-c-m"; break; }
         case EXTERNAL_DATA:        { cotType = "t-x-m-c-e"; break; }
         case MISSION_LAYER:        { cotType = "t-x-m-c-h"; break; }
         default:
         case CONTENT:            { cotType = "t-x-m-c";  break; }
         t-x-m-n create Mission
         t-x-m-d delete Mission
         t-x-m-i mission invite
         t-x-m-r mission role change
         */
        
        /*
         "<?xml version="1.0" encoding="UTF-8"?><event how="h-g-i-g-o" type="t-x-m-c" version="2.0" uid="d4234874-629e-4e55-8ab3-d7605c1d120b" start="2025-02-28T03:41:24Z" time="2025-02-28T03:41:24Z" stale="2025-02-28T03:41:44Z"><point ce="9999999" le="9999999" hae="0" lat="0" lon="0"/><detail><mission type="CHANGE" tool="public" name="FT-Test4" guid="606acd50-4dc5-46e9-86ba-6f64e14f3796" authorUid="F8C5D325-7B71-48E1-B148-F00E62387BEC"><MissionChanges><MissionChange><contentUid>A4F2E606-A1AF-4FA3-AB97-211DA9DEF357</contentUid><creatorUid>F8C5D325-7B71-48E1-B148-F00E62387BEC</creatorUid><isFederatedChange>false</isFederatedChange><missionName>FT-Test4</missionName><timestamp>2025-02-28T03:41:24.579Z</timestamp><type>ADD_CONTENT</type><details type="a-u-G" callsign="CP-HQ-Foy-iTAK.27.224010" iconsetPath="COT_MAPPING_2525B/a-u/a-u-G" color="-1"><location lat="36.04872578747775" lon="-79.17847949231503"/></details></MissionChange></MissionChanges></mission></detail></event>"
         */
        TAKLogger.debug("[COTDataParser] Parsing task \(cotEvent.type)")
    }
    
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
