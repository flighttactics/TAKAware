//
//  IconsetParser.swift
//  TAKAware
//
//  Created by Cory Foy on 2/4/25.
//

import Foundation
import SQLite
import SWXMLHash
import UIKit

class IconsetImporter {
    let iconsetsURL = AppConstants.appDirectoryFor(.iconsets)
    let iconSetTable = Table("iconsets")
    let iconTable = Table("icons")
    let fileManager = FileManager()
    let iconsetPackageToImport: URL
    let extractionDirectory: String
    
    var connection: Connection?
    var extractLocation: URL?
    var rootFile: URL?
    var hasFailure = false
    
    var iconsetUUID: UUID
    var parsedIconset: IconSet?
    var parsedIcons: [Icon] = []
    
    init(iconsetPackage: URL) {
        iconsetPackageToImport = iconsetPackage
        iconsetUUID = UUID()
        extractionDirectory = iconsetUUID.uuidString
        do {
            let bundle = Bundle(for: Self.self)
            guard let archiveURL = bundle.url(forResource: "iconsets", withExtension: "sqlite") else {
                TAKLogger.error("[IconsetImporter] Iconset Data Store not located in the Bundle.")
                hasFailure = true
                return
            }
            connection = try Connection(archiveURL.absoluteString, readonly: true)
        } catch {
            TAKLogger.error("[IconsetImporter] Unable to load icon data store.")
            TAKLogger.error("[IconsetImporter] \(error)")
            hasFailure = true
        }
    }
    
    func process() async -> Bool {
        TAKLogger.debug("[IconsetImporter] Starting Iconset processing")
        createExtractionDirectory()
        extractIconset()
        parseRootFile()
        await storeIconset()
        TAKLogger.debug("[IconsetImporter] Completed Iconset processing")
        return !self.hasFailure
    }
    
    private func createExtractionDirectory() {
        let finalExtractionDirectory = iconsetsURL.appending(path: extractionDirectory)
        do {
            try FileManager.default.createDirectory(at: finalExtractionDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            hasFailure = true
            TAKLogger.error("[IconsetImporter] Error creating directory: \(error)")
        }
    }
    
    private func extractIconset() {
        guard !hasFailure else { return }
        extractLocation = iconsetsURL.appending(path: extractionDirectory)
        let fileManager = FileManager()
        do {
            TAKLogger.debug("[IconsetImporter] Extracting iconset to \(extractLocation!.path(percentEncoded: false))")
            try fileManager.createDirectory(at: extractLocation!, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: iconsetPackageToImport, to: extractLocation!)
            let extractedFiles: [String] = try fileManager.contentsOfDirectory(atPath: extractLocation!.path(percentEncoded: false))
            guard let rootXml = extractedFiles.first(where: { $0.hasSuffix("xml") }) else {
                hasFailure = true
                TAKLogger.error("[IconsetImporter] Extraction of iconset archive failed due to no root XML file")
                return
            }
            rootFile = extractLocation!.appendingPathComponent(rootXml)
        } catch {
            hasFailure = true
            TAKLogger.error("[IconsetImporter] Extraction of iconset archive failed with error:\(error)")
        }
    }
    
    /*
     <iconset name="test-iconset" uid="12a34567-1a23-1234-1abc-a1b2cdefg345" skipResize="false" version="8">
         <icon name="air_ship.png" type2525b="a-h-G"/>
     </iconset>
     */
    
    fileprivate func buildIconset(_ iconsetRoot: XMLIndexer) throws {
        let iconSetName: String = try iconsetRoot.value(ofAttribute: "name")
        let iconSetUID: String = try iconsetRoot.value(ofAttribute: "uid")
        let version: String? = iconsetRoot.value(ofAttribute: "version")
        let selectedGroup: String? = iconsetRoot.value(ofAttribute: "selectedGroup")
        let skipResize: Bool = iconsetRoot.value(ofAttribute: "skipResize") ?? false
        let defaultFriendly: String? = iconsetRoot.value(ofAttribute: "defaultFriendly")
        let defaultHostile: String? = iconsetRoot.value(ofAttribute: "defaultHostile")
        let defaultNeutral: String? = iconsetRoot.value(ofAttribute: "defaultNeutral")
        let defaultUnknown: String? = iconsetRoot.value(ofAttribute: "defaultUnknown")
        parsedIconset = IconSet(
            id: 0,
            name: iconSetName,
            uid: iconSetUID,
            iconsetUUID: iconsetUUID,
            selectedGroup: selectedGroup ?? "Default",
            version: version,
            skipResize: skipResize,
            defaultFriendly: defaultFriendly,
            defaultHostile: defaultHostile,
            defaultNeutral: defaultNeutral,
            defaultUnknown: defaultUnknown
        )
    }
    
    private func parseRootFile() {
        guard !hasFailure else { return }
        guard rootFile != nil else { return }
        do {
            let data = try Data(contentsOf: rootFile!)
            if let xmlString = String(data: data, encoding: .utf8) {
                TAKLogger.debug("[IconsetImporter] Starting parse of root file")
                let rootXml = XMLHash.parse(xmlString)
                let iconsetRoot = rootXml["iconset"]
                try buildIconset(iconsetRoot)
                let iconNodes = iconsetRoot.children
                let subpaths: [String] = try fileManager.subpathsOfDirectory(atPath: extractLocation!.path(percentEncoded: false))
                try iconNodes.forEach { iconNode in
                    let iconName: String = try iconNode.value(ofAttribute: "name")
                    let iconType2525b: String? = iconNode.value(ofAttribute: "type2525b")
                    let iconPath = subpaths.first(where: { $0.hasSuffix("/\(iconName)") }) ?? ""
                    let iconPathParts = iconPath.split(separator: "/")
                    var group = "default"
                    if iconPathParts.count > 1 {
                        group = String(iconPathParts.first!)
                    }
                    var img = UIImage(named: "sugp-----------")!
                    
                    let imgPath = extractLocation!.appending(path: iconPath)
                    let imgData = fileManager.contents(atPath: imgPath.path(percentEncoded: false))
                    if imgData != nil {
                        let iconImg = UIImage(data: imgData!)
                        if iconImg != nil {
                            img = iconImg!
                        }
                    }

                    let icon = Icon(id: 0, iconset_uid: parsedIconset!.uid, filename: iconName, groupName: group, type2525b: iconType2525b, icon: img)
                    parsedIcons.append(icon)
                }
            }
        } catch {
            TAKLogger.error("[IconsetImporter] Unable to parse root file \(error)")
            hasFailure = true
        }
    }
    
    private func storeIconset() async {
        guard !hasFailure else { return }
        guard let parsedIconset = parsedIconset else { return }
        do {
            try await IconDataController.shared.createIconSet(iconSet: parsedIconset, icons: parsedIcons)
        } catch {
            hasFailure = true
        }
    }
}
