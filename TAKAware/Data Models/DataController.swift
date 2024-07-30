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
    
    let cotDataContainer = NSPersistentContainer(name: "COTData")
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var cleanUpTimer: Timer?
    
    private init() {
        cotDataContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        cotDataContainer.viewContext.automaticallyMergesChangesFromParent = true
        cotDataContainer.loadPersistentStores { description, error in
            if let error = error {
                TAKLogger.error("[DataController]: Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
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
        let predicate = NSPredicate(format: "staleDate < %@ AND archived == NO", Date() as CVarArg)
        clearMap(query: predicate)
    }
    
    func clearMap(query: NSPredicate) {
        self.cotDataContainer.performBackgroundTask { dataContext in
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
