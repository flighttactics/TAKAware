//
//  TAKDataPackageImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 11/14/24.
//

import Foundation
import NIOSSL
import SwiftTAK
import CoreData

class TAKDataPackageImporter: COTDataParser {
    var archiveLocation: URL
    var parsingErrors: [String] = []
    var parser: DataPackageParser?
    var dataPackageStore: DataPackage?
    
    init (fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageImporter]: Initializing")
        archiveLocation = fileLocation
        super.init()
    }
    
    func parse() {
        parser = DataPackageParser(fileLocation: archiveLocation)
        parser!.parse()
        //let packageFiles = parser!.packageFiles
        
        // So now we have the package parsed, a list of the files, and the configuration
        // We need to do a couple of things:
        // 1) Create some sort of data store for this package we're importing
        //    so we can manage it from the UI
        // 2) Go through the files and import them, performing necessary actions
        // 3) Make sure when we're importing them they're tied to this package
        //    and marked as archived so they don't get wiped out
        
        storeDataPackage()
        importFiles()
        
        TAKLogger.debug("[TAKDataPackageImporter]: Completed Parsing")
    }
    
    func storeDataPackage() {
        let packageConfiguration = parser!.packageConfiguration
        let packageName = packageConfiguration["name"] ?? "Data Package"
        let packageUid = packageConfiguration["uid"] ?? UUID().uuidString
        let fetchUser: NSFetchRequest<DataPackage> = DataPackage.fetchRequest()
        fetchUser.predicate = NSPredicate(format: "uid = %@", packageUid as String)

        dataContext.perform {
            let results = try? self.dataContext.fetch(fetchUser)
            
            let packageData: DataPackage!

            if results?.count == 0 {
                packageData = DataPackage(context: self.dataContext)
                packageData.uid = UUID(uuidString: packageUid)
                packageData.name = packageName
                packageData.createdAt = Date.now
             } else {
                 packageData = results?.first
             }

            do {
                try self.dataContext.save()
                self.dataPackageStore = packageData
            } catch {
                TAKLogger.error("[TAKDataPackageImporter] Invalid Data Context Save \(error)")
            }
        }
    }
    
    func importFiles() {
        guard let parser = parser else { return }
        let packageFiles = parser.packageFiles
        guard !packageFiles.isEmpty else { return }
        packageFiles.forEach {
            if $0.shouldIgnore { return }
            if $0.fileLocation.hasSuffix(".cot") {
                let cotFile = parser.retrieveFileFromArchive($0)
                let rawXml = String(decoding: cotFile, as: UTF8.self)
                guard let cotEvent = cotParser.parse(rawXml) else {
                    return
                }
                
                switch(cotEvent.eventType) {
                case .ATOM, .BIT:
                    parseAtom(cotEvent: cotEvent, rawXml: rawXml)
                default:
                    TAKLogger.debug("[TAKDataPackageImporter] Non-Atom CoT Event received \(cotEvent.type)")
                }
            }
        }
    }
}
