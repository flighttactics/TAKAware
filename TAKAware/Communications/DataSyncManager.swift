//
//  DataSyncManager.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import Foundation

struct DataSyncDataPackageRole {
    var permissions: [String] = []
    var type: String = ""
}

struct DataSyncDataPackageUid {
    var data: String = ""
    var timestamp: String = ""
    var creatorUid: String = ""
}

struct LocationCoordinates {
    var lat: Double
    var lon: Double
}

struct DataSyncDataPackageUidDetail {
    var type: String = ""
    var callsign: String = ""
    var iconsetPath: String = ""
    var color: String = "-1"
    var location: LocationCoordinates
}

struct DataSyncDataPackageContent {
    var data: DataSyncDataPackageContentData
    var timestamp: String = ""
    var creatorUid: String = ""
    var details: DataSyncDataPackageUidDetail?
}

struct DataSyncDataPackageContentData {
    var keywords: [String] = []
    var mimeType: String = ""
    var name: String = ""
    var submissionTime: String = ""
    var submitter: String = ""
    var uid: String = ""
    var creatorUid: String = ""
    var hash: String = ""
    var size: Int = 0
    var expiration: Int = -1
}

struct DataSyncDataPackage {
    var name: String = ""
    var description: String = ""
    var chatRoom: String = ""
    var baseLayer: String = ""
    var bbox: String = ""
    var path: String = ""
    var classification: String = ""
    var tool: String = ""
    var keywords: [String] = []
    var creatorUid: String = ""
    var createTime: String = ""
    var groups: [String] = []
    var externalData: [String] = []
    var feeds: [String] = []
    var mapLayers: [String] = []
    var defaultRole: DataSyncDataPackageRole = DataSyncDataPackageRole()
    var inviteOnly: String = ""
    var expiration: Int = -1
    var guid: String = ""
    var uids: [DataSyncDataPackageUid] = []
    var contents: [DataSyncDataPackageContent] = []
    var passwordProtected: Bool = false
}

class DataSyncManager: NSObject, ObservableObject, URLSessionDelegate {
    @Published var isLoading = false
    @Published var dataPackages: [DataSyncDataPackage] = []
    
    func retrieveMissions() {
        isLoading = true
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.DATA_PACKAGE_LIST_PATH)"
        TAKLogger.debug("[DataSyncManager] Requesting data packages from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "get"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[DataSyncManager] Session Data Task Returned...")
            self.isLoading = false
            if error != nil {
                self.logDataPackagesError(error!.localizedDescription)
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.logDataPackagesError("Non success response code \((response as? HTTPURLResponse)?.statusCode.description ?? "UNKNOWN")")
                return
            }
            if let mimeType = response.mimeType,
                (mimeType == "application/json" || mimeType == "text/plain"),
                let data = data {
                self.storeDataPackagesResponse(data)
            } else {
                self.logDataPackagesError("Unknown response from server when attempting data package retrieval")
            }
        })

        task.resume()
    }
    
    func storeDataPackagesResponse(_ data: Data) {
        TAKLogger.debug("[DataSyncManager] storingDataSyncResponse!")
        dataPackages = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let packageList = json["data"] as? [[String: Any]] else { return }
                for dataPackageData in packageList {
                    let name = dataPackageData["name"] as! String
                    let description = dataPackageData["description"] as! String
                    let creatorUid = dataPackageData["creatorUid"] as! String
                    let createTime = dataPackageData["createTime"] as! String
                    let dataPackage = DataSyncDataPackage(
                        name: name,
                        description: description,
                        creatorUid: creatorUid,
                        createTime: createTime
                    )
                    dataPackages.append(dataPackage)
                }
            }
        } catch {
            TAKLogger.error("[DataSyncManager]: Error processing data sync mission list response \(error)")
        }
    }
    
    func logDataPackagesError(_ err: String) {
        TAKLogger.error("[DataSyncManager]: Error while trying to retrieve data sync missions \(err)")
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authenticationMethod = challenge.protectionSpace.authenticationMethod

        if authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            TAKLogger.error("[DataSyncManager]: Server requesting identity challenge")
            guard let clientIdentity = SettingsStore.global.retrieveIdentity(label: SettingsStore.global.takServerUrl) else {
                TAKLogger.error("[DataSyncManager]: Identity was not stored in the keychain")
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            TAKLogger.error("[DataSyncManager]: Using client identity")
            let credential = URLCredential(identity: clientIdentity,
                                               certificates: nil,
                                                persistence: .none)
            challenge.sender?.use(credential, for: challenge)
            completionHandler(.useCredential, credential)

        } else if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            TAKLogger.debug("[DataSyncManager]: Server not trusted with default certs, seeing if we have custom ones")
            
            var optionalTrust: SecTrust?
            var customCerts: [SecCertificate] = []

            let trustCerts = SettingsStore.global.serverCertificateTruststore
            TAKLogger.debug("[DataSyncManager]: Truststore contains \(trustCerts.count) cert(s)")
            if !trustCerts.isEmpty {
                TAKLogger.debug("[DataSyncManager]: Loading Trust Store Certs")
                trustCerts.forEach { cert in
                    if let convertedCert = SecCertificateCreateWithData(nil, cert as CFData) {
                        customCerts.append(convertedCert)
                    }
                }
            }
            
            if !customCerts.isEmpty {
                TAKLogger.debug("[DataSyncManager]: We have custom certs, so disable hostname validation")
                let sslWithoutHostnamePolicy = SecPolicyCreateSSL(true, nil)
                let status = SecTrustCreateWithCertificates(customCerts as AnyObject,
                                                            sslWithoutHostnamePolicy,
                                                            &optionalTrust)
                guard status == errSecSuccess else {
                    completionHandler(.performDefaultHandling, nil)
                    return
                }
            }

            if optionalTrust != nil {
                TAKLogger.debug("[DataSyncManager]: Retrying with local truststore")
                let credential = URLCredential(trust: optionalTrust!)
                challenge.sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
            } else {
                TAKLogger.debug("[DataSyncManager]: No custom truststore ultimately found")
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}
