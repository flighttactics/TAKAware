//
//  DataController.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/6/24.
//

import CoreData
import Foundation
import SwiftTAK

class DataController: ObservableObject {
    
    static let shared = DataController()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.overwrite
        return context
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "COTData")
        
        // Enable memory-only store by enabling these lines
        //let description = NSPersistentStoreDescription()
        //description.url = URL(fileURLWithPath: "/dev/null")
        //container.persistentStoreDescriptions = [description]
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { persistentStore, error in
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergePolicy.overwrite
            if let error {
                TAKLogger.error("[DataController]: **FATAL ERROR** Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    //let cotDataContainer = NSPersistentContainer(name: "COTData")
    //var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var cleanUpTimer: Timer?
    
    private init() {
        clearTransientItems()
    }
    
    func startCleanUpTimer() {
        guard cleanUpTimer == nil else { return }
        cleanUpTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.clearStaleItems()
        }
    }
    
    func clearAllMarkers() {
        let predicate = NSPredicate(format: "1=1", Date() as CVarArg)
        clearMap(query: predicate)
    }
    
    // Clears everything not archived, regardless of stale
    func clearTransientItems() {
        let archiveFalseFlagPredicate = NSPredicate(format: "archived == NO")
        clearMap(query: archiveFalseFlagPredicate)
    }
    
    // Clears all non-archive stale items
    func clearStaleItems() {
        let staleDatePredictate = NSPredicate(format: "staleDate < %@", Date() as NSDate)
        let archiveFalseFlagPredicate = NSPredicate(format: "archived == NO")
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [staleDatePredictate, archiveFalseFlagPredicate])
        clearMap(query: predicate)
    }

    func updateMarker(id: String, title: String, remarks: String, cotType: String) {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "id = %@", id)
        backgroundContext.perform {
            let results = try? self.backgroundContext.fetch(fetchUser)
            if results?.count == 0 {
                TAKLogger.error("[DataController] Unable to locate marker with id \(id) for editing")
                return
            } else {
                let mapPointData: COTData = results!.first!
                mapPointData.callsign = title
                mapPointData.remarks = remarks
                mapPointData.cotType = cotType
                if(mapPointData.hasChanges) {
                    do {
                        try self.backgroundContext.save()
                    } catch {
                        TAKLogger.error("[DataController] Invalid Data Context Save \(error)")
                    }
                }
            }
        }
    }
    
    func createMarker(latitude: Double, longitude: Double) {
        let defaultCallsign = "UNKNOWN \(CGFloat.random(in: 1...1000))"
        let defaultType = "a-U-G"
        
        // First create a COTEvent
        var cotEvent = COTEvent(version: COTMessage.COT_EVENT_VERSION, uid: UUID().uuidString, type: defaultType, how: HowType.MachineGPSDerived.rawValue, time: Date.now, start: Date.now, stale: Date.distantFuture)
        let cotPoint = COTPoint(lat: latitude.description, lon: longitude.description, hae: COTPoint.DEFAULT_ERROR_VALUE.description, ce: COTPoint.DEFAULT_ERROR_VALUE.description, le: COTPoint.DEFAULT_ERROR_VALUE.description)
        
        var cotDetail = COTDetail()
        
        cotDetail.childNodes.append(COTContact(callsign: defaultCallsign))
        cotDetail.childNodes.append(COTArchive())
        
        cotEvent.childNodes.append(cotPoint)
        cotEvent.childNodes.append(cotDetail)
        
        backgroundContext.perform {
            let mapPointData: COTData!
            mapPointData = COTData(context: self.backgroundContext)
            mapPointData.id = UUID()
            mapPointData.cotUid = UUID().uuidString
            mapPointData.callsign = defaultCallsign
            mapPointData.latitude = latitude
            mapPointData.longitude = longitude
            mapPointData.remarks = ""
            mapPointData.cotType = defaultType
            mapPointData.startDate = Date.now
            mapPointData.updateDate = Date.now
            mapPointData.archived = true
            mapPointData.rawXml = cotEvent.toXml()

            do {
                try self.backgroundContext.save()
            } catch {
                TAKLogger.error("[DataController] Invalid Data Context Save \(error)")
            }
        }
    }
    
    func dataPackageFilesFromDataPackage(_ dataPackage: DataPackage) -> [DataPackageFile] {
        let packageFiles = dataPackage.dataPackageFiles as? Set<DataPackageFile> ?? []
        return packageFiles.sorted {
            $0.isCoT.description < $1.isCoT.description
        }
    }
    
    func changePackageVisibility(dataPackage: DataPackage, makeVisible: Bool) {
        let dataContext = dataPackage.managedObjectContext ?? backgroundContext
        dataContext.perform {
            let packageFiles = self.dataPackageFilesFromDataPackage(dataPackage)
            packageFiles.forEach { dataPackageFile in
                if dataPackageFile.cotData != nil {
                    dataPackageFile.cotData!.visible = makeVisible
                }
            }
            dataPackage.contentsVisible = makeVisible
            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[DataController]: Unable to change visibility of package \(error)")
            }
        }
    }
    
    func deletePackage(dataPackage: DataPackage, deleteAssociatedCoT: Bool = true) {
        let dataContext = dataPackage.managedObjectContext ?? backgroundContext
        dataContext.perform {
            let packageFiles = self.dataPackageFilesFromDataPackage(dataPackage)
            packageFiles.forEach { dataPackageFile in
                if deleteAssociatedCoT && dataPackageFile.cotData != nil {
                    dataContext.delete(dataPackageFile.cotData!)
                } else {
                    NSLog("***No associated COTData object to delete! \(dataPackageFile.cotUid?.uuidString ?? "NO UUID")")
                }
                dataContext.delete(dataPackageFile)
            }
            dataContext.delete(dataPackage)
            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[DataController]: Unable to delete package \(error)")
            }
        }
    }
    
    func deleteKMLFile(kmlFile: KMLFile, deleteStoredFile: Bool = true) {
        let dataContext = kmlFile.managedObjectContext ?? backgroundContext
        dataContext.perform {
            dataContext.delete(kmlFile)
            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[DataController]: Unable to delete KML File \(error)")
            }
        }
    }
    
    func changeKMLFileVisibility(kmlFile: KMLFile, visible: Bool) {
        let dataContext = kmlFile.managedObjectContext ?? backgroundContext
        dataContext.perform {
            kmlFile.visible = visible
            do {
                try dataContext.save()
            } catch {
                TAKLogger.error("[DataController]: Unable to change visibility of KML File \(error)")
            }
        }
    }
    
    func deleteCot(cotId: String) {
        let predicate = NSPredicate(format: "id = %@", cotId)
        clearMap(query: predicate)
    }
    
    func clearMap(query: NSPredicate) {
        backgroundContext.perform {
            let fetch = COTData.fetchRequest()
            fetch.predicate = query
            fetch.includesPropertyValues = false
            //let request = NSBatchDeleteRequest(fetchRequest: fetch)
            //request.resultType = .resultTypeObjectIDs
            
            do {
                let result = try self.backgroundContext.fetch(fetch)
                let count = result.count
                TAKLogger.debug("[DataController]: This query will impact \(count) records")
                for row in result {
                    self.backgroundContext.delete(row)
                }
                try self.backgroundContext.save()
//                let deleteResult = try dataContext.execute(request) as? NSBatchDeleteResult
//                if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
//                    // Merge the deletions into the app's managed object context.
//                    NSManagedObjectContext.mergeChanges(
//                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
//                        into: [dataContext]
//                    )
//                }
            } catch {
                TAKLogger.error("[DataController]: Unable to clear map \(error)")
            }
        }
    }
}
