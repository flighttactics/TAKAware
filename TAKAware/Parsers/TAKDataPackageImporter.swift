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

// TODO: Import Custom Iconsets
// TODO: Import multiple connections
// TODO: Handle preference files 
class TAKDataPackageImporter: COTDataParser {
    var archiveLocation: URL
    var fileHash: String = ""
    var parsingErrors: [String] = []
    var parser: DataPackageParser?
    var dataPackageStore: DataPackage?
    var missionPackage: TAKMissionPackage
    var packageUUID: UUID
    let dataPackageURL = AppConstants.appDirectoryFor(.dataPackages)
    var extractLocation: URL
    
    init(fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageImporter]: Initializing")
        archiveLocation = fileLocation
        packageUUID = UUID()
        extractLocation = dataPackageURL.appending(path: packageUUID.uuidString)
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
        packageUUID = UUID()
        extractLocation = dataPackageURL.appending(path: packageUUID.uuidString)
        self.missionPackage = missionPackage
        self.fileHash = missionPackage.hash
        super.init()
    }
    
    func parse() {
        parser = DataPackageParser(fileLocation: archiveLocation, extractLocation: extractLocation)
        parser!.parse()
        storeDataPackage()
        importFiles()
        TAKLogger.debug("[TAKDataPackageImporter]: Completed Parsing")
    }
    
    func storeDataPackage() {
        let packageConfiguration = parser!.packageConfiguration
        let packageName = packageConfiguration["name"] ?? missionPackage.name
        let fetchPackage: NSFetchRequest<DataPackage> = DataPackage.fetchRequest()
        fetchPackage.predicate = NSPredicate(format: "uid = %@", packageUUID.uuidString as String)

        dataContext.perform {
            let results = try? self.dataContext.fetch(fetchPackage)
            
            let packageData: DataPackage!

            if results?.count == 0 {
                packageData = DataPackage(context: self.dataContext)
                packageData.uid = self.packageUUID
                packageData.dataPackageUid = packageConfiguration["uid"] ?? ""
                packageData.name = packageName
                packageData.user = self.missionPackage.user
                packageData.contentsVisible = true
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
    
    func processKml(parser: DataPackageParser, packageFile: DataPackageContentsFile) {
        dataContext.perform {
            let packageDataFile = DataPackageFile(context: self.dataContext)
            packageDataFile.dataPackage = self.dataPackageStore
            packageDataFile.zipEntry = packageFile.fileLocation
            packageDataFile.ignore = false
            packageDataFile.isCoT = false
            packageDataFile.visible = true
            packageDataFile.name = packageFile.fileName
            do {
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[TAKDataPackageImporter] Invalid Data Context KML Save \(error)")
            }
        }
        
        let kmlFile = parser.retrieveFileFromArchive(packageFile)
        Task {
            guard let fileUrl = URL(string: packageFile.fileLocation) else {
                TAKLogger.error("[TAKDataPackageImporter] Unable to process fileURL as URL")
                return
            }
            let fileName = fileUrl.lastPathComponent
            let importer = KMLImporter(fileName: fileName, fileData: kmlFile)
            let fileProcessed = await importer.process()
            if !fileProcessed {
                TAKLogger.debug("[TAKDataPackageImporter] Unable to process KML file \(fileName)")
            }
        }
    }
    
    func processCoT(parser: DataPackageParser, packageFile: DataPackageContentsFile) {
        dataContext.perform {
            let packageDataFile = DataPackageFile(context: self.dataContext)
            packageDataFile.dataPackage = self.dataPackageStore
            packageDataFile.zipEntry = packageFile.fileLocation
            packageDataFile.ignore = false
            packageDataFile.isCoT = true
            packageDataFile.visible = true
            packageDataFile.name = packageFile.fileName
            let cotFile = parser.retrieveFileFromArchive(packageFile)
            let rawXml = String(decoding: cotFile, as: UTF8.self)
            guard let cotEvent = self.cotParser.parse(rawXml) else {
                TAKLogger.error("[TAKDataPackageImporter] Unable to parse COT XML for \(packageFile.fileLocation). Skipping.")
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
    
    func processMapSource(parser: DataPackageParser, packageFile: DataPackageContentsFile) {
        TAKLogger.debug("[TAKDataPackageImporter] Attempting to process XML as a map source")
        let mapFile = parser.retrieveFileFromArchive(packageFile)
        guard !mapFile.isEmpty else {
            return
        }
        let importer = MapSourceImporter(mapName: packageFile.fileName, fileData: mapFile)
        Task {
           await importer.process()
        }
    }
    
    func processUnknown(parser: DataPackageParser, packageFile: DataPackageContentsFile) {
        dataContext.perform {
            let packageDataFile = DataPackageFile(context: self.dataContext)
            packageDataFile.dataPackage = self.dataPackageStore
            packageDataFile.zipEntry = packageFile.fileLocation
            packageDataFile.ignore = false
            packageDataFile.isCoT = false
            packageDataFile.visible = false
            packageDataFile.name = packageFile.fileName
            do {
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[TAKDataPackageImporter] Invalid Data Context KML Save \(error)")
            }
        }
    }
    
    func importFiles() {
        guard let parser = parser else { return }
        let packageFiles = parser.packageFiles
        guard !packageFiles.isEmpty else { return }
        packageFiles.forEach {
            if $0.shouldIgnore {
                return
            } else {
                if $0.fileLocation.hasSuffix(".cot") {
                    self.processCoT(parser: parser, packageFile: $0)
                } else if $0.fileLocation.hasSuffix(".kml") {
                    self.processKml(parser: parser, packageFile: $0)
                } else if $0.fileLocation.hasSuffix(".kmz") {
                    self.processKml(parser: parser, packageFile: $0)
                } else if $0.fileLocation.hasSuffix(".xml") {
                    self.processMapSource(parser: parser, packageFile: $0)
                } else {
                    self.processUnknown(parser: parser, packageFile: $0)
                }
            }
        }
    }
}
