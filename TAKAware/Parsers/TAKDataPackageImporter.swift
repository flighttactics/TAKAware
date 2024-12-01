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
    var fileHash: String = ""
    var parsingErrors: [String] = []
    var parser: DataPackageParser?
    var dataPackageStore: DataPackage?
    var missionPackage: TAKMissionPackage
    
    init(fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageImporter]: Initializing")
        archiveLocation = fileLocation
        self.missionPackage = TAKMissionPackage(
            creator: SettingsStore.global.callSign,
            expiration: nil,
            groups: "",
            hash: "",
            keywords: "",
            mimeType: "application/zip",
            name: fileLocation.lastPathComponent,
            size: "",
            time: Date.now,
            user: SettingsStore.global.callSign)
        super.init()
    }
    
    init (fileLocation: URL, missionPackage: TAKMissionPackage) {
        TAKLogger.debug("[TAKDataPackageImporter]: Initializing")
        archiveLocation = fileLocation
        self.missionPackage = missionPackage
        self.fileHash = missionPackage.hash
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
        let packageName = packageConfiguration["name"] ?? missionPackage.name
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
                packageData.user = self.missionPackage.user
                packageData.originalFileHash = self.missionPackage.hash
                packageData.createdAt = self.missionPackage.time ?? Date.now
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
        dataContext.perform {
            packageFiles.forEach {
                let packageDataFile = DataPackageFile(context: self.dataContext)
                packageDataFile.dataPackage = self.dataPackageStore
                packageDataFile.zipEntry = $0.fileLocation
                if $0.shouldIgnore {
                    packageDataFile.ignore = true
                    return
                } else {
                    if $0.fileLocation.hasSuffix(".cot") {
                        packageDataFile.isCoT = true
                        let cotFile = parser.retrieveFileFromArchive($0)
                        let rawXml = String(decoding: cotFile, as: UTF8.self)
                        guard let cotEvent = self.cotParser.parse(rawXml) else {
                            TAKLogger.error("[TAKDataPackageImporter] Unable to parse COT XML for \($0.fileLocation). Skipping.")
                            return
                        }
                        
                        switch(cotEvent.eventType) {
                        case .ATOM:
                            self.parseAtom(cotEvent: cotEvent, rawXml: rawXml, forceArchive: true, dataPackageFile: packageDataFile)
                        case .BIT:
                            self.parseAtom(cotEvent: cotEvent, rawXml: rawXml, forceArchive: true, dataPackageFile: packageDataFile)
                        case .CUSTOM:
                            self.parseCustom(cotEvent: cotEvent, rawXml: rawXml, forceArchive: true, dataPackageFile: packageDataFile)
                        default:
                            TAKLogger.debug("[TAKDataPackageImporter] Non-Atom CoT Event received \(cotEvent.type)")
                        }
                    }
                }
            }
        }
    }
}
