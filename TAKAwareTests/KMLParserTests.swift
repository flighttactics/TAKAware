//
//  KMLParserTests.swift
//  TAKAware
//
//  Created by Cory Foy on 12/20/24.
//

import Foundation
import SwiftTAK
import XCTest
@testable import TAKAware

final class KMLParserTests: TAKAwareTestCase {
    
    var parser: KMLParser!

    override func setUpWithError() throws {
        parser = KMLParser()
    }
    
    func testPlacemarksFoundInRootOfDoc() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        XCTAssertEqual(parser.placemarks.first?.name, "RootPlacemark")
        XCTAssertEqual(parser.placemarks.first?.description, "Hello, World")
    }
    
    func testPlacemarksFoundUnderDocumentRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Document Root</name>
    <description>Hello, Document Root</description>
    <Placemark>
        <description>Hello, World</description>
        <name>DocumentRootPlacemark</name>
    </Placemark>
</Document>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        XCTAssertEqual(parser.placemarks.first?.name, "DocumentRootPlacemark")
        XCTAssertEqual(parser.placemarks.first?.description, "Hello, World")
    }
    
    func testPlacemarksFoundUnderFolderRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Folder>
    <name>Folder Root</name>
    <Placemark>
        <description>Hello, World</description>
        <name>FolderRootPlacemark</name>
    </Placemark>
</Folder>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        XCTAssertEqual(parser.placemarks.first?.name, "FolderRootPlacemark")
        XCTAssertEqual(parser.placemarks.first?.description, "Hello, World")
    }
    
    func testPlacemarksFoundUnderFolderUnderDocumentRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Document Root</name>
    <description>Hello, Document Root</description>
    <Folder>
        <name>Folder Subroot</name>
        <Placemark>
            <description>Hello, World</description>
            <name>DocumentFolderRootPlacemark</name>
        </Placemark>
    </Folder>
</Document>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        XCTAssertEqual(parser.placemarks.first?.name, "DocumentFolderRootPlacemark")
        XCTAssertEqual(parser.placemarks.first?.description, "Hello, World")
    }
    
    func testPlacemarksPoint() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
    <Point id="1234P">
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>-78.34,26.45,97.5</coordinates>
    </Point>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        let placemarkPoint = parser.placemarks.first?.point
        XCTAssertEqual(placemarkPoint?.id, "1234P")
        XCTAssertEqual(placemarkPoint?.coordinates, "-78.34,26.45,97.5")
        XCTAssertEqual(placemarkPoint?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkPoint?.extrude, true)
        
    }
    
    func testPlacemarksLineString() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
    <LineString id="1234LS">
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>-78.34,26.45,97.5 -79.34,26.45,97.5</coordinates>
        <tessellate>0</tessellate>
    </LineString>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        let placemarkLineString = parser.placemarks.first?.lineString
        XCTAssertEqual(placemarkLineString?.id, "1234LS")
        XCTAssertEqual(placemarkLineString?.coordinates, "-78.34,26.45,97.5 -79.34,26.45,97.5")
        XCTAssertEqual(placemarkLineString?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkLineString?.extrude, true)
        XCTAssertEqual(placemarkLineString?.tessellate, false)
        
    }
    
    func testPlacemarksLinearRing() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
    <LinearRing id="1234LR">
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>-78.34,26.45,97.5 -78.45,26.55,97.5 -78.64,26.65,97.5</coordinates>
        <tessellate>0</tessellate>
    </LinearRing>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        let placemarkLinearRing = parser.placemarks.first?.linearRing
        XCTAssertEqual(placemarkLinearRing?.id, "1234LR")
        XCTAssertEqual(placemarkLinearRing?.coordinates, "-78.34,26.45,97.5 -78.45,26.55,97.5 -78.64,26.65,97.5")
        XCTAssertEqual(placemarkLinearRing?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkLinearRing?.extrude, true)
        XCTAssertEqual(placemarkLinearRing?.tessellate, false)
        
    }
    
    func testPlacemarksPolygonNoInnerBoundary() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
    <Polygon id="1234PG">
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <tessellate>0</tessellate>
        <outerBoundaryIs>
            <LinearRing id="1234LR">
                <extrude>1</extrude>
                <altitudeMode>absolute</altitudeMode>
                <coordinates>-78.34,26.45,97.5 -78.45,26.55,97.5 -78.64,26.65,97.5</coordinates>
                <tessellate>0</tessellate>
            </LinearRing>
        </outerBoundaryIs>
    </Polygon>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        let placemarkPolygon = parser.placemarks.first?.polygon
        XCTAssertEqual(placemarkPolygon?.id, "1234PG")
        XCTAssertEqual(placemarkPolygon?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkPolygon?.extrude, true)
        XCTAssertEqual(placemarkPolygon?.tessellate, false)
        
        let placemarkLinearRing = placemarkPolygon?.outerLinearRing
        XCTAssertEqual(placemarkLinearRing?.id, "1234LR")
        XCTAssertEqual(placemarkLinearRing?.coordinates, "-78.34,26.45,97.5 -78.45,26.55,97.5 -78.64,26.65,97.5")
        XCTAssertEqual(placemarkLinearRing?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkLinearRing?.extrude, true)
        XCTAssertEqual(placemarkLinearRing?.tessellate, false)
        
    }
    
    func testPlacemarksPolygonWithInnerBoundaries() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <description>Hello, World</description>
    <name>RootPlacemark</name>
    <Polygon id="1234IB">
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <tessellate>0</tessellate>
        <outerBoundaryIs>
            <LinearRing id="1234LRO">
                <extrude>1</extrude>
                <altitudeMode>absolute</altitudeMode>
                <coordinates>-78.34,26.45,97.5 -78.45,26.55,97.5 -77.64,26.65,97.5</coordinates>
                <tessellate>0</tessellate>
            </LinearRing>
        </outerBoundaryIs>
        <innerBoundaryIs>
            <LinearRing id="1234LRI1">
                <extrude>1</extrude>
                <altitudeMode>absolute</altitudeMode>
                <coordinates>-77.34,26.45,97.5 -77.45,26.55,97.5 -77.64,26.65,97.5</coordinates>
                <tessellate>0</tessellate>
            </LinearRing>
        </innerBoundaryIs>
        <innerBoundaryIs>
            <LinearRing id="1234LRI2">
                <extrude>1</extrude>
                <altitudeMode>absolute</altitudeMode>
                <coordinates>-76.34,26.45,97.5 -76.45,26.55,97.5 -76.64,26.65,97.5</coordinates>
                <tessellate>0</tessellate>
            </LinearRing>
        </innerBoundaryIs>
    </Polygon>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.count, 1)
        let placemarkPolygon = parser.placemarks.first?.polygon
        XCTAssertEqual(placemarkPolygon?.id, "1234IB")
        XCTAssertEqual(placemarkPolygon?.altitudeMode, "absolute")
        XCTAssertEqual(placemarkPolygon?.extrude, true)
        XCTAssertEqual(placemarkPolygon?.tessellate, false)
        
        let placemarkLinearRings = placemarkPolygon?.innerLinearRings
        XCTAssertEqual(placemarkLinearRings?.count, 2)
        
        let firstInnerRing = placemarkLinearRings?.first
        let secondInnerRing = placemarkLinearRings?.last
        XCTAssertEqual(firstInnerRing?.id, "1234LRI1")
        XCTAssertEqual(firstInnerRing?.coordinates, "-77.34,26.45,97.5 -77.45,26.55,97.5 -77.64,26.65,97.5")
        XCTAssertEqual(firstInnerRing?.altitudeMode, "absolute")
        XCTAssertEqual(firstInnerRing?.extrude, true)
        XCTAssertEqual(firstInnerRing?.tessellate, false)
        
        XCTAssertEqual(secondInnerRing?.id, "1234LRI2")
        XCTAssertEqual(secondInnerRing?.coordinates, "-76.34,26.45,97.5 -76.45,26.55,97.5 -76.64,26.65,97.5")
        XCTAssertEqual(secondInnerRing?.altitudeMode, "absolute")
        XCTAssertEqual(secondInnerRing?.extrude, true)
        XCTAssertEqual(secondInnerRing?.tessellate, false)
        
    }
    
    func testGroundOverlaysFoundInRootOfDoc() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<GroundOverlay>
    <name>RootGroundOverlay</name>
</GroundOverlay>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        XCTAssertEqual(parser.groundOverlays.first?.name, "RootGroundOverlay")
    }
    
    func testGroundOverlaysFoundUnderDocumentRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Document Root</name>
    <description>Hello, Document Root</description>
    <GroundOverlay>
        <name>DocumentRootGroundOverlay</name>
    </GroundOverlay>
</Document>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        XCTAssertEqual(parser.groundOverlays.first?.name, "DocumentRootGroundOverlay")
    }
    
    func testGroundOverlaysFoundUnderFolderRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Folder>
    <name>Folder Root</name>
    <GroundOverlay>
        <name>FolderRootGroundOverlay</name>
    </GroundOverlay>
</Folder>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        XCTAssertEqual(parser.groundOverlays.first?.name, "FolderRootGroundOverlay")
    }
    
    func testGroundOverlaysFoundUnderFolderUnderDocumentRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Document Root</name>
    <description>Hello, Document Root</description>
    <Folder>
        <name>Folder Subroot</name>
        <GroundOverlay>
            <name>DocumentFolderRootGroundOverlay</name>
        </GroundOverlay>
    </Folder>
</Document>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        XCTAssertEqual(parser.groundOverlays.first?.name, "DocumentFolderRootGroundOverlay")
    }
    
    func testGroundOverlayParsesIcon() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<GroundOverlay>
    <name>RootGroundOverlay</name>
    <Icon>
        <href>images/test.png</href>
        <viewBoundScale>0.75</viewBoundScale>
    </Icon>
</GroundOverlay>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        let expectedIcon = KMLIcon(href: "images/test.png", viewBoundScale: 0.75)
        XCTAssertEqual(expectedIcon, parser.groundOverlays.first?.icon)
    }
    
    func testGroundOverlayParsesLatLonBox() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<GroundOverlay>
    <name>RootGroundOverlay</name>
    <LatLonBox>
        <north>40.78</north>
        <south>40.73</south>
        <east>-73.95</east>
        <west>-73.46</west>
        <rotation>-29.14</rotation>
    </LatLonBox>
</GroundOverlay>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        let expectedLatLonBox = KMLLatLonBox(north: 40.78, south: 40.73, east: -73.95, west: -73.46, rotation: -29.14)
        XCTAssertEqual(expectedLatLonBox, parser.groundOverlays.first?.latLonBox)
    }
    
    func testGroundOverlayParsesLatLonQuad() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<GroundOverlay>
    <name>RootGroundOverlay</name>
    <gx:LatLonQuad>
        <coordinates>81.60,44.16 83.52,43.66 82.94,44.24 81.50,44.32</coordinates>
    </gx:LatLonQuad>
</GroundOverlay>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        let expectedLatLonQuad = KMLGoogleLatLonQuad(coordinates: "81.60,44.16 83.52,43.66 82.94,44.24 81.50,44.32")
        XCTAssertEqual(expectedLatLonQuad, parser.groundOverlays.first?.latLonQuad)
    }
    
    func testGroundOverlayParsesAttributes() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<GroundOverlay>
    <name>RootGroundOverlayAttrs</name>
    <visibility>0</visibility>
    <altitude>30.5</altitude>
    <altitudeMode>absolute</altitudeMode>
</GroundOverlay>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.groundOverlays.count, 1)
        let overlay = parser.groundOverlays.first
        XCTAssertEqual("RootGroundOverlayAttrs", overlay?.name)
        XCTAssertEqual(false, overlay?.visibility)
        XCTAssertEqual(30.5, overlay?.altitude)
        XCTAssertEqual("absolute", overlay?.altitudeMode)
    }
    
    func testStyleInDocumentRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Document Root</name>
    <description>Hello, Document Root</description>
    <Style id="1234S">
        <IconStyle>
          <color>a1ff00ff</color>
          <scale>1.399999976158142</scale>
          <Icon>
            <href>http://myserver.com/icon.jpg</href>
          </Icon>
        </IconStyle>
        <LabelStyle>
          <color>7fffaaff</color>
          <scale>1.5</scale>
        </LabelStyle>
        <LineStyle>
          <color>ff0000ff</color>
          <width>15</width>
        </LineStyle>
        <PolyStyle>
          <color>7f7faaaa</color>
          <colorMode>random</colorMode>
        </PolyStyle>
    </Style>
</Document>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.document?.styles.count, 1)
        let style = parser.document?.styles.first
        XCTAssertEqual("1234S", style?.id)
        let iconStyle = style?.iconStyle
        let labelStyle = style?.labelStyle
        let lineStyle = style?.lineStyle
        let polyStyle = style?.polygonStyle
        
        XCTAssertEqual("a1ff00ff", iconStyle?.color)
        XCTAssertEqual(1.399999976158142, iconStyle?.scale)
        XCTAssertEqual("http://myserver.com/icon.jpg", iconStyle?.icon?.href)
        
        XCTAssertEqual("7fffaaff", labelStyle?.color)
        XCTAssertEqual(1.5, labelStyle?.scale)
        
        XCTAssertEqual("ff0000ff", lineStyle?.color)
        XCTAssertEqual(15.0, lineStyle?.width)
        
        XCTAssertEqual("7f7faaaa", polyStyle?.color)
        XCTAssertEqual("random", polyStyle?.colorMode)
    }
    
    func testStyleInPlacemarkRoot() throws {
        let testKML = """
<?xml version="1.0"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
<Placemark>
    <name>Placemark Root</name>
    <description>Hello, Placemark Root</description>
    <Style id="1234S">
        <IconStyle>
          <color>a1ff00ff</color>
          <scale>1.399999976158142</scale>
          <Icon>
            <href>http://myserver.com/icon.jpg</href>
          </Icon>
        </IconStyle>
        <LabelStyle>
          <color>7fffaaff</color>
          <scale>1.5</scale>
        </LabelStyle>
        <LineStyle>
          <color>ff0000ff</color>
          <width>15</width>
        </LineStyle>
        <PolyStyle>
          <color>7f7faaaa</color>
          <colorMode>random</colorMode>
        </PolyStyle>
    </Style>
</Placemark>
</kml>
"""
        parser.parse(kmlString: testKML)
        XCTAssertEqual(parser.placemarks.first?.styles.count, 1)
        let style = parser.placemarks.first?.styles.first
        XCTAssertEqual("1234S", style?.id)
        let iconStyle = style?.iconStyle
        let labelStyle = style?.labelStyle
        let lineStyle = style?.lineStyle
        let polyStyle = style?.polygonStyle
        
        XCTAssertEqual("a1ff00ff", iconStyle?.color)
        XCTAssertEqual(1.399999976158142, iconStyle?.scale)
        XCTAssertEqual("http://myserver.com/icon.jpg", iconStyle?.icon?.href)
        
        XCTAssertEqual("7fffaaff", labelStyle?.color)
        XCTAssertEqual(1.5, labelStyle?.scale)
        
        XCTAssertEqual("ff0000ff", lineStyle?.color)
        XCTAssertEqual(15.0, lineStyle?.width)
        
        XCTAssertEqual("7f7faaaa", polyStyle?.color)
        XCTAssertEqual("random", polyStyle?.colorMode)
    }
}
