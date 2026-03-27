//
//  TAKDataPackageParser.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/25/23.
//

import Foundation
import NIOSSL
import SwiftTAK
import ZIPFoundation

// MARK: - Section-aware .pref parser
//
// SwiftTAK's PreferencesParser is section-blind: it parses all three
// <preference name="..."> blocks flat. That means connectString0 from
// cot_inputs (UDP multicast) overwrites the one from cot_streams (SSL server).
// This parser only captures keys inside the cot_streams section.
private class SectionAwarePrefParser: NSObject, XMLParserDelegate {
    var serverConnectionString = ""
    var serverCertificatePath = ""
    var serverCertificatePassword = ""

    private var currentSection = ""
    private var currentKey = ""
    private var textBuffer = ""

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "preference" {
            currentSection = attributeDict["name"] ?? ""
        } else if elementName == "entry" {
            currentKey = attributeDict["key"] ?? ""
            textBuffer = ""
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "preference" {
            currentSection = ""
            return
        }
        guard elementName == "entry", currentSection == "cot_streams" else {
            currentKey = ""
            textBuffer = ""
            return
        }
        if currentKey == "connectString0" || currentKey == "connectString" {
            serverConnectionString = textBuffer
        } else if currentKey.hasPrefix("caLocation") {
            serverCertificatePath = textBuffer
        } else if currentKey.hasPrefix("caPassword") {
            serverCertificatePassword = textBuffer
        }
        currentKey = ""
        textBuffer = ""
    }
}

class TAKDataPackageParser: NSObject {
    var archiveLocation: URL
    var parsingErrors: [String] = []
    /// True when a certificate was present in the package but could not be imported.
    /// The hostname/port/protocol are still stored so the caller can prompt for credentials.
    var certImportFailed = false

    init (fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageParser]: Initializing")
        archiveLocation = fileLocation
        super.init()
    }

    // Re-parses the .pref file with section awareness and overrides the values
    // that SwiftTAK's section-blind PreferencesParser gets wrong.
    private func overrideContentsFromPref(_ contents: inout DataPackageContents) {
        let archive: Archive
        do {
            archive = try Archive(url: archiveLocation, accessMode: .read)
        } catch {
            TAKLogger.error("[TAKDataPackageParser]: Cannot open archive for pref override: \(error)")
            return
        }

        guard let prefEntry = archive.first(where: { !$0.path.hasPrefix(".") && $0.path.hasSuffix(".pref") }) else {
            TAKLogger.debug("[TAKDataPackageParser]: No .pref file found in archive")
            return
        }

        var prefData = Data()
        _ = try? archive.extract(prefEntry) { chunk in prefData.append(chunk) }
        guard !prefData.isEmpty else { return }

        let delegate = SectionAwarePrefParser()
        let xmlParser = XMLParser(data: prefData)
        xmlParser.delegate = delegate
        xmlParser.parse()

        // Override server connection from cot_streams connectString
        if !delegate.serverConnectionString.isEmpty {
            let parts = delegate.serverConnectionString.components(separatedBy: ":")
            contents.serverURL = parts.count > 0 ? parts[0] : contents.serverURL
            contents.serverPort = parts.count > 1 ? parts[1] : contents.serverPort
            contents.serverProtocol = parts.count > 2 ? parts[2] : contents.serverProtocol
            TAKLogger.debug("[TAKDataPackageParser]: pref override — server: \(delegate.serverConnectionString)")
        }

        // Override server certificate using full path first, then filename fallback
        guard !delegate.serverCertificatePath.isEmpty else { return }
        let certPath = delegate.serverCertificatePath
        let certFileName = certPath.components(separatedBy: "/").last ?? certPath

        var certData = Data()

        // Try 1: exact path as written in pref (e.g. cert/truststore.p12)
        if let entry = archive.first(where: { $0.path == certPath }) {
            _ = try? archive.extract(entry) { chunk in certData.append(chunk) }
        }

        // Try 2: rootFolder/certPath (packages with a top-level folder)
        if certData.isEmpty, !contents.rootFolder.isEmpty {
            let prefixed = "\(contents.rootFolder)/\(certPath)"
            if let entry = archive.first(where: { $0.path == prefixed }) {
                _ = try? archive.extract(entry) { chunk in certData.append(chunk) }
            }
        }

        // Try 3: filename only anywhere in the archive
        if certData.isEmpty {
            if let entry = archive.first(where: { $0.path == certFileName || $0.path.hasSuffix("/\(certFileName)") }) {
                _ = try? archive.extract(entry) { chunk in certData.append(chunk) }
            }
        }

        if !certData.isEmpty {
            let certPackage = TAKServerCertificatePackage(
                certificateData: certData,
                certificatePassword: delegate.serverCertificatePassword
            )
            contents.serverCertificates = [certPackage]
            TAKLogger.debug("[TAKDataPackageParser]: pref override — cert loaded from: \(certPath)")
        } else {
            TAKLogger.error("[TAKDataPackageParser]: pref override — cert not found for path: \(certPath)")
        }
    }

    func parse() {
        let parser = DataPackageParser(fileLocation: archiveLocation)
        parser.parse()
        var contents = parser.packageContents
        overrideContentsFromPref(&contents)
        storeUserCertificate(packageContents: contents)
        storeServerCertificate(packageContents: contents)
        storePreferences(packageContents: contents)
        TAKLogger.debug("[TAKDataPackageParser]: Completed Parsing")
    }
    
    // MARK: - CloudTAK import with explicit P12 password
    
    static let maxUncompressedSize: Int64 = 250 * 1024 * 1024  // 250 MB
    static let maxEntryCount: Int = 1000
    
    func parse(p12Password: Data) {
        var passwordBuffer = p12Password
        defer {
            TAKDataPackageParser.zeroPasswordBuffer(&passwordBuffer)
        }
        
        // Validate zip safety before extraction
        if let safetyError = validateZipSafety() {
            parsingErrors.append(safetyError)
            TAKLogger.error("[TAKDataPackageParser]: Zip safety check failed: \(safetyError)")
            return
        }
        
        let parser = DataPackageParser(fileLocation: archiveLocation)
        parser.parse()
        var contents = parser.packageContents
        overrideContentsFromPref(&contents)

        // Override password with the provided Data buffer
        // Minimize String lifetime — create in local scope, apply, then clear
        do {
            let passwordString = String(data: passwordBuffer, encoding: .utf8) ?? ""
            contents.userCertificatePassword = passwordString
            for i in 0..<contents.serverCertificates.count {
                contents.serverCertificates[i].certificatePassword = passwordString
            }
        }
        
        storeUserCertificateSynchronously(packageContents: contents)
        storeServerCertificate(packageContents: contents)
        storePreferences(packageContents: contents)
        TAKLogger.debug("[TAKDataPackageParser]: Completed CloudTAK Parsing")
    }
    
    func validateZipSafety() -> String? {
        let archive: Archive
        do {
            archive = try Archive(url: archiveLocation, accessMode: .read)
        } catch {
            return "The downloaded file is not a valid data package: \(error.localizedDescription)"
        }
        
        var entryCount = 0
        var totalUncompressedSize: Int64 = 0
        
        for entry in archive {
            entryCount += 1
            if entryCount > Self.maxEntryCount {
                return "Data package extraction aborted: too many files (>\(Self.maxEntryCount))"
            }
            
            totalUncompressedSize += Int64(entry.uncompressedSize)
            if totalUncompressedSize > Self.maxUncompressedSize {
                return "Data package extraction aborted: uncompressed size exceeds 250 MB"
            }
            
            let entryPath = entry.path
            
            // Reject absolute paths
            if entryPath.hasPrefix("/") {
                TAKLogger.debug("[TAKDataPackageParser]: Skipping entry with absolute path: \(entryPath)")
                continue
            }
            
            // Reject path traversal
            if entryPath.contains("../") {
                TAKLogger.debug("[TAKDataPackageParser]: Skipping entry with path traversal: \(entryPath)")
                continue
            }
            
            // Reject symbolic links
            if entry.type == .symlink {
                TAKLogger.debug("[TAKDataPackageParser]: Skipping symbolic link entry: \(entryPath)")
                continue
            }
        }
        
        return nil
    }
    
    static func zeroPasswordBuffer(_ buffer: inout Data) {
        buffer.withUnsafeMutableBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                // memset_s (C11 Annex K) is guaranteed not to be optimized away
                memset_s(baseAddress, ptr.count, 0, ptr.count)
            }
        }
        buffer = Data()
    }
    
    func storeUserCertificate(packageContents: DataPackageContents, on: DispatchQueue = DispatchQueue.global(qos: .background)) {
        guard !packageContents.userCertificate.isEmpty else {
            TAKLogger.debug("[TAKDataPackageParser]: No user certificate in package, skipping")
            return
        }
        TAKLogger.debug("[TAKDataPackageParser]: Storing User Certificate")

        on.async {
            let parsedCert = PKCS12(data: packageContents.userCertificate, password: packageContents.userCertificatePassword)

            guard let identity = parsedCert.identity else {
                TAKLogger.error("[TAKDataPackageParser]: Identity was not present in the parsed cert")
                return
            }

            SettingsStore.global.storeIdentity(identity: identity, label: packageContents.serverURL)
            TAKLogger.debug("[TAKDataPackageParser]: User Certificate Stored")
        }
    }

    /// Synchronous variant used by the CloudTAK import path so that
    /// parsingErrors are populated before the caller inspects them.
    func storeUserCertificateSynchronously(packageContents: DataPackageContents) {
        guard !packageContents.userCertificate.isEmpty else {
            TAKLogger.debug("[TAKDataPackageParser]: No user certificate in package, skipping (sync)")
            return
        }
        TAKLogger.debug("[TAKDataPackageParser]: Storing User Certificate (sync)")

        let parsedCert = PKCS12(data: packageContents.userCertificate, password: packageContents.userCertificatePassword)

        guard let identity = parsedCert.identity else {
            TAKLogger.error("[TAKDataPackageParser]: Identity was not present in the parsed cert")
            return
        }

        DispatchQueue.main.async {
            SettingsStore.global.storeIdentity(identity: identity, label: packageContents.serverURL)
        }
        TAKLogger.debug("[TAKDataPackageParser]: User Certificate Stored (sync)")
    }
    
    func storeServerCertificate(packageContents: DataPackageContents) {
        TAKLogger.debug("[TAKDataPackageParser]: Storing Server Certificate")
        
        let serverCerts = packageContents.serverCertificates
        var serverCertChain: [Data] = []
        
        guard !serverCerts.isEmpty else {
            TAKLogger.debug("[TAKDataPackageParser]: No server truststore in package — hostname-only import")
            certImportFailed = true
            DispatchQueue.main.async {
                SettingsStore.global.serverCertificateTruststore = serverCertChain
            }
            return
        }

        for serverCert in serverCerts {
            // Use Security framework (SecPKCS12Import) instead of NIOSSL
            // because NIOSSL calls fatalError when the P12 is a truststore
            // without a private key (common in CloudTAK packages)
            var importResult: CFArray?
            let options: [String: Any] = [kSecImportExportPassphrase as String: serverCert.certificatePassword]
            let status = SecPKCS12Import(serverCert.certificateData as CFData, options as CFDictionary, &importResult)
            if status == errSecSuccess, let items = importResult as? [[String: Any]] {
                for item in items {
                    if let chain = item[kSecImportItemCertChain as String] as? [SecCertificate] {
                        for cert in chain {
                            serverCertChain.append(SecCertificateCopyData(cert) as Data)
                        }
                    }
                    if let trust = item[kSecImportItemTrust as String] {
                        let secTrust = trust as! SecTrust
                        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                            if let chain = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate] {
                                for cert in chain {
                                    let certData = SecCertificateCopyData(cert) as Data
                                    if !serverCertChain.contains(certData) {
                                        serverCertChain.append(certData)
                                    }
                                }
                            }
                        } else {
                            // Fallback for older OS versions
                            for i in 0..<SecTrustGetCertificateCount(secTrust) {
                                if let cert = SecTrustGetCertificateAtIndex(secTrust, i) {
                                    let certData = SecCertificateCopyData(cert) as Data
                                    if !serverCertChain.contains(certData) {
                                        serverCertChain.append(certData)
                                    }
                                }
                            }
                        }
                    }
                }
            } else if status == errSecAuthFailed {
                TAKLogger.error("[TAKDataPackageParser]: Auth failed for server cert (wrong password?)")
                self.certImportFailed = true
            } else {
                // SecPKCS12Import failed with a non-auth error (likely legacy RC2-CBC/3DES
                // encryption common in Java-generated TAK Server P12s, which iOS rejects).
                // NIOSSL cannot be used as a fallback here because NIOSSLPKCS12Bundle calls
                // fatalError when the P12 has no private key (truststore-only).
                // There is no iOS API that handles legacy-encrypted cert-only P12s.
                // The caller will fall back to username/password credential enrollment.
                TAKLogger.error("[TAKDataPackageParser]: SecPKCS12Import failed (OSStatus \(status)) — likely legacy RC2/3DES-encrypted P12. Falling back to credential auth.")
                self.certImportFailed = true
            }
        }

        if serverCertChain.isEmpty {
            TAKLogger.debug("[TAKDataPackageParser]: Server cert chain empty after import — falling back to credential auth")
            certImportFailed = true
        }
        
        TAKLogger.debug("[TAKDataPackageParser]: Storing cert chain with \(serverCertChain.count) cert(s)")
        DispatchQueue.main.async {
            SettingsStore.global.serverCertificateTruststore = serverCertChain
        }
    }
    
    func storePreferences(packageContents: DataPackageContents) {
        DispatchQueue.main.async {
            SettingsStore.global.takServerUrl = packageContents.serverURL
            SettingsStore.global.takServerPort = packageContents.serverPort
            SettingsStore.global.takServerProtocol = packageContents.serverProtocol
            SettingsStore.global.takServerChanged = true
        }
    }

}
