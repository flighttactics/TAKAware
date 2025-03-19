//
//  MapViewTests.swift
//  TAKAware
//
//  Created by Cory Foy on 3/4/25.
//

import Foundation
import XCTest
import SWXMLHash
import SwiftProtobuf
import SwiftTAK
@testable import TAKAware

final class COTMapObjectTests: TAKAwareTestCase {
    
    func testProcessesAsEllipse() throws {
        let dataContext = DataController.shared.backgroundContext
        dataContext.performAndWait {
            let xml = """
    <?persistorRestore True?><event version="2.0" uid="0acdabc9-2fc3-429a-917c-d84a64d4f2ee" type="u-d-c-e" time="2025-03-04T22:20:55.85Z" start="2025-03-04T22:20:55.85Z" stale="2025-03-11T22:20:55.85Z" how="h-g-i-g-o" access="Undefined"><point lat="38.8846631547111" lon="-77.0027752048967" hae="9999999" ce="9999999" le="9999999" /><detail><contact callsign="RRT At-Large and P.W. Bikes" /><fillColor value="335478784" /><strokeColor value="-65536" /><strokeWeight value="3" /><clamped value="True" /><strokeStyle value="solid" /><remarks /><color argb="-65536" value="-65536" /><height value="0.00">0.00</height><height_unit>4</height_unit><archive /><shape><ellipse minor="116.381521186434" major="301.758319606262" angle="180" /><link relation="p-c" uid="0acdabc9-2fc3-429a-917c-d84a64d4f2ee.style" type="b-x-KmlStyle"><Style><LineStyle><color>FFFF0000</color><width>3</width><alpha>19</alpha></LineStyle><PolyStyle><color>13FF0000</color></PolyStyle></Style></link></shape></detail></event>
    """
            let cotData = COTData(context: dataContext)
            cotData.rawXml = xml
            cotData.cotType = "u-d-c-e"
            cotData.cotUid = "0acdabc9-2fc3-429a-917c-d84a64d4f2ee"
            
            let cmo = COTMapObject(mapPoint: cotData)
            XCTAssertTrue(cmo.shape! is COTMapEllipse)
        }
    }
    
}
