//
//  KMLImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import Foundation
import CoreData

class KMLImporter: COTDataParser {
    var archiveLocation: URL
    var savedLocation: URL?
    var kmlParser: KMLParser
    
    init(archiveLocation: URL) {
        self.archiveLocation = archiveLocation
        kmlParser = KMLParser()
    }
    
    func process() {
        TAKLogger.debug("[KMLImporter] Starting KML processing")
        createDirectoryIfNeeded()
        copyFile()
        parseFile()
        storeFile()
    }
    
    private func storeFile() {
        let fetchKml: NSFetchRequest<KMLFile> = KMLFile.fetchRequest()
        fetchKml.predicate = NSPredicate(format: "fileName = %@", savedLocation!.lastPathComponent)

        dataContext.perform {
            let results = try? self.dataContext.fetch(fetchKml)
            
            let kmlFile: KMLFile!

            if results?.count == 0 {
                kmlFile = KMLFile(context: self.dataContext)
                kmlFile.id = UUID()
            } else {
                 kmlFile = results?.first
            }

            kmlFile.fileName = self.savedLocation!.lastPathComponent
            kmlFile.filePath = self.savedLocation!
            kmlFile.isCompressed = self.savedLocation!.lastPathComponent.hasSuffix(".kmz")
            kmlFile.visible = true
            
            do {
                TAKLogger.debug("[KMLImporter] KML Parsed - storing DB record")
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[StreamParser] Invalid Data Context Save \(error)")
                return
            }
        }
    }
    
    private func parseFile() {
        guard let savedLocation = savedLocation else {
            TAKLogger.debug("[KMLImporter] No files saved so unable to parse KML")
            return
        }
        do {
            let data = try Data(contentsOf: savedLocation)
            if let kmlString = String(data: data, encoding: .utf8) {
                TAKLogger.debug("[KMLImporter] Starting parse of KML File")
                kmlParser.parse(kmlString: kmlString)
            }
        } catch {
            TAKLogger.error("[KMLImporter] Error parsing file: \(error)")
        }
    }
    
    private func copyFile() {
        TAKLogger.debug("[KMLImporter] Preparing to copy file")
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let overlaysURL = documentsURL.appendingPathComponent("overlays")
            let fileName = archiveLocation.lastPathComponent
            let overlayFileURL = overlaysURL.appendingPathComponent(fileName)
            let data = try Data(contentsOf: archiveLocation)
            try data.write(to: overlayFileURL)
            savedLocation = overlayFileURL
        } catch {
            TAKLogger.error("[KMLImporter] Error copying file: \(error)")
        }
        TAKLogger.debug("[KMLImporter] File copy complete")
    }
    
    private func createDirectoryIfNeeded() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let overlaysURL = documentsURL.appendingPathComponent("overlays")

        do {
            try FileManager.default.createDirectory(at: overlaysURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            TAKLogger.error("[KMLImporter] Error creating directory: \(error)")
        }
    }
}
