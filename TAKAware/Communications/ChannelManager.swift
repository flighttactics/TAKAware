//
//  ChannelManager.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/10/24.
//

import Foundation

class TAKChannel: Equatable, Comparable {
    static func < (lhs: TAKChannel, rhs: TAKChannel) -> Bool {
        lhs.name.lowercased() < rhs.name.lowercased()
    }
    
    var name: String
    var active: Bool
    var direction: String?
    var created: Date?
    var type: String?
    var bitpos: Int?
    
    public init(name: String, active: Bool, direction: String? = nil, created: Date? = nil, type: String? = nil, bitpos: Int? = nil) {
        self.name = name
        self.active = active
        self.direction = direction
        self.created = created
        self.type = type
        self.bitpos = bitpos
    }
    
    public static func == (lhs: TAKChannel, rhs: TAKChannel) -> Bool {
        return lhs.name == rhs.name &&
        lhs.active == rhs.active &&
        lhs.direction == rhs.direction &&
        lhs.created == rhs.created &&
        lhs.type == rhs.type &&
        lhs.bitpos == rhs.bitpos
    }
}

class ChannelManager: APIRequestObject, ObservableObject {
    @Published var activeChannels: [TAKChannel] = []
    @Published var isLoading = false
    @Published var isSendingUpdate = false
    let ANON_CHANNEL_NAME = "__ANON__"
    
    func retrieveChannels() {
        if !isSendingUpdate {
            isLoading = true
        }
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.CHANNELS_LIST_PATH)?useCache=true&sendLatestSA=true"
        TAKLogger.debug("[ChannelManager] Requesting channels from \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "get"

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[ChannelManager] Session Data Task Returned...")
            self.isLoading = false
            self.isSendingUpdate = false
            if error != nil {
                self.logChannelsError(error!.localizedDescription)
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.logChannelsError("Non success response code \((response as? HTTPURLResponse)?.statusCode.description ?? "UNKNOWN")")
                return
            }
            if let mimeType = response.mimeType,
                (mimeType == "application/json" || mimeType == "text/plain"),
                let data = data {
                self.storeChannelsResponse(data)
            } else {
                self.logChannelsError("Unknown response from server when attempting channel retrieval")
            }
        })

        task.resume()
    }
    
    func storeChannelsResponse(_ data: Data) {
        TAKLogger.debug("[ChannelManager] storingChannelsResponse!")
        activeChannels = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let channelList = json["data"] as? [[String: Any]] else { return }
                for channelData in channelList {
                    var name = channelData["name"] as! String
                    if(name == ANON_CHANNEL_NAME) {
                        name = "Public"
                    }
                    
                    let active = channelData["active"] as! Int == 1
                    var direction = channelData["direction"] as! String
                    let createdString = channelData["created"] as! String
                    let created = dateFormatter.date(from: createdString)
                    let type = channelData["type"] as! String
                    let bitpos = channelData["bitpos"] as? Int
                    
                    if let existingChannel = activeChannels.first(where: {$0.name == name}) {
                        activeChannels.removeAll(where: {$0 == existingChannel})
                        direction = "BOTH"
                    }
                    
                    let channel = TAKChannel(name: name, active: active, direction: direction, created: created, type: type, bitpos: bitpos)
                    activeChannels.append(channel)
                }
                activeChannels = activeChannels.sorted()
            }
        } catch {
            TAKLogger.error("[ChannelManager]: Error processing channel list response \(error)")
        }
    }
    
    func logChannelsError(_ err: String) {
        TAKLogger.error("[ChannelManager]: Error while trying to retrieve channels \(err)")
        isLoading = false
        isSendingUpdate = false
    }
    
    func toggleChannel(channel: TAKChannel) {
        TAKLogger.debug("[ChannelManager] Request to toggle visibility of \(channel.name)")
        let updatedChannels = activeChannels
        updatedChannels.first(where: {$0 == channel})?.active.toggle()
        activeChannels = updatedChannels
        
        let activeBits: [Int] = activeChannels.filter({ $0.active }).map({ $0.bitpos! })
        let requestData = try? JSONSerialization.data(
            withJSONObject: activeBits,
            options: []
        )
        
        isSendingUpdate = true
        let requestURLString = "https://\(SettingsStore.global.takServerUrl):\(SettingsStore.global .takServerSecureAPIPort)\(AppConstants.CHANNELS_BIT_UPDATE_PATH)"
        TAKLogger.debug("[ChannelManager] Sending updated active channels to \(requestURLString)")
        let requestUrl = URL(string: requestURLString)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "put"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let session = URLSession(configuration: configuration,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)
        
        // We'll clear the map of all transient points
        // The server will flush us updated ones upon the channel update happening
        DataController.shared.clearTransientItems()

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            TAKLogger.debug("[ChannelManager] Session Data Task Returned...")
            self.isLoading = false
            if error != nil {
                self.logChannelsError(error!.localizedDescription)
                self.retrieveChannels()
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.logChannelsError("Non success response code \((response as? HTTPURLResponse)?.statusCode.description ?? "UNKNOWN")")
                self.retrieveChannels()
                return
            }
            TAKLogger.debug("[ChannelManager] Successfully updated channels. Requesting new list")
            self.retrieveChannels()
        })

        task.resume()
    }
}
