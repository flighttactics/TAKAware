//
//  MapSourceImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 2/17/25.
//

import Foundation
import CoreData

class MapSourceImporter: COTDataParser {
    var mapSourceLocation: URL
    var fileName: String
    var mapSourceParser: MapSourceParser
    var hasFailure = false
    
    init(fileLocation: URL) {
        self.mapSourceLocation = fileLocation
        fileName = fileLocation.lastPathComponent
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
        do {
            let data = try Data(contentsOf: mapSourceLocation)
            if let mapString = String(data: data, encoding: .utf8) {
                TAKLogger.debug("[MapSourceImporter] Starting parse of Map Source")
                mapSourceParser.parse(mapSourceString: mapString)
                if mapSourceParser.parsedMapSource == nil {
                    hasFailure = true
                }
            } else {
                hasFailure = true
            }
        } catch {
            hasFailure = true
            TAKLogger.error("[MapSourceImporter] Error parsing file: \(error)")
        }
    }
    
    private func storeFile() {
        guard !hasFailure, let parsedMapSource = mapSourceParser.parsedMapSource else { return }
        var mapSource: MapSource = MapSource(context: self.dataContext)
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
