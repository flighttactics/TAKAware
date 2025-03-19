//
//  MapSourceImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 2/17/25.
//

import Foundation
import CoreData

class MapSourceImporter: COTDataParser {
    var mapSourceLocation: URL?
    var mapSourceFileData: Data?
    var fileName: String
    var mapSourceParser: MapSourceParser
    var hasFailure = false
    
    init(fileLocation: URL) {
        self.mapSourceLocation = fileLocation
        self.mapSourceFileData = try? Data(contentsOf: fileLocation)
        fileName = fileLocation.lastPathComponent
        mapSourceParser = MapSourceParser()
    }
    
    init(mapName: String, fileData: Data) {
        self.mapSourceFileData = fileData
        fileName = mapName
        mapSourceParser = MapSourceParser()
    }
    
    func process() async -> Bool {
        TAKLogger.debug("[MapSourceImporter] Starting Map Source processing")
        await dataContext.perform {
            self.parseFile()
            self.storeFile()
        }
        TAKLogger.debug("[MapSourceImporter] Completed Map Source processing")
        return !self.hasFailure
    }
    
    private func parseFile() {
        guard !hasFailure else { return }
        guard mapSourceFileData != nil else {
            TAKLogger.error("[MapSourceImporter] Attempted to parse a map source without data")
            return
        }
        if let mapString = String(data: mapSourceFileData!, encoding: .utf8) {
            TAKLogger.debug("[MapSourceImporter] Starting parse of Map Source")
            mapSourceParser.parse(mapSourceString: mapString)
            if mapSourceParser.parsedMapSource == nil {
                hasFailure = true
            }
        } else {
            hasFailure = true
        }
    }
    
    private func storeFile() {
        guard !hasFailure, let parsedMapSource = mapSourceParser.parsedMapSource else { return }
        let mapSource: MapSource = MapSource(context: self.dataContext)
        mapSource.id = parsedMapSource.id
        mapSource.name = parsedMapSource.name
        mapSource.url = parsedMapSource.url
        mapSource.tileType = parsedMapSource.tileType
        mapSource.tileUpdate = parsedMapSource.tileUpdate
        mapSource.backgroundColor = parsedMapSource.backgroundColor
        mapSource.minZoom = parsedMapSource.minZoom
        mapSource.maxZoom = parsedMapSource.maxZoom
        mapSource.visible = parsedMapSource.visible
        mapSource.replacesContent = parsedMapSource.replacesContent
        
        do {
            TAKLogger.debug("[MapSourceImporter] Map Source Parsed - storing DB record")
            try self.dataContext.save()
        } catch {
            hasFailure = true
            TAKLogger.error("[MapSourceImporter] Invalid Data Context Save \(error)")
            return
        }
    }
}
