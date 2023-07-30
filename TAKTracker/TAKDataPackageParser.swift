//
//  TAKDataPackageParser.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/25/23.
//

import UIKit
import ZIPFoundation

class TAKDataPackageParser: NSObject {
    var archiveLocation: URL?
    
    init (fileLocation:URL) {
        TAKLogger.debug("Initializing TAKDPP")
        archiveLocation = fileLocation
        super.init()
    }
    
    func parse() {
        processArchive()
    }
    
    private
    func processArchive() {
        TAKLogger.debug("Entering processArchive")
        guard let sourceURL = archiveLocation
        else {
            TAKLogger.error("Unable to access sourceURL variable \(String(describing: archiveLocation))")
            return
        }

        guard let archive = Archive(url: sourceURL, accessMode: .read)
        else {
            TAKLogger.error("Unable to access archive at location \(String(describing: archiveLocation))")
            return
        }
        
        let prefsFile = retrievePrefsFile(archive: archive)
        let prefs = parsePrefsFile(archive: archive, prefsFile: prefsFile)
        storeUserCertificate(archive: archive, fileName: prefs.userCertificateFileName())
        storeServerCertificate(archive: archive, fileName: prefs.serverCertificateFileName())
        storePreferences(preferences: prefs)
        TAKLogger.debug("processArchive Complete")
    }
    
    func storeUserCertificate(archive: Archive, fileName: String) {
        guard let certFile = archive[fileName]
        else { TAKLogger.debug("userCertificate \(fileName) not found in archive"); return }

        _ = try? archive.extract(certFile) { data in
            SettingsStore.global.userCertificate = data
        }
    }
    
    func storeServerCertificate(archive: Archive, fileName: String) {
        guard let certFile = archive[fileName]
        else { TAKLogger.debug("serverCertificate \(fileName) not found in archive"); return }

        _ = try? archive.extract(certFile) { data in
            SettingsStore.global.serverCertificate = data
        }
    }
    
    func storePreferences(preferences: TAKPreferences) {
        SettingsStore.global.userCertificatePassword = preferences.userCertificatePassword
        SettingsStore.global.serverCertificatePassword = preferences.serverCertificatePassword
        
        SettingsStore.global.takServerUrl = preferences.serverConnectionAddress()
        SettingsStore.global.takServerPort = preferences.serverConnectionPort()
        SettingsStore.global.takServerProtocol = preferences.serverConnectionProtocol()
        SettingsStore.global.shouldTryReconnect = true
    }
    
    func parsePrefsFile(archive:Archive, prefsFile: String) -> TAKPreferences {
        let prefsParser = TAKPreferencesParser()
        
        guard let prefFile = archive[prefsFile]
        else { TAKLogger.debug("prefFile not in archive"); return prefsParser.preferences }

        _ = try? archive.extract(prefFile) { data in
            let xmlParser = XMLParser(data: data)
            TAKLogger.debug(String(describing: xmlParser))
            xmlParser.delegate = prefsParser
            xmlParser.parse()
        }
        return prefsParser.preferences
    }
    
    func retrievePrefsFile(archive:Archive) -> String {
        var prefsFile = ""
        
        guard let takManifest = archive["manifest.xml"]
        else { return prefsFile }

        _ = try? archive.extract(takManifest) { data in
            let xmlParser = XMLParser(data: data)
            let manifestParser = TAKManifestParser()
            xmlParser.delegate = manifestParser
            xmlParser.parse()
            TAKLogger.debug("Prefs file: \(manifestParser.prefsFile())")
            prefsFile = manifestParser.prefsFile()
        }
        return prefsFile
    }

}