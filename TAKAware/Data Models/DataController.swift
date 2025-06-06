//
//  DataController.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/6/24.
//

import CoreData
import Foundation
import SwiftTAK
import MapKit

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
//        let description = NSPersistentStoreDescription()
//        description.url = URL(fileURLWithPath: "/dev/null")
//        container.persistentStoreDescriptions = [description]
        
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
        clearStaleItems()
    }
    
    func startCleanUpTimer() {
        guard cleanUpTimer == nil else { return }
        cleanUpTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.clearStaleItems()
        }
    }

    func updateMarker(id: String, title: String, remarks: String, cotType: String) {
        let fetchUser: NSFetchRequest<COTData> = COTData.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "id = %@", id)
        persistentContainer.viewContext.perform {
            let results = try? self.persistentContainer.viewContext.fetch(fetchUser)
            if results?.count == 0 {
                TAKLogger.error("[DataController] Unable to locate marker with id \(id) for editing")
                return
            } else {
                let mapPointData: COTData = results!.first!
                mapPointData.callsign = title
                mapPointData.remarks = remarks
                mapPointData.cotType = cotType
                mapPointData.archived = true // Always archive edited markers
                if(mapPointData.hasChanges) {
                    do {
                        try self.persistentContainer.viewContext.save()
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
        
        persistentContainer.viewContext.perform {
            let mapPointData: COTData!
            mapPointData = COTData(context: self.persistentContainer.viewContext)
            mapPointData.id = UUID()
            mapPointData.cotUid = UUID().uuidString
            mapPointData.callsign = defaultCallsign
            mapPointData.latitude = latitude
            mapPointData.longitude = longitude
            mapPointData.remarks = ""
            mapPointData.cotType = defaultType
            mapPointData.startDate = Date.now
            mapPointData.updateDate = Date.now
            mapPointData.archived = true // Always archive created markers
            mapPointData.rawXml = cotEvent.toXml()

            do {
                try self.persistentContainer.viewContext.save()
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
    
    func deletePackage(dataPackage: DataPackage, deleteAssociatedCoT: Bool = true, deleteStoredFile: Bool = true) {
        let dataContext = dataPackage.managedObjectContext ?? backgroundContext
        let extractLocation = dataPackage.extractLocation
        dataContext.perform {
            let packageFiles = self.dataPackageFilesFromDataPackage(dataPackage)
            packageFiles.forEach { dataPackageFile in
                if deleteAssociatedCoT && dataPackageFile.cotData != nil {
                    dataContext.delete(dataPackageFile.cotData!)
                } else {
                    TAKLogger.debug("[DataController] ***No associated COTData object to delete! \(dataPackageFile.cotUid?.uuidString ?? "NO UUID")")
                }
                dataContext.delete(dataPackageFile)
            }
            dataContext.delete(dataPackage)
            do {
                try dataContext.save()
                if deleteStoredFile && extractLocation != nil {
                    let fileManager = FileManager()
                    TAKLogger.debug("[DataController] Deleting Data Package directory at \(extractLocation!.path(percentEncoded: false))")
                    try fileManager.removeItem(at: extractLocation!)
                }
            } catch {
                TAKLogger.error("[DataController]: Unable to delete package \(error)")
            }
        }
    }
    
    func deleteKMLFile(kmlFile: KMLFile, deleteStoredFile: Bool = true) {
        let dataContext = kmlFile.managedObjectContext ?? backgroundContext
        let filePath = kmlFile.filePath!
        let fileID = kmlFile.id!
        let isKmz = kmlFile.isCompressed
        dataContext.perform {
            dataContext.delete(kmlFile)
            do {
                try dataContext.save()
                if deleteStoredFile {
                    let fileManager = FileManager()
                    if isKmz {
                        let kmzSubdirectory = AppConstants.appDirectoryFor(.overlays).appendingPathComponent(fileID.uuidString)
                        TAKLogger.debug("[DataController] Deleting KMZ directory at \(kmzSubdirectory.path(percentEncoded: false))")
                        try fileManager.removeItem(at: kmzSubdirectory)
                    }
                    try fileManager.removeItem(at: filePath)
                }
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
    
    func activateMapSource(name: String) {
        switch name {
        case "Standard":
            SettingsStore.global.mapTypeDisplay = MKMapType.standard.rawValue
            changeCustomMapSourceVisibility(visible: false)
        case "Hybrid":
            SettingsStore.global.mapTypeDisplay = MKMapType.hybrid.rawValue
            changeCustomMapSourceVisibility(visible: false)
        case "Satellite":
            SettingsStore.global.mapTypeDisplay = MKMapType.satellite.rawValue
            changeCustomMapSourceVisibility(visible: false)
        case "Flyover":
            SettingsStore.global.mapTypeDisplay = MKMapType.hybridFlyover.rawValue
            changeCustomMapSourceVisibility(visible: false)
        default:
            changeCustomMapSourceVisibility(mapName: name, visible: true)
            SettingsStore.global.mapTypeDisplay = MKMapType.satellite.rawValue
        }
    }
    
    func changeCustomMapSourceVisibility(mapSource: MapSource? = nil, mapName: String? = nil, visible: Bool) {
        TAKLogger.debug("[DataController] Requested to change custom map source visibility to \(visible)")
        let fetch = MapSource.fetchRequest()
        let dataContext = mapSource?.managedObjectContext ?? backgroundContext
        dataContext.perform {
            do {
                let customMapSources = try dataContext.fetch(fetch)
                // Only one custom map source can be visible at a time
                customMapSources.forEach { customMapSource in
                    if customMapSource.name == mapName {
                        customMapSource.visible = visible
                    } else {
                        customMapSource.visible = false
                    }
                }
                mapSource?.visible = visible
                try dataContext.save()
                NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_MAP_SOURCE_UPDATED), object: nil)
            } catch {
                TAKLogger.error("[DataController]: Unable to change Map Source visibility \(error)")
            }
        }
        
    }
    
    func deleteMapSource(mapSource: MapSource) {
        let dataContext = mapSource.managedObjectContext ?? backgroundContext
        dataContext.perform {
            dataContext.delete(mapSource)
            do {
                try dataContext.save()
                NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_MAP_SOURCE_UPDATED), object: nil)
            } catch {
                TAKLogger.error("[DataController]: Unable to change visibility of Map Source \(error)")
            }
        }
    }
    
    func deleteCot(cotId: String) {
        let predicate = NSPredicate(format: "id = %@", cotId)
        clearMap(query: predicate)
    }
    
    func clearAll() async {
        TAKLogger.debug("[DataController] Clearing All Data")
        
        let entityList = ["COTData", "DataPackage", "DataPackageFile", "KMLFile", "MapSource"]
        await backgroundContext.perform {
            entityList.forEach { entityName in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try self.backgroundContext.execute(deleteRequest)
                } catch {
                    TAKLogger.error("[DataController] Error during clear all of \(entityName): \(error)")
                }
            }
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
    
    func clearMap(query: NSPredicate) {
        backgroundContext.perform {
            let fetch = COTData.fetchRequest()
            fetch.predicate = query
            fetch.includesPropertyValues = false
            
            do {
                let result = try self.backgroundContext.fetch(fetch)
                let count = result.count
                TAKLogger.debug("[DataController]: This query will impact \(count) records")
                for row in result {
                    self.backgroundContext.delete(row)
                }
                try self.backgroundContext.save()
                NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_COT_REMOVED), object: nil)
            } catch {
                TAKLogger.error("[DataController]: Unable to clear map \(error)")
            }
        }
    }
}
