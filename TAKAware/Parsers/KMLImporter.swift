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
    var archiveLocation: URL
    var savedLocation: URL?
    var fileUUID: UUID
    var kmlParser: KMLParser
    var kmlFile: KMLFile?
    var rootFile: URL?
    let overlaysURL = AppConstants.appDirectoryFor(.OVERLAYS)
    var hasFailure = false
    
    init(archiveLocation: URL) {
        self.archiveLocation = archiveLocation
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
        NSLog("***ALL DONE PROCESSING***")
        return !self.hasFailure
    }
    
    private func createOrLoadDataStore() {
        guard !hasFailure else { return }
        let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
        fetchKml.predicate = NSPredicate(format: "fileName = %@", archiveLocation.lastPathComponent)
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
        TAKLogger.debug("[KMLImporter] Preparing to copy file")
        do {
            if archiveLocation.startAccessingSecurityScopedResource() {
                let fileName = archiveLocation.lastPathComponent
                let overlayFileURL = overlaysURL.appendingPathComponent(fileName)
                let data = try Data(contentsOf: archiveLocation)
                try data.write(to: overlayFileURL)
                savedLocation = overlayFileURL
            } else {
                hasFailure = true
                TAKLogger.error("[KMLImporter] Error copying file from \(archiveLocation.path()): Unable to access")
            }
        } catch {
            hasFailure = true
            TAKLogger.error("[KMLImporter] Error copying file from \(archiveLocation.path()): \(error)")
        }
        archiveLocation.stopAccessingSecurityScopedResource()
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
        var extractLocation = overlaysURL.appendingPathComponent(fileUUID.uuidString)
        do {
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
