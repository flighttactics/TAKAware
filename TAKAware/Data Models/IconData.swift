//
//  IconData.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/6/24.
//

import CoreGraphics
import Foundation
import SQLite
import SwiftTAK
import UIKit

struct IconSet {
    var id: Int
    var name: String
    var uid: String
    var iconsetUUID: UUID
    var selectedGroup: String
    var version: String?
    var skipResize: Bool = false
    var defaultFriendly: String?
    var defaultHostile: String?
    var defaultNeutral: String?
    var defaultUnknown: String?
}

struct Icon {
    var id: Int
    var iconset_uid: String
    var filename: String
    var groupName: String
    var type2525b: String?
    var icon: UIImage
    var isCircularImage: Bool = false
}

class IconData {
    var connection: Connection?
    let iconSetTable = Table("iconsets")
    let iconTable = Table("icons")
    
    let iconSetId = Expression<Int>(value: "id")
    let iconSetName = Expression<String>(value: "name")
    let iconSetUid = Expression<String>(value: "uid")
    let selectedGroup = Expression<String>(value: "selectedGroup")
    let version = Expression<String?>(value: "version")
    let defaultFriendly = Expression<String?>(value: "defaultFriendly")
    let defaultHostile = Expression<String?>(value: "defaultHostile")
    let defaultNeutral = Expression<String?>(value: "defaultNeutral")
    let defaultUnknown = Expression<String?>(value: "defaultUnknown")
    
    static let DEFAULT_KML_ICON: String = "f7f71666-8b28-4b57-9fbb-e38e61d33b79/Google/ylw-pushpin.png"
    
    static let shared = IconData()
    
    func insertIconset(iconSet: IconSet) throws {
        guard let connection = connection else { return }
        var iconsetGroup = iconSet.selectedGroup
        if iconsetGroup.isEmpty { iconsetGroup = iconSet.name }
        try connection.run(
            iconSetTable.insert(
                iconSetName <- iconSet.name,
                iconSetUid <- iconSet.uid,
                selectedGroup <- iconsetGroup,
                version <- iconSet.version ?? "",
                defaultFriendly <- iconSet.defaultFriendly ?? "",
                defaultHostile <- iconSet.defaultHostile ?? "",
                defaultNeutral <- iconSet.defaultNeutral ?? "",
                defaultUnknown <- iconSet.defaultUnknown ?? ""
            )
        )
    }
    
    static func colorFromArgb(argbVal: Int) -> UIColor {
        let blue = CGFloat(argbVal & 0xff)
        let green = CGFloat(argbVal >> 8 & 0xff)
        let red = CGFloat(argbVal >> 16 & 0xff)
        let alpha = CGFloat(argbVal >> 24 & 0xff)
        return UIColor(red: red/255, green: green/255.0, blue: blue/255.0, alpha: alpha/255.0)
    }
    
    // The order of expression is aabbggrr, where aa=alpha (00 to ff);
    // bb=blue (00 to ff); gg=green (00 to ff); rr=red (00 to ff)
    static func colorFromKMLColor(kmlColor: String) -> Int {
        let colorArray = kmlColor.hexaToBytes
        guard colorArray.count == 4 else {
            TAKLogger.debug("[IconData] Unable to parse KML Color from \(kmlColor)")
            return 0
        }
        let a1: Int32 = Int32(colorArray[0])
        let b1: Int32 = Int32(colorArray[1])
        let g1: Int32 = Int32(colorArray[2])
        let r1: Int32 = Int32(colorArray[3])
        let finalInt = (a1 << 24) + (r1 << 16) + (g1 << 8) + (b1 << 0)
        return Int(finalInt)
    }
    
    static func colorForTeam(_ team: String) -> UIColor {
        /*
         From https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV/blob/889eee292c43d3d2eafdd1f2fbf378ad5cd89ecc/atak/ATAK/app/src/main/assets/filters/team_filters.xml#L9
         <filter team='White'>white</filter>
         <filter team='Yellow'>yellow</filter>
         <filter team='Orange'>#FFFF7700</filter>
         <filter team='Magenta'>magenta</filter>
         <filter team='Red'>red</filter>
         <filter team='Maroon'>#FF7F0000</filter>
         <filter team='Purple'>#FF7F007F</filter>
         <filter team='Dark Blue'>#FF00007F</filter>
         <filter team='Blue'>blue</filter>
         <filter team='Cyan'>cyan</filter>
         <filter team='Teal'>#FF007F7F</filter>
         <filter team='Green'>green</filter>
         <filter team='Dark Green'>#FF007F00</filter>
         <filter team='Brown'>#FFA0714F</filter>
         */
        switch(team) {
        case "White": return UIColor.white
        case "Yellow": return UIColor.yellow
        case "Magenta": return UIColor.magenta
        case "Red": return UIColor.red
        case "Blue": return UIColor.blue
        case "Cyan": return UIColor.cyan
        case "Green": return UIColor.green
        case "Orange": return UIColor(red: 1, green: 0.467, blue: 0, alpha: 1.0)
        case "Maroon": return UIColor(red: 0.498, green: 0, blue: 0, alpha: 1.0)
        case "Purple": return UIColor(red: 0.498, green: 0, blue: 0.498, alpha: 1.0)
        case "Dark Blue": return UIColor(red: 0, green: 0, blue: 0.498, alpha: 1.0)
        case "Teal": return UIColor(red: 0, green: 0.498, blue: 0.498, alpha: 1.0)
        case "Dark Green": return UIColor(red: 0, green: 0.498, blue: 0, alpha: 1.0)
        case "Brown": return UIColor(red: 0.627, green: 0.443, blue: 0.31, alpha: 1.0)
        default: return UIColor.white
        }
    }
    
    static func iconFor(annotation: MapPointAnnotation?) async -> Icon {
        if annotation?.role != nil && !annotation!.role!.isEmpty && !SettingsStore.global.enable2525ForRoles {
            return IconData.iconFor(role: annotation!.role!)
        }
        let iconSetPath = annotation?.icon ?? ""
        return await IconData.iconFor(type2525: annotation?.cotType ?? "", iconsetPath: iconSetPath)
    }
    
    static func iconFor(role: String) -> Icon {
        let uiImg = switch(role) {
        case TeamRole.ForwardObserver.rawValue: UIImage(named: "forwardobserver")
        case TeamRole.HQ.rawValue: UIImage(named: "hq")
        case TeamRole.K9.rawValue: UIImage(named: "k9")
        case TeamRole.Medic.rawValue: UIImage(named: "medic")
        case TeamRole.RTO.rawValue: UIImage(named: "rto")
        case TeamRole.Sniper.rawValue: UIImage(named: "sniper")
        case TeamRole.TeamMember.rawValue: UIImage(named: "team")
        case TeamRole.TeamLead.rawValue: UIImage(named: "teamlead")
        default: UIImage(named: "team")
        }
        return Icon(id: 0, iconset_uid: UUID().uuidString, filename: "none", groupName: "none", icon: uiImg!, isCircularImage: true)
    }
    
    static func iconFor(type2525: String, iconsetPath: String) async -> Icon {
        var dataBytes = Data()
        
        TAKLogger.debug("[IconData] Loading icon for \(type2525) and path \(iconsetPath)")
        
        if iconsetPath.count > 0 {
            //de450cbf-2ffc-47fb-bd2b-ba2db89b035e/Resources/ESF4-FIRE-HAZMAT_Aerial-Apparatus-Ladder.png
            let pathParts = iconsetPath.split(separator: "/")
            if pathParts.count == 3 {
                let iconSetUid = String(pathParts[0]) //iconset_uid
                //let iconsetName = String(pathParts[1]) //iconsetName
                let imageName = String(pathParts[2]) //filename
                
                if iconSetUid == "COT_MAPPING_SPOTMAP" {
                    TAKLogger.debug("[IconData] Spotmap detected")
                    // This is a unique spotmap
                    // So we'll return a circle
                    // where the imageName is the argb colors
                    let spotMapImg = UIImage(systemName: "circle.inset.filled")!
                    return Icon(id: 0, iconset_uid: UUID().uuidString, filename: "none", groupName: "none", icon: spotMapImg)
                } else {
                    let bitMapCol = SQLite.Expression<Blob>("bitmap")
                    let iconSetCol = SQLite.Expression<String>("iconset_uid")
                    let fileNameCol = SQLite.Expression<String>("filename")
                    
                    let query: QueryType = shared.iconTable
                        .filter(iconSetCol == iconSetUid)
                        .filter(fileNameCol == imageName)
                    let conn = shared.connection
                    do {
                        if let row = try conn!.pluck(query) {
                            dataBytes = try Data.fromDatatypeValue(row.get(bitMapCol))
                        }
                    } catch {
                        TAKLogger.error("[IconData] Error retrieving iconsetpath \(error)")
                    }
                    
                    if dataBytes.isEmpty {
                        TAKLogger.debug("[IconData] Default SQL did not contain icon. Need to check custom loads")
                        dataBytes = await IconDataController().retrieveIconFor(iconSetUid: iconSetUid, filename: imageName)
                        TAKLogger.debug("[IconData] dataBytes empty? \(dataBytes.isEmpty)")
                    }
                }
            } else {
                TAKLogger.debug("[IconData] Unknown iconset path split for path \(iconsetPath)")
            }
        }

        // Default icon is the unknown icon
        var uiImg = UIImage(named: milStdIconWithName(name: "sugp"))!
        
        if !dataBytes.isEmpty {
            TAKLogger.debug("[IconData] Custom icon located, loading")
            let cgDp = CGDataProvider(data: dataBytes as CFData)!
            let cgImg = CGImage(pngDataProviderSource: cgDp, decode: nil, shouldInterpolate: false, intent: .perceptual)!
            uiImg = UIImage(cgImage: cgImg)
        } else {
            TAKLogger.debug("[IconData] No custom icon located, attempting 2525 load")
            let mil2525iconName = IconData.mil2525FromCotType(cotType: type2525)
            if !mil2525iconName.isEmpty {
                TAKLogger.debug("[IconData] Found a 2525 icon for \(type2525) - \(mil2525iconName)")
                let img2525 = UIImage(named: mil2525iconName)
                if img2525 != nil {
                    uiImg = img2525!
                } else {
                    TAKLogger.error("[IconData] mil2525icon with name \(mil2525iconName) for \(type2525) could not be converted into an image!")
                    let defaultImg = milStdIconWithName(name: "sugp")
                    uiImg = UIImage(named: defaultImg)!
                }
                
            }
        }

        return Icon(id: 0, iconset_uid: UUID().uuidString, filename: "none", groupName: "none", icon: uiImg)
    }
    
    static func milStdIconWithName(name: String) -> String {
        // The milspec names are 15 characters long, dash padded
        // Ex: sugp-----------
        return name.padding(toLength: 15, withPad: "-", startingAt: 0)
    }
    
    static func iconsForSet(iconSetUid: String) -> [Icon] {
        return []
    }
    
    static func iconsFor2525b(type2525b: String) -> [Icon] {
        return []
    }
    
    static func iconForFileName(iconSetUid: String?, filename: String) -> Icon? {
        return nil
    }
    
    private init() {
        do {
            let bundle = Bundle(for: Self.self)
            guard let archiveURL = bundle.url(forResource: "iconsets", withExtension: "sqlite") else {
                TAKLogger.error("[IconData] Iconset Data Store not located in the Bundle. Defaulting all icons")
                return
            }
            connection = try Connection(archiveURL.absoluteString, readonly: true)
        } catch {
            TAKLogger.error("[IconData] Unable to load icon data store. Defaulting all icons")
            TAKLogger.error("[IconData] \(error)")
        }
    }
    
    // Adapted from the Icon2525cTypeResolver.java
    // found in https://github.com/deptofdefense/AndroidTacticalAssaultKit-CIV
    static func mil2525FromCotType(cotType: String) -> String {
        guard cotType.count > 2 && cotType.first == "a" else {
            return ""
        }
        
        var s2525C = ""
        
        let checkIndex = cotType.index(cotType.startIndex, offsetBy: 2)

        switch(cotType[checkIndex].lowercased()) {
        case "f", "a":
            s2525C = "sf"
        case "n":
            s2525C = "sn"
        case "s", "j", "k", "h":
            s2525C = "sh"
        case "u":
            s2525C = "su"
        default:
            s2525C = "su"
        }
        
        var cotCharacters = Array(cotType)
        for pos in stride(from: 4, to: cotType.count, by: 2) {
            let cotChar = cotCharacters[pos]
            s2525C.append(cotChar.lowercased())
            if pos == 4 {
                s2525C.append("p")
            }
        }
        
        cotCharacters = Array(s2525C)

        for pos in (s2525C.count)..<15 {
            if (pos == 10 && cotCharacters.count >= 5 && cotCharacters[2] == "g" && cotCharacters[4] == "i") {
                s2525C.append("h")
            } else {
                s2525C.append("-")
            }
        }
        return s2525C
    }
}
