//
//  KMLParser.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import SWXMLHash
import SwiftTAK
import MapKit

struct KMLStyle: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer?
    var id: String = ""
    
    var iconStyle: KMLIconStyle? {
        guard let node = node else { return nil }
        do {
            return try node["IconStyle"].value()
        } catch {}
        return nil
    }
    
    var labelStyle: KMLLabelStyle? {
        guard let node = node else { return nil }
        do {
            return try node["LabelStyle"].value()
        } catch {}
        return nil
    }
    
    var lineStyle: KMLLineStyle? {
        guard let node = node else { return nil }
        do {
            return try node["LineStyle"].value()
        } catch {}
        return nil
    }
    
    var polygonStyle: KMLPolyStyle? {
        guard let node = node else { return nil }
        do {
            return try node["PolyStyle"].value()
        } catch {}
        return nil
    }
    
    public static func ==(lhs: KMLStyle, rhs: KMLStyle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLStyle {
        let id = try? node.value(ofAttribute: "id") as String
        return KMLStyle(node: node, id: id ?? "")
    }
}

struct KMLIconStyle: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer?
    var id: String = ""
    var color: String = ""
    var colorMode: String = "normal"
    var scale: Double = 1.0
    var heading: Double = 0.0
    
    var icon: KMLIcon? {
        guard let node = node else { return nil }
        do {
            return try node["Icon"].value()
        } catch {}
        return nil
    }
    
    public static func ==(lhs: KMLIconStyle, rhs: KMLIconStyle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLIconStyle {
        let id = try? node.value(ofAttribute: "id") as String
        let color = try? node["color"].value() as String
        let colorMode = try? node["colorMode"].value() as String
        let scale = try? node["scale"].value() as Double
        let heading = try? node["heading"].value() as Double
        return KMLIconStyle(
            node: node,
            id: id ?? "",
            color: color ?? "",
            colorMode: colorMode ?? "normal",
            scale: scale ?? 1.0,
            heading: heading ?? 0.0
        )
    }
}

struct KMLLabelStyle: Equatable, XMLObjectDeserialization {
    var id: String = ""
    var color: String = ""
    var colorMode: String = "normal"
    var scale: Double = 1.0
    
    public static func ==(lhs: KMLLabelStyle, rhs: KMLLabelStyle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLLabelStyle {
        let id = try? node.value(ofAttribute: "id") as String
        let color = try? node["color"].value() as String
        let colorMode = try? node["colorMode"].value() as String
        let scale = try? node["scale"].value() as Double
        return KMLLabelStyle(
            id: id ?? "",
            color: color ?? "",
            colorMode: colorMode ?? "normal",
            scale: scale ?? 1.0
        )
    }
}

struct KMLLineStyle: Equatable, XMLObjectDeserialization {
    var id: String = ""
    var color: String = ""
    var colorMode: String = "normal"
    var width: Double = 1.0
    
    public static func ==(lhs: KMLLineStyle, rhs: KMLLineStyle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLLineStyle {
        let id = try? node.value(ofAttribute: "id") as String
        let color = try? node["color"].value() as String
        let colorMode = try? node["colorMode"].value() as String
        let width = try? node["width"].value() as Double
        return KMLLineStyle(
            id: id ?? "",
            color: color ?? "",
            colorMode: colorMode ?? "normal",
            width: width ?? 1.0
        )
    }
}

struct KMLPolyStyle: Equatable, XMLObjectDeserialization {
    var id: String = ""
    var color: String = ""
    var colorMode: String = "normal"
    var fill: Bool = false
    var outline: Bool = true
    
    public static func ==(lhs: KMLPolyStyle, rhs: KMLPolyStyle) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLPolyStyle {
        let id = try? node.value(ofAttribute: "id") as String
        let color = try? node["color"].value() as String
        let colorMode = try? node["colorMode"].value() as String
        let fill = try? node["fill"].value() as Bool
        let outline = try? node["outline"].value() as Bool
        return KMLPolyStyle(
            id: id ?? "",
            color: color ?? "",
            colorMode: colorMode ?? "normal",
            fill: fill ?? false,
            outline: outline ?? true
        )
    }
}

struct KMLPoint: Equatable, XMLObjectDeserialization {
    var id: String
    var coordinates: String
    var extrude: Bool
    var altitudeMode: String
    
    var mapCoordinate: CLLocationCoordinate2D? {
        let coordArray = coordinates.split(separator: ",")
        guard coordArray.count >= 2 else { return nil }
        let lon = Double(coordArray[0]) ?? 0.0
        let lat = Double(coordArray[1]) ?? 0.0
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    public static func ==(lhs: KMLPoint, rhs: KMLPoint) -> Bool {
        return lhs.coordinates == rhs.coordinates &&
            lhs.extrude == rhs.extrude &&
            lhs.altitudeMode == rhs.altitudeMode
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLPoint {
        let id = try? node.value(ofAttribute: "id") as String
        let coordinates = try? node["coordinates"].value() as String
        let extrude = try? node["extrude"].value() as Bool
        let altitudeMode = try? node["altitudeMode"].value() as String
        
        return KMLPoint(
            id: id ?? "",
            coordinates: coordinates ?? "",
            extrude: extrude ?? false,
            altitudeMode: altitudeMode ?? "clampToGround"
        )
    }
}

struct KMLLineString: Equatable, XMLObjectDeserialization {
    var id: String
    var coordinates: String
    var extrude: Bool
    var tessellate: Bool
    var altitudeMode: String
    
    var mapCoordinates: [CLLocationCoordinate2D] {
        let coordTupleArray = coordinates.split(separator: " ").filter { !$0.isEmpty }
        guard coordTupleArray.count >= 2 else { return [] }
        let mappedCoordinates: [CLLocationCoordinate2D] = coordTupleArray.map { tuple in
            let coordArray = tuple.split(separator: ",")
            if coordArray.count < 2 {
                TAKLogger.debug("[KMLParser] unable to split coordinates \(tuple), returning 0,0")
                return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            }
            let lon = Double(coordArray[0]) ?? 0.0
            let lat = Double(coordArray[1]) ?? 0.0
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } as [CLLocationCoordinate2D]
        let filteredMappedCoordinates = mappedCoordinates.filter { $0.latitude != 0.0 && $0.longitude != 0.0 }
        if filteredMappedCoordinates.count < 2 {
            TAKLogger.debug("[KMLParser] No coordinates found after filtering")
            return []
        }
        return filteredMappedCoordinates
    }

    public static func ==(lhs: KMLLineString, rhs: KMLLineString) -> Bool {
        return lhs.coordinates == rhs.coordinates &&
            lhs.extrude == rhs.extrude &&
            lhs.tessellate == rhs.tessellate &&
            lhs.altitudeMode == rhs.altitudeMode
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLLineString {
        let id = try? node.value(ofAttribute: "id") as String
        let coordinates = try? node["coordinates"].value() as String
        let extrude = try? node["extrude"].value() as Bool
        let altitudeMode = try? node["altitudeMode"].value() as String
        let tessellate = try? node["tessellate"].value() as Bool
        
        return KMLLineString(
            id: id ?? "",
            coordinates: coordinates ?? "",
            extrude: extrude ?? false,
            tessellate: tessellate ?? true,
            altitudeMode: altitudeMode ?? "clampToGround"
        )
    }
}

struct KMLLinearRing: Equatable, XMLObjectDeserialization {
    var id: String
    var coordinates: String
    var extrude: Bool
    var tessellate: Bool
    var altitudeMode: String
    
    var mapCoordinates: [CLLocationCoordinate2D] {
        let coordTupleArray = coordinates.split(separator: " ").filter { !$0.isEmpty }
        guard coordTupleArray.count >= 2 else { return [] }
        let mappedCoordinates: [CLLocationCoordinate2D] = coordTupleArray.map { tuple in
            let coordArray = tuple.split(separator: ",")
            if coordArray.count < 2 {
                TAKLogger.debug("[KMLParser] unable to split coordinates \(tuple), returning 0,0")
                return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            }
            let lon = Double(coordArray[0]) ?? 0.0
            let lat = Double(coordArray[1]) ?? 0.0
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } as [CLLocationCoordinate2D]
        let filteredMappedCoordinates = mappedCoordinates.filter { $0.latitude != 0.0 && $0.longitude != 0.0 }
        if filteredMappedCoordinates.count < 2 {
            TAKLogger.debug("[KMLParser] No coordinates found after filtering")
            return []
        }
        return filteredMappedCoordinates
    }

    public static func ==(lhs: KMLLinearRing, rhs: KMLLinearRing) -> Bool {
        return lhs.coordinates == rhs.coordinates &&
            lhs.extrude == rhs.extrude &&
            lhs.tessellate == rhs.tessellate &&
            lhs.altitudeMode == rhs.altitudeMode
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLLinearRing {
        let id = try? node.value(ofAttribute: "id") as String
        let coordinates = try? node["coordinates"].value() as String
        let extrude = try? node["extrude"].value() as Bool
        let altitudeMode = try? node["altitudeMode"].value() as String
        let tessellate = try? node["tessellate"].value() as Bool
        
        return KMLLinearRing(
            id: id ?? "",
            coordinates: coordinates ?? "",
            extrude: extrude ?? false,
            tessellate: tessellate ?? true,
            altitudeMode: altitudeMode ?? "clampToGround"
        )
    }
}

struct KMLPolygon: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer? = nil
    var id: String
    var extrude: Bool
    var tessellate: Bool
    var altitudeMode: String
    
    var outerLinearRing: KMLLinearRing? {
        guard let node = node else { return nil }
        do {
            return try node["outerBoundaryIs"]["LinearRing"].value()
        } catch {}
        return nil
    }
    
    var innerLinearRings: [KMLLinearRing] {
        guard let node = node else { return [] }
        let innerBoundaryNodes = node["innerBoundaryIs"].all
        do {
            return try innerBoundaryNodes.map { node in
                try node["LinearRing"].value() as KMLLinearRing
            }
        }
        catch {}
        return []
    }

    public static func ==(lhs: KMLPolygon, rhs: KMLPolygon) -> Bool {
        return lhs.extrude == rhs.extrude &&
            lhs.tessellate == rhs.tessellate &&
            lhs.altitudeMode == rhs.altitudeMode
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLPolygon {
        let id = try? node.value(ofAttribute: "id") as String
        let extrude = try? node["extrude"].value() as Bool
        let altitudeMode = try? node["altitudeMode"].value() as String
        let tessellate = try? node["tessellate"].value() as Bool
        
        return KMLPolygon(
            node: node,
            id: id ?? "",
            extrude: extrude ?? false,
            tessellate: tessellate ?? true,
            altitudeMode: altitudeMode ?? "clampToGround"
        )
    }
}

struct KMLMultiGeometry: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer? = nil

    public static func ==(lhs: KMLMultiGeometry, rhs: KMLMultiGeometry) -> Bool {
        return lhs.node?.all.count == rhs.node?.all.count
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLMultiGeometry {
        return KMLMultiGeometry(
            node: node
        )
    }
    
    var mapKitShapes: [MKShape] {
        var shapes: [MKShape] = []
        shapes.append(contentsOf: points.compactMap { point in
            guard let coordinate = point.mapCoordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            return annotation
        })
        
        shapes.append(contentsOf: lineStrings.compactMap { lineString in
            let coordinates = lineString.mapCoordinates
            guard !coordinates.isEmpty else { return nil }
            return MKPolyline(coordinates: coordinates, count: coordinates.count)
        })
        
        shapes.append(contentsOf: linearRings.compactMap { linearRing in
            let coordinates = linearRing.mapCoordinates
            guard !coordinates.isEmpty else { return nil }
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        })
        
        shapes.append(contentsOf: polygons.compactMap { polygon in
            guard let outerCoordinates = polygon.outerLinearRing?.mapCoordinates else { return nil }
            
            let innerShapes: [MKPolygon] = polygon.innerLinearRings.map { linearRing in
                let coords = linearRing.mapCoordinates
                return MKPolygon(coordinates: coords, count: coords.count)
            }
            
            return MKPolygon(coordinates: outerCoordinates, count: outerCoordinates.count, interiorPolygons: innerShapes)
        })
        return shapes
    }
    
    var points: [KMLPoint] {
        guard let node = node else { return [] }
        do {
            let pointNodes = try node.byKey("Point")
            let kmlPoints = try pointNodes.all.map { try $0.value() as KMLPoint }
            return kmlPoints
        } catch {}
        return []
    }
    
    var lineStrings: [KMLLineString] {
        guard let node = node else { return [] }
        do {
            let lineStringNodes = try node.byKey("LineString")
            let kmlLineStrings = try lineStringNodes.all.map { try $0.value() as KMLLineString }
            return kmlLineStrings
        } catch {}
        return []
    }
    
    var linearRings: [KMLLinearRing] {
        guard let node = node else { return [] }
        do {
            let linearRingNodes = try node.byKey("LinearRing")
            let kmlLinearRings = try linearRingNodes.all.map { try $0.value() as KMLLinearRing }
            return kmlLinearRings
        } catch {}
        return []
    }
    
    var polygons: [KMLPolygon] {
        guard let node = node else { return [] }
        do {
            let polygons = try node.byKey("Polygon")
            let kmlPolygons = try polygons.all.map { try $0.value() as KMLPolygon }
            return kmlPolygons
        } catch {}
        return []
    }
}

struct KMLPlacemark: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer? = nil
    var name: String = ""
    var description: String = ""
    var visibility: Bool = true
    // TODO: Future StyleSelector Support: StyleMap
    // TODO: Future Geometry Support: GeometryCollection, Model, gx:Track, gx:MultiTrack
    
    var coordinate: CLLocationCoordinate2D {
        mapKitShapes.first?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    var mapKitShapes: [MKShape] {
        if let multiGeometry = multiGeometry {
            return multiGeometry.mapKitShapes
        } else if let mapKitShape = mapKitShape {
            return [mapKitShape]
        } else {
            return []
        }
    }
    
    private var mapKitShape: MKShape? {
        if let point = point {
            guard let coordinate = point.mapCoordinate else { return nil }
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            return annotation
        } else if let lineString = lineString {
            let coordinates = lineString.mapCoordinates
            guard !coordinates.isEmpty else { return nil }
            return MKPolyline(coordinates: coordinates, count: coordinates.count)
        } else if let polygon = polygon {
            guard let outerCoordinates = polygon.outerLinearRing?.mapCoordinates else { return nil }
            
            let innerShapes: [MKPolygon] = polygon.innerLinearRings.map { linearRing in
                let coords = linearRing.mapCoordinates
                return MKPolygon(coordinates: coords, count: coords.count)
            }
            
            return MKPolygon(coordinates: outerCoordinates, count: outerCoordinates.count, interiorPolygons: innerShapes)
        } else if let linearRing = linearRing {
            let coordinates = linearRing.mapCoordinates
            guard !coordinates.isEmpty else { return nil }
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        }
        return nil
    }
    
    var multiGeometry: KMLMultiGeometry? {
        guard let node = node else { return nil }
        do {
            return try node["MultiGeometry"].value()
        } catch {}
        return nil
    }
    
    var point: KMLPoint? {
        guard let node = node else { return nil }
        do {
            return try node["Point"].value()
        } catch {}
        return nil
    }
    
    var lineString: KMLLineString? {
        guard let node = node else { return nil }
        do {
            return try node["LineString"].value()
        } catch {}
        return nil
    }
    
    var linearRing: KMLLinearRing? {
        guard let node = node else { return nil }
        do {
            return try node["LinearRing"].value()
        } catch {}
        return nil
    }
    
    var polygon: KMLPolygon? {
        guard let node = node else { return nil }
        do {
            return try node["Polygon"].value()
        } catch {}
        return nil
    }
    
    var styles: [KMLStyle] {
        guard let node = node else { return [] }
        let styleNodes = node["Style"].all
        do {
            return try styleNodes.map { node in
                try node.value() as KMLStyle
            }
        }
        catch {}
        return []
    }
    
    public static func ==(lhs: KMLPlacemark, rhs: KMLPlacemark) -> Bool {
        return lhs.name == rhs.name &&
            lhs.description == rhs.description
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLPlacemark {
        let name = try? node["name"].value() as String
        let description = try? node["description"].value() as String
        return KMLPlacemark(
            node: node,
            name: name ?? "UNKNOWN",
            description: description ?? ""
        )
    }
}

struct KMLDocument: XMLObjectDeserialization {
    var node: XMLIndexer? = nil
    var name: String = ""
    var description: String = ""
    
    var styles: [KMLStyle] {
        guard let node = node else { return [] }
        let styleNodes = node["Style"].all
        do {
            return try styleNodes.map { node in
                try node.value() as KMLStyle
            }
        }
        catch {}
        return []
    }
    
    var placemarks: [KMLPlacemark] {
        guard let node = node else { return [] }
        let placemarkNodes = node["Placemark"].all
        do {
            return try placemarkNodes.map { node in
                try node.value() as KMLPlacemark
            }
        }
        catch {}
        return []
    }
    
    var groundOverlays: [KMLGroundOverlay] {
        guard let node = node else { return [] }
        let groundOverlayNodes = node["GroundOverlay"].all
        do {
            return try groundOverlayNodes.map { node in
                try node.value() as KMLGroundOverlay
            }
        }
        catch {}
        return []
    }
    
    var folders: [KMLFolder] {
        guard let node = node else { return [] }
        let folderNodes = node["Folder"].all
        do {
            return try folderNodes.map { node in
                try node.value() as KMLFolder
            }
        }
        catch {}
        return []
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLDocument {
        let name = try? node["name"].value() as String
        let description = try? node["description"].value() as String
        return KMLDocument(
            node: node,
            name: name ?? "",
            description: description ?? ""
        )
    }
}

struct KMLFolder: XMLObjectDeserialization {
    var node: XMLIndexer? = nil
    var name: String = ""

    var placemarks: [KMLPlacemark] {
        guard let node = node else { return [] }
        let placemarkNodes = node["Placemark"].all
        do {
            return try placemarkNodes.map { node in
                try node.value() as KMLPlacemark
            }
        }
        catch {}
        return []
    }
    
    var groundOverlays: [KMLGroundOverlay] {
        guard let node = node else { return [] }
        let groundOverlayNodes = node["GroundOverlay"].all
        do {
            return try groundOverlayNodes.map { node in
                try node.value() as KMLGroundOverlay
            }
        }
        catch {}
        return []
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLFolder {
        let name = try? node["name"].value() as String
        return KMLFolder(
            node: node,
            name: name ?? "UNKNOWN"
        )
    }
}

struct KMLIcon: Equatable, XMLObjectDeserialization {
    var href: String = ""
    var viewBoundScale: Double = 1.0
    
    public static func ==(lhs: KMLIcon, rhs: KMLIcon) -> Bool {
        return lhs.href == rhs.href &&
            lhs.viewBoundScale == rhs.viewBoundScale
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLIcon {
        let href = try? node["href"].value() as String
        let viewBoundScale = try? node["viewBoundScale"].value() as Double
        return KMLIcon(
            href: href ?? "",
            viewBoundScale: viewBoundScale ?? 1.0
        )
    }
}

struct KMLLatLonBox: Equatable, XMLObjectDeserialization {
    var north: Double = 0.0
    var south: Double = 0.0
    var east: Double = 0.0
    var west: Double = 0.0
    var rotation: Double = 0.0
    
    public static func ==(lhs: KMLLatLonBox, rhs: KMLLatLonBox) -> Bool {
        return lhs.north == rhs.north &&
            lhs.south == rhs.south &&
            lhs.east == rhs.east &&
            lhs.west == rhs.west &&
            lhs.rotation == rhs.rotation
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLLatLonBox {
        let north = try? node["north"].value() as Double
        let south = try? node["south"].value() as Double
        let east = try? node["east"].value() as Double
        let west = try? node["west"].value() as Double
        let rotation = try? node["rotation"].value() as Double
        return KMLLatLonBox(
            north: north ?? 0.0,
            south: south ?? 0.0,
            east: east ?? 0.0,
            west: west ?? 0.0,
            rotation: rotation ?? 0.0
        )
    }
}

struct KMLGoogleLatLonQuad: Equatable, XMLObjectDeserialization {
    var coordinates: String
    public static func ==(lhs: KMLGoogleLatLonQuad, rhs: KMLGoogleLatLonQuad) -> Bool {
        return lhs.coordinates == rhs.coordinates
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLGoogleLatLonQuad {
        let coords = try? node["coordinates"].value() as String
        return KMLGoogleLatLonQuad(
            coordinates: coords ?? ""
        )
    }
}

struct KMLGroundOverlay: Equatable, XMLObjectDeserialization {
    var node: XMLIndexer? = nil
    var name: String = ""
    var visibility: Bool = true
    var altitude: Double = 0.0
    var altitudeMode: String = "clampToGround"
    
    var icon: KMLIcon? {
        guard let node = node else { return nil }
        do {
            return try node["Icon"].value()
        } catch {}
        return nil
    }
    
    // Specifies where the top, bottom, right, and left sides of a bounding box for the ground overlay are aligned. 
    var latLonBox: KMLLatLonBox? {
        guard let node = node else { return nil }
        do {
            return try node["LatLonBox"].value()
        } catch {}
        return nil
    }
    
    // Specifies the coordinates of the four corner points of a quadrilateral defining the overlay area
    var latLonQuad: KMLGoogleLatLonQuad? {
        guard let node = node else { return nil }
        do {
            return try node["gx:LatLonQuad"].value()
        } catch {}
        return nil
    }
    
    public static func ==(lhs: KMLGroundOverlay, rhs: KMLGroundOverlay) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func deserialize(_ node: XMLIndexer) throws -> KMLGroundOverlay {
        let name = try? node["name"].value() as String
        let visibility = try? node["visibility"].value() as Bool
        let altitude = try? node["altitude"].value() as Double
        let altitudeMode = try? node["altitudeMode"].value() as String

        return KMLGroundOverlay(
            node: node,
            name: name ?? "",
            visibility: visibility ?? true,
            altitude: altitude ?? 0.0,
            altitudeMode: altitudeMode ?? "clampToGround"
        )
    }
}

class KMLParser {
    var placemarks: [KMLPlacemark] = []
    var groundOverlays: [KMLGroundOverlay] = []
    var document: KMLDocument? = nil
    
    func parse(kmlString: String) {
        let kml = XMLHash.parse(kmlString)
        let kmlRoot = kml["kml"]
        
        let placemarkElements = kmlRoot["Placemark"].all
        placemarkElements.forEach { placemarkXml in
            do {
                try placemarks.append(placemarkXml.value())
            } catch {}
        }
        
        let groundOverlayElements = kmlRoot["GroundOverlay"].all
        groundOverlayElements.forEach { groundOverlayXml in
            do {
                try groundOverlays.append(groundOverlayXml.value())
            } catch {}
        }
        
        let folderElements = kmlRoot["Folder"].all
        folderElements.forEach { folderXml in
            do {
                let folder: KMLFolder = try folderXml.value()
                placemarks.append(contentsOf: folder.placemarks)
                groundOverlays.append(contentsOf: folder.groundOverlays)
            } catch {}
        }
        
        let documentElements = kmlRoot["Document"].all
        documentElements.forEach { documentXml in
            do {
                let documentKml: KMLDocument = try documentXml.value()
                if self.document == nil {
                    self.document = documentKml // Only take the first document in the case of multiples
                }
                placemarks.append(contentsOf: documentKml.placemarks)
                groundOverlays.append(contentsOf: documentKml.groundOverlays)
                documentKml.folders.forEach { folder in
                    placemarks.append(contentsOf: folder.placemarks)
                    groundOverlays.append(contentsOf: folder.groundOverlays)
                }
            } catch {}
        }
    }
}
