//
//  DataSyncManager.swift
//  TAKAware
//
//  Created by Cory Foy on 7/27/24.
//

import Foundation
import CoreData

struct DataSyncDataPackageRole {
    var permissions: [String] = []
    var type: String = ""
}

struct DataSyncDataPackageUid {
    var data: String = ""
    var timestamp: String = ""
    var creatorUid: String = ""
    var detail: DataSyncDataPackageUidDetail? = nil
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
    var uid: String // Should match data.uid
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
    var password: String? = nil
    var dbUid: UUID? = nil
    var token: String? = nil
}

class DataSyncManager: COTDataParser, ObservableObject, URLSessionDelegate {
    @Published var isDownloadingMission = false
    @Published var missionDownloadCompleted = false
    @Published var isSubscribingToMission = false
    @Published var isUnsubscribingFromMission = false
    @Published var missionSubscribeCompleted = false
    @Published var isLoadingMission = false
    @Published var isLoadingMissionList = false
    @Published var dataPackages: [DataSyncDataPackage] = []
    
    init(shouldListenForUpdates: Bool = false) {
        super.init()
        if shouldListenForUpdates {
            NotificationCenter.default.addObserver(forName: Notification.Name(AppConstants.NOTIFY_SERVER_CONNECTED), object: nil, queue: nil, using: serverConnectedNotification)
        }
    }
    
    func serverConnectedNotification(notification: Notification) {
        guard let serverName = notification.object as? String else {
            TAKLogger.error("[TAKTrackerApp] Server Connection notification received with no server name")
            return
        }
        resubscribeToMissionsForServer(serverName: serverName)
    }
    
    func resubscribeToMissionsForServer(serverName: String) {
        TAKLogger.debug("[DataSyncManager] Resubscribing missions for server \(serverName)")
        dataContext.perform {
            let fetchDsm: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
            fetchDsm.predicate = NSPredicate(format: "serverHost = %@", serverName as String)
            let results = try? self.dataContext.fetch(fetchDsm)
            results?.forEach { dataSyncMission in
                guard let missionName = dataSyncMission.name else { return }
                TAKLogger.debug("[DataSyncManager] Resubscribing to \(missionName)")
                self.subscribeToMission(missionName: missionName, password: dataSyncMission.password)
            }
        }
    }
    
    func retrieveLatestMissionCoT(mission: DataSyncDataPackage) {
        let missionPath = AppConstants.DATA_SYNC_MISSION_COT_DETAILS_PATH.replacingOccurrences(of: "{name}", with: mission.name)
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(missionPath)"
        TAKLogger.debug("[DataSyncManager] Retriving mission CoT from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "get"
        if mission.passwordProtected && mission.token != nil {
            TAKLogger.debug("[DataSyncManager] Adding bearer token for mission CoT retrieval at \(requestURLString)")
            request.setValue("Bearer \(mission.token!)", forHTTPHeaderField: "Authorization")
        }

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[DataSyncManager] Session Data Task Returned...")
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
                (mimeType == "application/xml" || mimeType == "text/plain"),
            let _ = data {
                TAKLogger.debug("[DataSyncManager] Parsing latest mission CoT")
                let streamParser = StreamParser()
                streamParser.parseCoTStream(dataStream: data, forceArchive: true)
            } else {
                self.logDataPackagesError("Unknown response from server when attempting data mission CoT retrieval")
            }
        })

        task.resume()
    }
    
    func downloadMission(missionName: String, password: String?) {
        retrieveMission(missionName: missionName, password: password, shouldSyncContents: true)
    }
    
    func downloadMission(mission: DataSyncDataPackage, shouldDbBack: Bool = false) {
        isDownloadingMission = true
        // Retrieve Mission
        // UIDs need to be stored as CoT messages
        // Content needs to be stored as files
        // Probably follow Data Package storing concepts
        // TODO: Don't redownload things we already have
        // TODO: Don't resync things we deleted unless forcing download?
        // TODO: Delete cotIcons we've previously downloaded but aren't here
        TAKLogger.debug("[DataSyncManager] downloading mission files for \(mission.name)")
        if shouldDbBack {
            storeDataSyncMission(missionName: mission.name, password: mission.password, missionPackage: mission)
        }
        dataContext.perform {
            let incomingUids = mission.uids.map { $0.data }
            
            // Clean up delete items
            let fetchCot: NSFetchRequest<COTData> = COTData.fetchRequest()
            fetchCot.predicate = NSPredicate(format: "NOT (cotUid IN %@)", incomingUids)
            let missingCots = try? self.dataContext.fetch(fetchCot)
            
            let fetchDSMissionItem: NSFetchRequest<DataSyncMissionItem> = DataSyncMissionItem.fetchRequest()
            fetchDSMissionItem.predicate = NSPredicate(format: "missionUUID = %@ AND NOT (uid IN %@)", (mission.dbUid ?? UUID()) as CVarArg, incomingUids)
            let missingMissionItems = try? self.dataContext.fetch(fetchDSMissionItem)
            
            missingMissionItems?.forEach { missionItem in
                if let matchingCot = missingCots?.first(where: {$0.cotUid == missionItem.uid}) {
                    self.dataContext.delete(matchingCot)
                }
                self.dataContext.delete(missionItem)
            }
            
            missingMissionItems?.forEach { self.dataContext.delete($0) }
            
            // Add new items
            // TODO: Once we've added them, we need to pull in the CoT from /missions/name/cot
            // TODO: When pulling in CoT, make sure it gets associated to these records
            mission.uids.forEach { uid in
                TAKLogger.debug("[DataSyncManager] Storing point for \(uid.data). DB Backed? \(shouldDbBack)")
                let fetchCot: NSFetchRequest<COTData> = COTData.fetchRequest()
                fetchCot.predicate = NSPredicate(format: "cotUid = %@", uid.data as String)
                let results = try? self.dataContext.fetch(fetchCot)
                
                let mapPointData: COTData!
                var mapPointUUID: UUID? = nil

                if results?.count == 0 {
                 } else {
                     mapPointData = results?.first
                     mapPointUUID = mapPointData?.id
                 }
                
                if shouldDbBack {
                    let fetchDSMission: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
                    fetchDSMission.predicate = NSPredicate(format: "name = %@", mission.name)
                    if let mission = try? self.dataContext.fetch(fetchDSMission).first {
                        let fetchDSMissionItem: NSFetchRequest<DataSyncMissionItem> = DataSyncMissionItem.fetchRequest()
                        fetchDSMissionItem.predicate = NSPredicate(format: "uid = %@", uid.data)
                        let results = try? self.dataContext.fetch(fetchDSMissionItem)
                        
                        let dsMissionItem: DataSyncMissionItem!

                        if results?.count == 0 {
                            dsMissionItem = DataSyncMissionItem(context: self.dataContext)
                            dsMissionItem.id = UUID()
                            dsMissionItem.cotUid = mapPointUUID
                            dsMissionItem.uid = uid.data
                            dsMissionItem.missionUUID = mission.id
                            dsMissionItem.isCOT = true
                         } else {
                             dsMissionItem = results?.first
                             dsMissionItem.cotUid = mapPointUUID
                         }
                    }
                }
            }

            do {
                try self.dataContext.save()
                self.retrieveLatestMissionCoT(mission: mission)
                DispatchQueue.main.async {
                    self.missionDownloadCompleted = true
                    self.isDownloadingMission = false
                }
            } catch {
                TAKLogger.error("[DataSyncManager] Invalid Data Context Save \(error)")
                DispatchQueue.main.async {
                    self.isDownloadingMission = false
                }
            }
        }
    }
    
    func storeDataSyncMission(missionName: String, password: String? = nil, missionPackage: DataSyncDataPackage? = nil) {
        TAKLogger.debug("[DataSyncManager] storing data sync mission files for \(missionName)")
        dataContext.perform {
            let fetchDsm: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
            fetchDsm.predicate = NSPredicate(format: "name = %@", missionName as String)
            let results = try? self.dataContext.fetch(fetchDsm)
            let mission: DataSyncMission
            if results?.count == 0 {
                mission = DataSyncMission(context: self.dataContext)
                mission.id = UUID()
                mission.serverHost = SettingsStore.global.takServerUrl
                mission.name = missionName
            } else {
                mission = results!.first!
            }
            
            mission.passwordProtected = (password != nil)
            mission.password = password
            
            if let missionPackage = missionPackage {
                // mission.createTime = missionPackage.createTime
                mission.creatorUID = missionPackage.creatorUid
                //mission.expiration = missionPackage.expiration
                mission.groups = missionPackage.groups.joined(separator: ",")
                mission.guid = missionPackage.guid
                mission.inviteOnly = (missionPackage.inviteOnly == "true")
                mission.keywords = missionPackage.keywords.joined(separator: ",")
                mission.missionDescription = missionPackage.description
                mission.token = missionPackage.token
            }
            
            do {
                try self.dataContext.save()
            } catch {
                TAKLogger.error("[DataSyncManager] Invalid Data Context Save \(error)")
            }
        }
    }
    
    func deleteDataSyncMission(missionName: String, deleteContents: Bool = false) {
        dataContext.perform {
            let fetchDsm: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
            fetchDsm.predicate = NSPredicate(format: "name = %@", missionName as String)
            let results = try? self.dataContext.fetch(fetchDsm)

            if let storedMission = results?.first {
                let fetchMissionItems: NSFetchRequest<DataSyncMissionItem> = DataSyncMissionItem.fetchRequest()
                fetchMissionItems.predicate = NSPredicate(format: "missionUUID = %@", storedMission.id! as CVarArg)
                let results = try? self.dataContext.fetch(fetchMissionItems)
                results?.forEach { self.dataContext.delete($0) }
                
                self.dataContext.delete(storedMission)
                if var dp = self.dataPackages.first {
                    DispatchQueue.main.async {
                        dp.dbUid = nil
                        self.dataPackages.removeAll()
                        self.dataPackages.append(dp)
                    }
                }
                TAKLogger.debug("[DataSyncManager] Mission \(missionName) deleted from DB")
            } else {
                TAKLogger.debug("[DataSyncManager] Mission \(missionName) not found when trying to delete from DB")
            }
        }
    }
    
    func unsubscribeFromMission(missionName: String, deleteContents: Bool = false) {
        DispatchQueue.main.async {
            self.isUnsubscribingFromMission = true
        }
        deleteDataSyncMission(missionName: missionName, deleteContents: deleteContents)
        let missionPath = AppConstants.DATA_SYNC_MISSION_UNSUBSCRIBE_PATH.replacingOccurrences(of: "{name}", with: missionName)
        let uidPath = "uid=\(AppConstants.getClientID())"
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(missionPath)&\(uidPath)"
        TAKLogger.debug("[DataSyncManager] Unsubscribing from mission via \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "delete"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[DataSyncManager] Session Data Task Returned...")
            self.isUnsubscribingFromMission = false
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
            let _ = data {
                TAKLogger.debug("[DataSyncManager] Successfully unsubscribed from mission")
            } else {
                self.logDataPackagesError("Unknown response from server when attempting data mission detail retrieval")
            }
        })

        task.resume()
    }
    
    // TODO: Mark this as subscribed in the database (unless already subscribed)
    // Note: This method will be called on reconnecting to a server to reestablish the sub
    func subscribeToMission(missionName: String, password: String? = nil) {
        DispatchQueue.main.async {
            self.isSubscribingToMission = true
        }
        storeDataSyncMission(missionName: missionName, password: password)
        let missionPath = AppConstants.DATA_SYNC_MISSION_SUBSCRIBE_PATH.replacingOccurrences(of: "{name}", with: missionName)
        let uidPath = "uid=\(AppConstants.getClientID())"
        let pwPath = password == nil ? "" : "&password=\(password!)"
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(missionPath)?\(uidPath)\(pwPath)"
        TAKLogger.debug("[DataSyncManager] Subscribing to mission from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "put"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[DataSyncManager] Session Data Task Returned...")
            self.isSubscribingToMission = false
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
            let _ = data {
                self.downloadMission(missionName: missionName, password: password)
            } else {
                self.logDataPackagesError("Unknown response from server when attempting data mission detail retrieval")
            }
        })

        task.resume()
    }
    
    func retrieveMission(missionName: String, password: String? = nil, shouldSyncContents: Bool = false) {
        isLoadingMission = true
        let missionPath = AppConstants.DATA_SYNC_MISSION_DETAILS_PATH.replacingOccurrences(of: "{name}", with: missionName)
        let pwPath = password == nil ? "" : "password=\(password!)"
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(missionPath)?\(pwPath)"
        TAKLogger.debug("[DataSyncManager] Requesting data mission details from \(requestURLString)")
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
            self.isLoadingMission = false
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
                Task {
                    await self.storeDataMissionDetailResponse(data, password: password, shouldSyncContents: shouldSyncContents)
                }
            } else {
                self.logDataPackagesError("Unknown response from server when attempting data mission detail retrieval")
            }
        })

        task.resume()
    }
    
    func storeDataMissionDetailResponse(_ response: Data, password: String? = nil, shouldSyncContents: Bool = false) async {
        TAKLogger.debug("[DataSyncManager] storeDataMissionDetailResponse!")
        DispatchQueue.main.async {
            self.dataPackages = []
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            try await dataContext.perform {
                if let json = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any] {
                    guard let packageList = json["data"] as? [[String: Any]] else { return }
                    for dataPackageData in packageList {
                        let name = dataPackageData["name"] as! String
                        
                        var dbUid: UUID? = nil
                        let fetchDsm: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
                        fetchDsm.predicate = NSPredicate(format: "name = %@", name as String)
                        let results = try? self.dataContext.fetch(fetchDsm)
                        if let storedMission = results?.first {
                            dbUid = storedMission.id
                        }
                        
                        let description = dataPackageData["description"] as! String
                        let creatorUid = dataPackageData["creatorUid"] as! String
                        let createTime = dataPackageData["createTime"] as! String
                        let passwordProtected = dataPackageData["passwordProtected"] as! Bool
                        let uids = dataPackageData["uids"] as! [[String: Any]]
                        let contents = dataPackageData["contents"] as! [[String: Any]]
                        let token = dataPackageData["token"] as? String
                        
                        /*
                         {
                         "data": "b39b0f95-f96f-46fc-a466-cde75143b100",
                         "timestamp": "2025-02-23T23:06:40.065Z",
                         "creatorUid": "ANDROID-07b42ddf9728082d",
                         "details": {
                         "type": "a-n-G",
                         "callsign": "Watagua Hospital",
                         "iconsetPath": "83198b4872a8c34eb9c549da8a4de5a28f07821185b39a2277948f66c24ac17a/WildFire/Airstrip or Airport.png",
                         "color": "-1",
                         "location": {
                         "lat": 36.1973079,
                         "lon": -81.6518124
                         }
                         */
                        let mappedUids: [DataSyncDataPackageUid] = uids.map { uid in
                            let detail: [String: Any]? = uid["details"] as? [String: Any]
                            var dsPackage = DataSyncDataPackageUid(
                                data: uid["data"] as? String ?? "",
                                timestamp: uid["timestamp"] as? String ?? "",
                                creatorUid: uid["creatorUid"] as? String ?? ""
                            )
                            
                            guard let detail = detail, let coords = detail["location"] as? [String: Any] else {
                                return dsPackage
                            }
                            
                            let dpCoords = LocationCoordinates(
                                lat: coords["lat"] as? Double ?? 0.0,
                                lon: coords["lon"] as? Double ?? 0.0
                            )
                            
                            let dpDetail = DataSyncDataPackageUidDetail(
                                type: detail["type"] as? String ?? "",
                                callsign: detail["callsign"] as? String ?? "",
                                iconsetPath: detail["iconsetPath"] as? String ?? "",
                                color: detail["color"] as? String ?? "",
                                location: dpCoords
                            )
                            
                            dsPackage.detail = dpDetail
                            
                            return dsPackage
                        }
                        
                        let mappedContents: [DataSyncDataPackageContent] = contents.map { content in
                            let detail: [String: Any]? = content["data"] as? [String: Any]
                            let uid = detail?["uid"] as? String ?? UUID().uuidString
                            return DataSyncDataPackageContent(
                                uid: uid,
                                data: DataSyncDataPackageContentData(
                                    mimeType: detail?["mimeType"] as? String ?? "",
                                    name: detail?["name"] as? String ?? "UNKNOWN",
                                    uid: uid,
                                    size: detail?["size"] as? Int ?? 0
                                ),
                                timestamp: content["timestamp"] as? String ?? "",
                                creatorUid: content["creatorUid"] as? String ?? ""
                            )
                        }
                        let dataPackage = DataSyncDataPackage(
                            name: name,
                            description: description,
                            creatorUid: creatorUid,
                            createTime: createTime,
                            uids: mappedUids,
                            contents: mappedContents,
                            passwordProtected: passwordProtected,
                            password: password,
                            dbUid: dbUid,
                            token: token
                        )
                        DispatchQueue.main.async {
                            self.dataPackages.append(dataPackage)
                            if shouldSyncContents {
                                self.downloadMission(mission: dataPackage, shouldDbBack: true)
                            }
                        }
                    }
                }
            }
        } catch {
            TAKLogger.error("[DataSyncManager]: Error processing data sync mission list response \(error)")
        }
    }
    
    func retrieveMissions() {
        isLoadingMissionList = true
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.DATA_SYNC_MISSION_LIST_PATH)"
        TAKLogger.debug("[DataSyncManager] Requesting missions from \(requestURLString)")
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
            self.isLoadingMissionList = false
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
                Task {
                    await self.storeDataPackagesResponse(data)
                }
            } else {
                self.logDataPackagesError("Unknown response from server when attempting mission list retrieval")
            }
        })

        task.resume()
    }
    
    func storeDataPackagesResponse(_ data: Data) async {
        TAKLogger.debug("[DataSyncManager] storingDataSyncResponse!")
        DispatchQueue.main.async {
            self.dataPackages = []
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            try await dataContext.perform {
                let fetchDsm: NSFetchRequest<DataSyncMission> = DataSyncMission.fetchRequest()
                let results = try? self.dataContext.fetch(fetchDsm)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    guard let packageList = json["data"] as? [[String: Any]] else { return }
                    for dataPackageData in packageList {
                        let name = dataPackageData["name"] as! String
                        let storedMission = results?.first(where: {$0.name == name})
                        var dbUid: UUID? = nil
                        var password: String? = nil
                        if storedMission != nil {
                            dbUid = storedMission?.id
                            password = storedMission?.password
                        }
                        let description = dataPackageData["description"] as! String
                        let creatorUid = dataPackageData["creatorUid"] as! String
                        let createTime = dataPackageData["createTime"] as! String
                        let passwordProtected = dataPackageData["passwordProtected"] as! Bool
                        let token = dataPackageData["token"] as? String
                        let dataPackage = DataSyncDataPackage(
                            name: name,
                            description: description,
                            creatorUid: creatorUid,
                            createTime: createTime,
                            passwordProtected: passwordProtected,
                            password: password,
                            dbUid: dbUid,
                            token: token
                        )
                        DispatchQueue.main.async {
                            self.dataPackages.append(dataPackage)
                        }
                    }
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
