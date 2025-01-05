//
//  DataPackageManager.swift
//  TAKAware
//
//  Created by Cory Foy on 11/27/24.
//

import Foundation
import SwiftTAK

class TAKMissionPackage: Equatable {
    var creator: String
    var expiration: Date?
    var groups: String
    var hash: String
    var keywords: String
    var mimeType: String
    var name: String
    var size: String
    var time: Date?
    var user: String
    
    public init(
        creator: String,
        expiration: Date?,
        groups: String,
        hash: String,
        keywords: String,
        mimeType: String,
        name: String,
        size: String,
        time: Date?,
        user: String
    ) {
        self.creator = creator
        self.expiration = expiration
        self.groups = groups
        self.hash = hash
        self.keywords = keywords
        self.mimeType = mimeType
        self.name = name
        self.size = size
        self.time = time
        self.user = user
    }
    
    public static func == (lhs: TAKMissionPackage, rhs: TAKMissionPackage) -> Bool {
        return lhs.hash == rhs.hash &&
        lhs.creator == rhs.creator &&
        lhs.expiration == rhs.expiration &&
        lhs.groups == rhs.groups &&
        lhs.keywords == rhs.keywords &&
        lhs.mimeType == rhs.mimeType &&
        lhs.name == rhs.name &&
        lhs.size == rhs.size &&
        lhs.time == rhs.time &&
        lhs.user == rhs.user
    }
}

class DataPackageManager: APIRequestObject, ObservableObject {
    @Published var dataPackages: [TAKMissionPackage] = []
    @Published var isLoading = false
    @Published var isSendingUpdate = false
    @Published var isFinishedProcessingRemotePackage = false
    @Published var remotePackageProcessStatus: String = ""
    let ANON_CHANNEL_NAME = "__ANON__"
    
    func retrieveDataPackages() {
        if !isSendingUpdate {
            isLoading = true
        }
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.MISSION_PACKAGE_LIST_PATH)"
        TAKLogger.debug("[DataPackageManager] Requesting packages from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "get"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[DataPackageManager] Session Data Task Returned...")
            self.isLoading = false
            self.isSendingUpdate = false
            if error != nil {
                self.logDataPackageManagerError(error!.localizedDescription)
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.logDataPackageManagerError("Non success response code \((response as? HTTPURLResponse)?.statusCode.description ?? "UNKNOWN")")
                return
            }
            if let mimeType = response.mimeType,
                (mimeType == "application/json" || mimeType == "text/plain"),
                let data = data {
                self.storeDataPackageResponse(data)
            } else {
                self.logDataPackageManagerError("Unknown response from server when attempting package retrieval")
            }
        })

        task.resume()
    }
    
    /**
     {
         Creator = "";
         Expiration = none;
         Groups = "2024-State-Fair";
         Hash = e652f29c0b8d5df59d8f29a57119ad8630deedea12715c0491a3fb6b3c54cda3;
         Keywords = missionpackage;
         MimeType = "application/x-zip-compressed";
         Name = "FairPOIs.zip";
         Size = 16kB;
         Time = "2024-10-23 11:30:12.545";
         User = "comm1.wcem";
     }
     
     {
        "filename": "DP-ORG-SORS-CFOY-S24-1",
        "keywords": [
          "missionpackage"
        ],
        "mimeType": "application/x-zip-compressed",
        "name": "DP-ORG-SORS-CFOY-S24-1",
        "submissionTime": "2024-10-02T14:06:10.468Z",
        "submitter": "civtak2024",
        "uid": "fa916f67886612e7cc2003808eb3d11b266e03f49bbe46c42e35afe8b53f1a7f",
        "creatorUid": "ANDROID-07b42ddf9728082d",
        "hash": "fa916f67886612e7cc2003808eb3d11b266e03f49bbe46c42e35afe8b53f1a7f",
        "size": 1466,
        "tool": "public"
      },
     */
    
    func storeDataPackageResponse(_ data: Data) {
        TAKLogger.debug("[DataPackageManager] storeDataPackageResponse!")
        dataPackages = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let packageList = json["data"] as? [[String: Any]] else { return }
                for dataPackage in packageList {
                    let creator: String = dataPackage["Creator"] as? String ?? "UNKNOWN CREATOR"
                    let expirationString: String = dataPackage["Expiration"] as? String ?? "none"
                    let expiration: Date? = dateFormatter.date(from: expirationString)
                    let groups: String = dataPackage["Groups"] as? String ?? ""
                    let hash: String = dataPackage["Hash"] as? String ?? UUID().uuidString
                    let keywords: String = dataPackage["Keywords"] as? String ?? ""
                    let mimeType: String = dataPackage["MimeType"] as? String ?? ""
                    let name: String = dataPackage["Name"] as? String ?? "UNKNOWN NAME"
                    let size: String = dataPackage["Size"] as? String ?? "0"
                    let timeString: String = dataPackage["Time"] as? String ?? "none"
                    let time: Date? = dateFormatter.date(from: timeString)
                    let user: String = dataPackage["User"] as? String ?? "UNKNOWN USER"
                    
                    let dp = TAKMissionPackage(creator: creator, expiration: expiration, groups: groups, hash: hash, keywords: keywords, mimeType: mimeType, name: name, size: size, time: time, user: user)
                    dataPackages.append(dp)
                }
            }
        } catch {
            TAKLogger.error("[DataPackageManager]: Error processing data package list response \(error)")
        }
    }
    
    func deletePackage(dataPackage: DataPackage) {
        DataController.shared.deletePackage(dataPackage: dataPackage)
    }
    
    func hidePackage(dataPackage: DataPackage) {
        DataController.shared.changePackageVisibility(dataPackage: dataPackage, makeVisible: false)
    }
    
    func showPackage(dataPackage: DataPackage) {
        DataController.shared.changePackageVisibility(dataPackage: dataPackage, makeVisible: true)
    }
    
    func importRemotePackage(missionPackage: TAKMissionPackage) {
        remotePackageProcessStatus = ""
        isFinishedProcessingRemotePackage = false
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.MISSION_PACKAGE_FILE_PATH)/\(missionPackage.hash)"
        TAKLogger.debug("[DataPackageManager] Requesting file from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "get"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)
        
        let task = session.downloadTask(with: requestUrl) { localURL, urlResponse, error in
            if let localURL = localURL {
                TAKLogger.debug("[DataPackageManager] File downloaded, starting import")
                let parser = TAKDataPackageImporter(fileLocation: localURL, missionPackage: missionPackage)
                parser.parse()
                self.remotePackageProcessStatus = "Data package processed successfully!"
            } else {
                self.logDataPackageManagerError(error.debugDescription)
                self.remotePackageProcessStatus = "Data package could not be processed \(error.debugDescription)"
            }
            self.isFinishedProcessingRemotePackage = true
        }
        task.resume()
    }
    
    func logDataPackageManagerError(_ err: String) {
        TAKLogger.error("[DataPackageManager]: Error while trying to retrieve data packages \(err)")
        isLoading = false
        isSendingUpdate = false
    }
}
