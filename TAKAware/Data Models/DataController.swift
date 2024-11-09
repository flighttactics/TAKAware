//
//  DataController.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/6/24.
//

import CoreData
import Foundation

class DataController: ObservableObject {
    
    static let shared = DataController()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "COTData")
        
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { persistentStore, error in
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergePolicy.overwrite
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    //let cotDataContainer = NSPersistentContainer(name: "COTData")
    //var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var cleanUpTimer: Timer?
    
    private init() {}
    
    func startCleanUpTimer() {
        guard cleanUpTimer == nil else { return }
        cleanUpTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.clearStaleItems()
        }
    }
    
    // Clears everything not archived, regardless of stale
    func clearTransientItems() {
        let predicate = NSPredicate(format: "1=1", Date() as CVarArg)
        clearMap(query: predicate)
    }
    
    // Clears all non-archive stale items
    func clearStaleItems() {
        let predicate = NSPredicate(format: "staleDate < %@", Date() as NSDate)
        clearMap(query: predicate)
    }
    
    func clearMap(query: NSPredicate) {
        self.persistentContainer.performBackgroundTask { dataContext in
            dataContext.mergePolicy = NSMergePolicy.overwrite
            let fetch = COTData.fetchRequest()
            fetch.predicate = query
            fetch.includesPropertyValues = false
            
            //let request = NSBatchDeleteRequest(fetchRequest: fetch)
            //request.resultType = .resultTypeObjectIDs
            
            do {
                let result = try dataContext.fetch(fetch)
                let count = result.count
                TAKLogger.debug("[DataController]: This query will impact \(count) records")
                for row in result {
                    dataContext.delete(row)
                }
                try dataContext.save()
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
