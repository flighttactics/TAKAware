//
//  MapCacheDataController.swift
//  TAKAware
//
//  Created by Cory Foy on 6/4/25.
//

import CoreData
import Foundation
import SwiftTAK

class MapCacheDataController: ObservableObject {
    static let shared = MapCacheDataController()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.overwrite
        return context
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MapCache")
        
        // Enable memory-only store by enabling these lines
        // let description = NSPersistentStoreDescription()
        // description.url = URL(fileURLWithPath: "/dev/null")
        // container.persistentStoreDescriptions = [description]
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { persistentStore, error in
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergePolicy.overwrite
            if let error {
                TAKLogger.error("[MapCacheDataController]: **FATAL ERROR** Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    init() {}
    
    func clearAll() {
        backgroundContext.perform {
            
            let fetchMapTiles: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MapCache")
            let mapTilesDelete = NSBatchDeleteRequest(fetchRequest: fetchMapTiles)

            _ = try? self.backgroundContext.execute(mapTilesDelete)
        }
    }
    
    func retrieveTileFor(cacheKey: String) async -> Data? {
        return await persistentContainer.viewContext.perform {
            let fetchTile: NSFetchRequest<MapCache> = MapCache.fetchRequest()
            fetchTile.predicate = NSPredicate(format: "key = %@", cacheKey)
            let results = (try? self.persistentContainer.viewContext.fetch(fetchTile)) ?? []
            return results.first?.tileData
        }
    }
    
    func insertTile(cacheKey: String, mapTile: Data) async {
        await backgroundContext.perform {
            let fetchTile: NSFetchRequest<MapCache> = MapCache.fetchRequest()
            fetchTile.predicate = NSPredicate(format: "key = %@", cacheKey)
            let results = (try? self.backgroundContext.fetch(fetchTile)) ?? []
            if results.isEmpty {
                let cachedTile: MapCache = MapCache(context: self.backgroundContext)
                cachedTile.cachedAt = Date.now
                cachedTile.key = cacheKey
                cachedTile.tileData = mapTile
                do {
                    try self.backgroundContext.save()
                } catch {
                    TAKLogger.error("[MapCacheDataController] Invalid Data Context Save \(error)")
                }
            }
        }
    }

    func deleteCachedDataFor(baseUrl: String) {
        let dataContext = backgroundContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MapCache")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        fetchRequest.predicate = NSPredicate(format: "key BEGINSWITH %@", baseUrl)
        dataContext.perform {
            do {
                try dataContext.execute(batchDeleteRequest)
            } catch {
                TAKLogger.error("[MapCacheDataController]: Unable to delete cached data for baseUrl \(baseUrl): \(error)")
            }
        }
    }
}
