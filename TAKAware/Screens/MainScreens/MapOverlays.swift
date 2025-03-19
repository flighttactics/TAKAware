//
//  MapOverlays.swift
//  TAKAware
//
//  Created by Cory Foy on 2/21/25.
//  Parts of overzoom adapted from https://stackoverflow.com/a/69148976
//

// TODO: Modify this to be able to pull from uploaded MBTile files
// TODO: Does this matter if it's an actual offline map vs image overlay?

import Foundation
import SQLite
import MapKit
import UIKit

class OfflineTileLoadError: Error {}

class OfflineTileOverlay : MKTileOverlay {
    let cache = NSCache<AnyObject, AnyObject>()
    let dbUrl: URL
    var connection: Connection?
    let metadataTable = Table("metadata")
    let tilesTable = Table("tiles")
    
    let metaNameCol = SQLite.Expression<String>("name")
    let metaValueCol = SQLite.Expression<String>("value")
    
    let zoomLevelCol = SQLite.Expression<Int>("zoom_level")
    let tileColumnCol = SQLite.Expression<Int>("tile_column")
    let tileRowCol = SQLite.Expression<Int>("tile_row")
    let tileImageCol = SQLite.Expression<Blob>("tile_data")
    
    var minZoom: Int = 0
    var maxZoom: Int = 0
    
    func zoomScaleToZoomLevel(_ scale: MKZoomScale) -> Int {
        let numTilesAt1_0 = MKMapSize.world.width / tileSize.width
        let zoomLevelAt1_0 = log2(numTilesAt1_0) // add 1 because the convention skips a virtual level with 1 tile.
        let zoomLevel = Int(max(0, zoomLevelAt1_0 + floor(Double(log2f(Float(scale))) + 0.5)))
        return zoomLevel
    }
    
//    override var tileSize: CGSize {
//        set {}
//        get { return CGSize(width: 256.0, height: 256.0) }
//    }
    
    override init(urlTemplate: String?) {
        do {
            dbUrl = Bundle.main.url(forResource: "hydrant_raster_18_meta4", withExtension: "mbtiles")!
            connection = try Connection(dbUrl.absoluteString, readonly: true)
        } catch {
            TAKLogger.error("[OfflineTileOverlay] Unable to load data store. Defaulting all tiles")
            TAKLogger.error("[OfflineTileOverlay] \(error)")
        }
        super.init(urlTemplate: urlTemplate)
        self.minimumZ = 18
        self.maximumZ = 31
        
        // Get these from the database
        minZoom = 18
        maxZoom = 18
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        return URL(string: String(format: "http://takaware/%i/%i/%i.png", path.z, path.x, path.y))!
    }
    
    func tiles(in rect: MKMapRect, zoomScale scale: MKZoomScale) -> [ImageTile]? {
        guard connection != nil else { return [] }
        var z = zoomScaleToZoomLevel(scale)
        
        // OverZoom Mode - Detect when we are zoomed beyond the tile set.
        var overZoom = 1
        let zoomCap = maxZoom

        if z > zoomCap {
            // overZoom progression: 1, 2, 4, 8, etc...
            overZoom = Int(pow(2, Double(z - zoomCap)))
            z = zoomCap
        }
        
        // When we are zoomed in beyond the tile set, use the tiles
        // from the maximum z-depth, but render them larger.
        let adjustedTileSize = overZoom * Int(tileSize.width)
        
        // Number of tiles wide or high (but not wide * high)
        // let tilesAtZ = Int(pow(2, Double(z)))
        
        let minX = Int(floor((rect.minX * Double(scale)) / Double(adjustedTileSize)))
        let maxX = Int(floor((rect.maxX * Double(scale)) / Double(adjustedTileSize)))
        let minY = Int(floor((rect.minY * Double(scale)) / Double(adjustedTileSize)))
        let maxY = Int(floor((rect.maxY * Double(scale)) / Double(adjustedTileSize)))
        var tiles: [ImageTile] = []
        
        for x in minX...maxX {
            for y in minY...maxY {
                let yRow = Int(truncating: NSDecimalNumber(decimal: pow(2.0, z))) - y - 1

                let query: QueryType = tilesTable
                    .filter(tileColumnCol == x)
                    .filter(tileRowCol == yRow)
                    .filter(zoomLevelCol == z)

                do {
                    if let row = try connection!.pluck(query) {
                        let dataBytes = try Data.fromDatatypeValue(row.get(tileImageCol))
                        let frame = MKMapRect(
                            x: Double(x * adjustedTileSize) / Double(scale),
                            y: Double(y * adjustedTileSize) / Double(scale),
                            width: Double(CGFloat(adjustedTileSize) / scale),
                            height: Double(CGFloat(adjustedTileSize) / scale))
                        let tile = ImageTile(frame: frame, path: "", imgData: dataBytes)
                        tiles.append(tile)
                    }
                } catch {
                    TAKLogger.error("[OfflineTileOverlay] Error retrieving tile \(error)")
                }
            }
            
        }
        return tiles
        
    }
    
    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        guard connection != nil else { throw OfflineTileLoadError() }
        //KEY for caching
        //let url: String = String(path.x) + "-" + String(path.y) + "-" + String(path.z)
        
        // These are the min/max X/Y for the lowest view level in the DB
        let minLevelGridMinX = 45384 //min col
//        let minLevelGridMinY = 157280 //min row
//        let minLevelGridMaxX = 45468 //min col
//        let minLevelGridMaxY = 157339 //min row
        
        let numAvailableLevels = 1
//        let maxLevel = minLevel + numAvailableLevels - 1
        let gridOffsetX = (minLevelGridMinX<<(numAvailableLevels-1))
//        let gridOffsetY = (minLevelGridMinX<<(numAvailableLevels-1))

        
        //MAP
        let col : NSInteger = path.x
        let row : NSInteger = path.y
        let zoom : NSInteger = path.z
        
        let yRow = Int(truncating: NSDecimalNumber(decimal: pow(2.0, zoom))) - row - 1
        //var yRow = row + (gridOffsetY>>zoom)
        let xCol = col + (gridOffsetX>>zoom)

        //print("Z\(zZoom) - R\(yRow) - C\(xCol)")
        
        //int column = ((int) (pow(2, zoom) - y) - 1);
        
        let query: QueryType = tilesTable
            .filter(tileColumnCol == xCol)
            .filter(tileRowCol == yRow)
            .filter(zoomLevelCol == zoom)

        do {
            if let row = try connection!.pluck(query) {
                let dataBytes = try Data.fromDatatypeValue(row.get(tileImageCol))
                return dataBytes
            }
        } catch {
            TAKLogger.error("[OfflineTileOverlay] Error retrieving tile \(error)")
        }
        throw OfflineTileLoadError()
    }
}

struct ImageTile {
    let frame: MKMapRect
    let path: String
    let imgData: Data?
}

class TileOverlayRenderer: MKOverlayRenderer {
    
    override func draw(
        _ mapRect: MKMapRect,
        zoomScale: MKZoomScale,
        in context: CGContext
    ) {
        
        guard let tileOverlay = overlay as? OfflineTileOverlay else { return }

        // OverZoom Mode - Detect when we are zoomed beyond the tile set.
        let z = tileOverlay.zoomScaleToZoomLevel(zoomScale)
        var overZoom = 1
        let zoomCap = tileOverlay.maxZoom
        
        if z > zoomCap {
            // overZoom progression: 1, 2, 4, 8, etc...
            overZoom = Int(pow(2, Double(z - zoomCap)))
        }
        
        // Get the list of tile images from the model object for this mapRect.  The
        // list may be 1 or more images (but not 0 because canDrawMapRect would have
        // returned NO in that case).
        
        let tilesInRect = tileOverlay.tiles(in: mapRect, zoomScale: zoomScale)
        let tileAlpha: CGFloat = 1
        context.setAlpha(tileAlpha)
        
        for tile in tilesInRect ?? [] {
            // For each image tile, draw it in its corresponding MKMapRect frame
            let rect = self.rect(for: tile.frame)
            let image = UIImage(data: tile.imgData!)
            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.minY)
            
            if let cgImage = image?.cgImage, let width = image?.size.width, let height = image?.size.height {
                // OverZoom mode - 1 when using tiles as is, 2, 4, 8 etc when overzoomed.
                context.scaleBy(x: CGFloat(CGFloat(overZoom) / zoomScale), y: CGFloat(CGFloat(overZoom) / zoomScale))
                context.translateBy(x: 0, y: image?.size.height ?? 0.0)
                context.scaleBy(x: 1, y: -1)
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                context.restoreGState()
            }
            
        }
    }
}
