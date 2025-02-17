//
//  IconDataController.swift
//  TAKAware
//
//  Created by Cory Foy on 2/8/25.
//

import CoreData
import Foundation
import SwiftTAK

enum IconDataControllerError: Error {
    case runtimeError(String)
}

class IconDataController: ObservableObject {
    static let shared = IconDataController()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.overwrite
        return context
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IconSetModel")
        
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
    
    private init() {}
    
    func clearAll() {
        backgroundContext.perform {
            
            let fetchIconset: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalIconSet")
            let iconsetDelete = NSBatchDeleteRequest(fetchRequest: fetchIconset)
            
            let fetchIcons: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalIcon")
            let iconsDelete = NSBatchDeleteRequest(fetchRequest: fetchIcons)
            
            _ = try? self.backgroundContext.execute(iconsetDelete)
            _ = try? self.backgroundContext.execute(iconsDelete)
        }
    }
    
    func retrieveIconSet(iconSetUid: String) async -> LocalIconSet? {
        return await backgroundContext.perform {
            let fetchIconset: NSFetchRequest<LocalIconSet> = LocalIconSet.fetchRequest()
            fetchIconset.predicate = NSPredicate(format: "uid = %@", iconSetUid)
            let results = (try? self.backgroundContext.fetch(fetchIconset)) ?? []
            return results.first
        }
    }
    
    func retrieveIconFor(iconSetUid: String, filename: String) async -> Data {
        return await backgroundContext.perform {
            let fetchIcon: NSFetchRequest<LocalIcon> = LocalIcon.fetchRequest()
            fetchIcon.predicate = NSPredicate(format: "iconset_uid = %@ AND filename = %@", iconSetUid, filename)
            let results = (try? self.backgroundContext.fetch(fetchIcon)) ?? []
            if results.count > 0 {
                let icon = results.first!
                return icon.bitmap ?? Data()
            }
            return Data()
        }
    }
    
    // TODO: Set selectedGroup name if empty
    // TODO: Fail insert if UUID already exists
    func createIconSet(iconSet: IconSet, icons: [Icon]) async throws {
        TAKLogger.debug("[IconDataController] Inserting iconset named \(iconSet.name)")
        var didCreateIconset = true
        
        await backgroundContext.perform {
            let fetchIconset: NSFetchRequest<LocalIconSet> = LocalIconSet.fetchRequest()
            fetchIconset.predicate = NSPredicate(format: "uid = %@", iconSet.uid)
            let results = (try? self.backgroundContext.fetch(fetchIconset)) ?? []
            if results.isEmpty {
                let iconSetData: LocalIconSet = LocalIconSet(context: self.backgroundContext)
                iconSetData.iconsetUUID = UUID()
                iconSetData.id = Int32(iconSet.id)
                iconSetData.uid = iconSet.uid
                iconSetData.name = iconSet.name
                iconSetData.version = Int16(iconSet.version ?? "0") ?? 0
                iconSetData.selectedGroup = iconSet.selectedGroup
                iconSetData.defaultFriendly = iconSet.defaultFriendly
                iconSetData.defaultHostile = iconSet.defaultHostile
                iconSetData.defaultNeutral = iconSet.defaultNeutral
                iconSetData.defaultUnknown = iconSet.defaultUnknown
                
                icons.forEach { parsedIcon in
                    let localIcon = LocalIcon(context: self.backgroundContext)
                    localIcon.filename = parsedIcon.filename
                    localIcon.groupName = parsedIcon.groupName
                    localIcon.iconset_uid = parsedIcon.iconset_uid
                    localIcon.iconUUID = iconSetData.iconsetUUID
                    localIcon.bitmap = parsedIcon.icon.pngData()
                }
                
                do {
                    try self.backgroundContext.save()
                } catch {
                    TAKLogger.error("[IconDataController] Invalid Data Context Save \(error)")
                    didCreateIconset = false
                }
            } else {
                TAKLogger.error("[IconDataController] IconSet \(iconSet.name) already exists with uid \(iconSet.uid)")
                didCreateIconset = false
            }
        }
        
        if !didCreateIconset {
            throw IconDataControllerError.runtimeError("IconSet \(iconSet.name) already exists with uid \(iconSet.uid)")
        }
    }
}
