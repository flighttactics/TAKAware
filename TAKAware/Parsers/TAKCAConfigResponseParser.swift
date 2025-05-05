//
//  TAKCAConfigResponseParser.swift
//  TAKTracker
//
//  Created by Cory Foy on 9/14/23.
//

import Foundation

struct CAConfigDistiguishedName {
    var organizationNameComponents: [String] = []
    var organizationalUnitNameComponents: [String] = []
    var domainComponents: [String] = []
}

class TAKCAConfigResponseParser: NSObject, XMLParserDelegate {
    var distingushedNameEntries: CAConfigDistiguishedName = CAConfigDistiguishedName()
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        if(elementName == "nameEntry") {
            if let nameVal = attributeDict["name"],
               let valueVal = attributeDict["value"] {
                
                switch(nameVal.uppercased()) {
                case "O":
                    distingushedNameEntries.organizationNameComponents.append(valueVal)
                case "OU":
                    distingushedNameEntries.organizationalUnitNameComponents.append(valueVal)
                case "DC":
                    distingushedNameEntries.domainComponents.append(valueVal)
                default:
                    TAKLogger.error("[TAKConfigResponseParser]: Unknown entry received \(nameVal) - ignoring")
                }
            }
        }
        
    }
}
