//
//  TAKDataPackageImporter.swift
//  TAKAware
//
//  Created by Cory Foy on 11/14/24.
//

import Foundation
import NIOSSL
import SwiftTAK

class TAKDataPackageImporter: COTDataParser {
    var archiveLocation: URL
    var parsingErrors: [String] = []
    var parser: DataPackageParser?
    
    init (fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageImporter]: Initializing")
        archiveLocation = fileLocation
        super.init()
    }
    
    func parse() {
        parser = DataPackageParser(fileLocation: archiveLocation)
        parser!.parse()
        //let packageFiles = parser!.packageFiles
        //let packageConfiguration = parser!.packageConfiguration
        
        // So now we have the package parsed, a list of the files, and the configuration
        // We need to do a couple of things:
        // 1) Create some sort of data store for this package we're importing
        //    so we can manage it from the UI
        // 2) Go through the files and import them, performing necessary actions
        // 3) Make sure when we're importing them they're tied to this package
        //    and marked as archived so they don't get wiped out
        
        importFiles()
        
        TAKLogger.debug("[TAKDataPackageImporter]: Completed Parsing")
    }
    
    func importFiles() {
        guard let parser = parser else { return }
        let packageFiles = parser.packageFiles
        guard !packageFiles.isEmpty else { return }
        packageFiles.forEach {
            if $0.shouldIgnore { return }
            if $0.fileLocation.hasSuffix(".cot") {
                let cotFile = parser.retrieveFileFromArchive($0)
                let rawXml = String(decoding: cotFile, as: UTF8.self)
                guard let cotEvent = cotParser.parse(rawXml) else {
                    return
                }
                
                switch(cotEvent.eventType) {
                case .ATOM, .BIT:
                    parseAtom(cotEvent: cotEvent, rawXml: rawXml)
                default:
                    TAKLogger.debug("[TAKDataPackageImporter] Non-Atom CoT Event received \(cotEvent.type)")
                }
            }
        }
    }
}
