//
//  KMLImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import Foundation
import CoreData
import ZIPFoundation

class KMLImporter: COTDataParser {
    var archiveLocation: URL?
    var fileName: String
    var fileData: Data?
    var savedLocation: URL?
    var fileUUID: UUID
    var kmlParser: KMLParser
    var kmlFile: KMLFile?
    var rootFile: URL?
    let overlaysURL = AppConstants.appDirectoryFor(.overlays)
    var hasFailure = false
    
    init(archiveLocation: URL) {
        self.archiveLocation = archiveLocation
        fileName = archiveLocation.lastPathComponent
        kmlParser = KMLParser()
        fileUUID = UUID()
    }
    
    init(fileName: String, fileData: Data) {
        self.fileName = fileName
        self.fileData = fileData
        kmlParser = KMLParser()
        fileUUID = UUID()
    }
    
    func process() async -> Bool {
        TAKLogger.debug("[KMLImporter] Starting KML processing")
        createDirectoryIfNeeded()
        await dataContext.perform {
            self.createOrLoadDataStore()
            self.copyFile()
            self.extractIfCompressed()
            self.parseFile()
            self.storeFile()
        }
        TAKLogger.debug("[KMLImporter] Completed KML processing")
        return !self.hasFailure
    }
    
    private func createOrLoadDataStore() {
        guard !hasFailure else { return }
        let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
        fetchKml.predicate = NSPredicate(format: "fileName = %@", fileName)
        let results = try? self.dataContext.fetch(fetchKml)

        if results?.count == 0 {
            kmlFile = KMLFile(context: self.dataContext)
            kmlFile!.id = UUID()
        } else {
            kmlFile = results?.first
            fileUUID = kmlFile!.id!
        }
    }
    
    private func copyFile() {
        guard !hasFailure else { return }
        TAKLogger.debug("[KMLImporter] Preparing to copy file \(fileName)")
        
        var data: Data!
        
        if fileData != nil {
            TAKLogger.debug("[KMLImporter] We have data of \(fileData!.debugDescription) - writing directly")
            data = fileData
        } else if archiveLocation != nil {
            TAKLogger.debug("[KMLImporter] We have an archiveLocation of \(archiveLocation!.path()) - copying")
            do {
                if archiveLocation!.startAccessingSecurityScopedResource() {
                    fileName = archiveLocation!.lastPathComponent
                    data = try Data(contentsOf: archiveLocation!)
                } else {
                    hasFailure = true
                    TAKLogger.error("[KMLImporter] Error copying file from \(archiveLocation!.path()): Unable to access")
                }
            } catch {
                hasFailure = true
                TAKLogger.error("[KMLImporter] Error copying file from \(archiveLocation!.path()): \(error)")
            }
            archiveLocation!.stopAccessingSecurityScopedResource()
        }
        
        let overlayFileURL = overlaysURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: overlayFileURL)
            savedLocation = overlayFileURL
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Error writing file to \(overlayFileURL.path()): \(error)")
        }

        TAKLogger.debug("[KMLImporter] File copy complete")
    }
    
    private func extractIfCompressed() {
        guard !hasFailure else { return }
        guard let savedLocation = savedLocation else { hasFailure = true; return }
        guard savedLocation.lastPathComponent.hasSuffix("kmz") else {
            rootFile = savedLocation
            return
        }
        let fileManager = FileManager()
        let extractLocation = overlaysURL.appendingPathComponent(fileUUID.uuidString)
        do {
            TAKLogger.debug("[KMLImporter] Extracting KMZ to \(extractLocation.path())")
            try fileManager.createDirectory(at: extractLocation, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: savedLocation, to: extractLocation)
            let extractedFiles: [String] = try fileManager.contentsOfDirectory(atPath: extractLocation.path())
            guard let rootKml = extractedFiles.first(where: { $0.hasSuffix("kml") }) else {
                hasFailure = true
                TAKLogger.error("[KMLImporter] Extraction of ZIP archive failed due to no root KML file")
                return
            }
            rootFile = extractLocation.appendingPathComponent(rootKml)
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Extraction of ZIP archive failed with error:\(error)")
        }
    }
    
    private func parseFile() {
        guard !hasFailure else { return }
        guard let rootFile = rootFile else {
            hasFailure = true
            TAKLogger.debug("[KMLImporter] No files saved so unable to parse KML")
            return
        }
        do {
            let data = try Data(contentsOf: rootFile)
            if let kmlString = String(data: data, encoding: .utf8) {
                TAKLogger.debug("[KMLImporter] Starting parse of KML File")
                kmlParser.parse(kmlString: kmlString)
            }
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Error parsing file: \(error)")
        }
    }
    
    private func storeFile() {
        guard !hasFailure else { return }
        guard let kmlFile = kmlFile else {
            hasFailure = true
            TAKLogger.error("[KMLImporter] kmlFile was nil when attempting to store the final result")
            return
        }
        kmlFile.id = fileUUID
        kmlFile.fileName = self.savedLocation!.lastPathComponent
        kmlFile.filePath = self.savedLocation!
        kmlFile.isCompressed = self.savedLocation!.lastPathComponent.hasSuffix(".kmz")
        kmlFile.visible = true
        
        do {
            TAKLogger.debug("[KMLImporter] KML Parsed - storing DB record")
            try self.dataContext.save()
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Invalid Data Context Save \(error)")
            return
        }
    }
    
    private func createDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: overlaysURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Error creating directory: \(error)")
        }
    }
}
