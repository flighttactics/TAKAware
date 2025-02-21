//
//  MapSourceParser.swift
//  TAKAware
//
//  Created by Cory Foy on 2/17/25.
//

import Foundation
import SWXMLHash

struct ParsedMapSource {
    var id: UUID
    var name: String
    var url: String
    var visible: Bool = false
    var replacesContent: Bool = true
    var minZoom: Int16 = 0
    var maxZoom: Int16 = 25
    var tileType: String = "png"
    var tileUpdate: String = "None"
    var backgroundColor: String = "#000000"
}

class MapSourceParser {
    var parsedMapSource: ParsedMapSource?
    
    func parse(mapSourceString: String) {
        let mapXml = XMLHash.parse(mapSourceString)
        let mapRoot = mapXml["customMapSource"]
        
        do {
            let name: String = try mapRoot["name"].value()
            let url: String = try mapRoot["url"].value()
            let minZoom: Int = try mapRoot["minZoom"].value()
            let maxZoom: Int = try mapRoot["maxZoom"].value()
            let tileType: String = try mapRoot["tileType"].value()
            let tileUpdate: String = try mapRoot["tileUpdate"].value()
            let backgroundColor: String = try mapRoot["backgroundColor"].value()
            
            parsedMapSource = ParsedMapSource(
                id: UUID(),
                name: name,
                url: url,
                minZoom: Int16(minZoom),
                maxZoom: Int16(maxZoom),
                tileType: tileType,
                tileUpdate: tileUpdate,
                backgroundColor: backgroundColor
            )
        } catch {
            TAKLogger.error("[MapSourceParser] Error while parsing map: \(error)")
        }
    }
}
