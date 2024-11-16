//
//  DataPackageParserTests.swift
//  TAKTrackerTests
//
//  Created by Cory Foy on 9/12/23.
//

import Crypto
import _CryptoExtras
import Foundation
import NIOSSL
import SwiftASN1
import SwiftTAK
import X509
import XCTest
import ZIPFoundation
@testable import TAKAware

final class DataPackageParserTests: TAKAwareTestCase {
    var parser:TAKDataPackageParser? = nil
    var archiveURL:URL? = nil
    let queue = DispatchQueue(label: "DataPackageParserTests")

    override func setUpWithError() throws {
        let bundle = Bundle(for: Self.self)
        archiveURL = bundle.url(forResource: TestConstants.ITAK_DATA_PACKAGE_NAME, withExtension: "zip")
        parser = TAKDataPackageParser.init(fileLocation: archiveURL!)
        
        let cleanUpQuery: [String: Any] = [kSecClass as String:  kSecClassIdentity,
                                           kSecAttrLabel as String: TestConstants.TEST_HOST]
        SecItemDelete(cleanUpQuery as CFDictionary)
    }
    
    func testParserStoresServerCertificates() throws {
        let bundle = Bundle(for: Self.self)
        guard let certificateURL = bundle.url(forResource: TestConstants.SERVER_CERTIFICATE_NAME, withExtension: TestConstants.CERTIFICATE_FILE_EXTENSION) else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open test server certificate"])
        }
        
        let certData = try Data(contentsOf: certificateURL)
        let p12Bundle = try NIOSSLPKCS12Bundle(buffer: Array(certData), passphrase: Array(TestConstants.DEFAULT_CERT_PASSWORD.utf8))
        var expectedChain: [Data] = []
        try p12Bundle.certificateChain.forEach { cert in
            try expectedChain.append(Data(cert.toDERBytes()))
        }
        XCTAssert(!expectedChain.isEmpty, "No certificate chain found in the test p12 bundle")
        
        var contents = DataPackageContents()
        
        var pkg = TAKServerCertificatePackage()
        pkg.certificateData = certData
        pkg.certificatePassword = TestConstants.DEFAULT_CERT_PASSWORD
        
        contents.serverCertificates = [pkg]
        contents.serverURL = TestConstants.TEST_HOST
        
        parser!.storeServerCertificate(packageContents: contents)
        XCTAssertEqual(expectedChain, SettingsStore.global.serverCertificateTruststore)
    }
    
    func testParserStoresIdentityInKeychain() throws {
        let bundle = Bundle(for: Self.self)
        guard let certificateURL = bundle.url(forResource: TestConstants.USER_CERTIFICATE_NAME, withExtension: TestConstants.CERTIFICATE_FILE_EXTENSION) else {
            throw XCTestError(.failureWhileWaiting, userInfo: ["FileError": "Could not open test user certificate"])
        }
        
        let certData = try Data(contentsOf: certificateURL)
        
        var contents = DataPackageContents()
        contents.userCertificate = certData
        contents.userCertificatePassword = TestConstants.DEFAULT_CERT_PASSWORD
        contents.serverURL = TestConstants.TEST_HOST
        
        parser!.storeUserCertificate(packageContents: contents, on: queue)
        
        // Wait for queue to sync so we know it stored
        queue.sync {}
        
        let identity = SettingsStore.global.retrieveIdentity(label: TestConstants.TEST_HOST)

        XCTAssertNotNil(identity, "Identity was not stored in the Keychain")
    }

}
