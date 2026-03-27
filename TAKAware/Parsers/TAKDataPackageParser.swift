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

class TAKDataPackageParser: NSObject {
    var archiveLocation: URL
    var parsingErrors: [String] = []
    
    init (fileLocation: URL) {
        TAKLogger.debug("[TAKDataPackageParser]: Initializing")
        archiveLocation = fileLocation
        super.init()
    }
    
    func parse() {
        let parser = DataPackageParser(fileLocation: archiveLocation)
        parser.parse()
        let contents = parser.packageContents
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
        guard let archive = Archive(url: archiveLocation, accessMode: .read) else {
            return "The downloaded file is not a valid data package"
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
        TAKLogger.debug("[TAKDataPackageParser]: Storing User Certificate")
        
        on.async {
            //Parse the cert file
            let parsedCert = PKCS12(data: packageContents.userCertificate, password: packageContents.userCertificatePassword)
            
            guard let identity = parsedCert.identity else {
                self.parsingErrors.append("No User Certificate found")
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
        TAKLogger.debug("[TAKDataPackageParser]: Storing User Certificate (sync)")
        
        let parsedCert = PKCS12(data: packageContents.userCertificate, password: packageContents.userCertificatePassword)
        
        guard let identity = parsedCert.identity else {
            parsingErrors.append("No User Certificate found")
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
            parsingErrors.append("No Server truststore certificate was found in the data package")
            DispatchQueue.main.async {
                SettingsStore.global.serverCertificateTruststore = serverCertChain
            }
            return
        }
        
        do {
            try serverCerts.forEach { serverCert in
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
                } else if status == errSecAuthFailed {
                    self.parsingErrors.append("Incorrect password for server truststore certificate")
                    TAKLogger.error("[TAKDataPackageParser]: Auth failed for server cert (wrong password?)")
                } else {
                    TAKLogger.error("[TAKDataPackageParser]: SecPKCS12Import failed: \(status)")
                    // Try NIOSSL as fallback for standard TAK Server packages
                    let p12Bundle = try NIOSSLPKCS12Bundle(buffer: Array(serverCert.certificateData), passphrase: Array(serverCert.certificatePassword.utf8))
                    try p12Bundle.certificateChain.forEach { cert in
                        try serverCertChain.append(Data(cert.toDERBytes()))
                    }
                }
            }
        } catch {
            parsingErrors.append("Could not process server certificates \(error)")
            TAKLogger.error("[TAKDataPackageParser]: Unable to store Server Certificate from Data Package: \(error)")
        }
        
        if(serverCertChain.isEmpty) {
            parsingErrors.append("No Server truststore certificate was found in the data package")
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
