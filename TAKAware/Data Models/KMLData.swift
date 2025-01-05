//
//  KMLData.swift
//  TAKAware
//
//  Created by Cory Foy on 1/3/25.
//

import CoreData

class KMLData {
    let kmlRecord: KMLFile
    let overlayDirectory = AppConstants.appDirectoryFor(.overlays)
    var placemarks: [KMLPlacemark] = []
    
    init(kmlRecord: KMLFile) {
        self.kmlRecord = kmlRecord
        let filePath: URL!
        guard let fileId = kmlRecord.id else {
            TAKLogger.error("[KMLData] KMLRecord had no ID. Not processing file")
            return
        }
        
        if kmlRecord.isCompressed {
            do {
                let fileManager = FileManager()
                let kmzDirectory = overlayDirectory.appending(path: fileId.uuidString)
                let kmzPaths = try fileManager.contentsOfDirectory(atPath: kmzDirectory.relativePath)
                let kmlPath = kmzPaths.first(where: { $0.hasSuffix(".kml") })
                if kmlPath == nil {
                    TAKLogger.error("[KMLData] No KMLs found in the KMZ directory \(kmzDirectory.relativePath)")
                    return
                }
                filePath = kmzDirectory.appending(path: kmlPath!)
            } catch {
                TAKLogger.error("[KMLData] Unable to retrieve files from KMZ path \(error)")
                return
            }
        } else if kmlRecord.filePath != nil {
            filePath = kmlRecord.filePath!
        } else {
            TAKLogger.debug("[KMLData] KMLRecord had no file path")
            return
        }
        
        guard let data = try? Data(contentsOf: filePath) else {
            // TODO: Maybe notify the user or update the KML UI?
            // This is a rare case, usually only during development
            TAKLogger.debug("[KMLData] Unable to load KML from \(filePath.path())")
            return
        }
        
        if let string = String(data: data, encoding: .utf8) {
            let parser = KMLParser()
            parser.parse(kmlString: string)
            self.placemarks = parser.placemarks
        } else {
            TAKLogger.error("[MapView] Unable to decode KML from file")
        }
    }
}
