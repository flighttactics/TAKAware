//
//  SettingsStore.swift
//  TAKTracker
//
//  Created by Cory Foy on 7/12/23.
//  Adapted from https://blog.maximeheckel.com/snippets/2020-11-27-storing-user-settings-swift/
//

import MapKit
import SwiftTAK
import UIKit

enum MapLabelDisplayOption: Int {
    case Truncate
    case ShowFullLabel
    case Scroll
}

struct ServerConfiguration: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var host: String
    var port: String
    var csrPort: String
    var secureAPIPort: String
    var userCertificate: Data
    var serverCertificate: Data
    var serverCertificateTruststore: [Data]

    init(
        id: UUID = UUID(),
        name: String = "",
        host: String,
        port: String = TAKConstants.DEFAULT_STREAMING_PORT,
        csrPort: String = TAKConstants.DEFAULT_CSR_PORT,
        secureAPIPort: String = TAKConstants.DEFAULT_SECURE_API_PORT,
        userCertificate: Data = Data(),
        serverCertificate: Data = Data(),
        serverCertificateTruststore: [Data] = []
    ) {
        self.id = id
        self.name = name.isEmpty ? host : name
        self.host = host
        self.port = port
        self.csrPort = csrPort
        self.secureAPIPort = secureAPIPort
        self.userCertificate = userCertificate
        self.serverCertificate = serverCertificate
        self.serverCertificateTruststore = serverCertificateTruststore
    }
}

class SettingsStore: ObservableObject {
    static let global = SettingsStore()
    
    static func generateDefaultCallSign() -> String {
        
        let appendValue: String = Int.random(in: 1..<40).description
        
        guard let firstIdBlock = AppConstants.getClientID().split(separator: "-").first else {
            return "TRACKER-\(appendValue)"
        }
        
        if(firstIdBlock.isEmpty) {
            return "TRACKER-\(appendValue)"
        }
        
        return "TRACKER-\(String(firstIdBlock))"
    }
    
    
    func storeIdentity(identity: SecIdentity, label: String) {
        // Delete only the existing identity with this specific label
        let deleteQuery: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                          kSecAttrLabel as String: label]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [kSecValueRef as String: identity,
                                       kSecAttrLabel as String: label]
        TAKLogger.debug("[SettingsStore]: Adding Identity to Keychain with label \(label)")
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            TAKLogger.error("[SettingsStore]: Error adding identity to keychain \(String(describing: status))")
            return
        }
    }
    
    func retrieveIdentity(label: String) -> SecIdentity? {
        let getquery: [String: Any] = [kSecClass as String:  kSecClassIdentity,
                                       kSecAttrLabel as String: label,
                                       kSecReturnRef as String: kCFBooleanTrue!]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess, let item = item else {
            TAKLogger.error("[SettingsStore]: Identity was not stored in the keychain \(String(describing: status))")
            return nil
        }
        // CFTypeRef is always bridgeable to SecIdentity when kSecClassIdentity is used
        let clientIdentity = item as! SecIdentity
        return clientIdentity
    }
    
    func clearAllIdentities() {
        TAKLogger.debug("[SettingsStore]: Clearing out all existing identities")
        let cleanUpQuery: [String: Any] = [kSecClass as String:  kSecClassIdentity]
        SecItemDelete(cleanUpQuery as CFDictionary)
    }
    
    // MARK: - Keychain helpers for sensitive strings
    
    private static let keychainService = "com.flighttactics.TAKAware"
    
    private func keychainSave(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            TAKLogger.error("[SettingsStore]: Keychain save failed for \(key): \(status)")
        }
    }
    
    private func keychainLoad(key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let str = String(data: data, encoding: .utf8) else {
            return ""
        }
        return str
    }
    
    private func keychainDelete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    /// Migrate passwords from UserDefaults to Keychain (one-time)
    private func migratePasswordsToKeychain() {
        let keys = ["serverCertificatePassword", "userCertificatePassword", "takServerUsername", "takServerPassword"]
        for key in keys {
            if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
                if keychainLoad(key: key).isEmpty {
                    keychainSave(key: key, value: value)
                    TAKLogger.debug("[SettingsStore]: Migrated \(key) to Keychain")
                }
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    func clearConnection() {
        activeServerId = nil
        isConnectedToServer = false
        isConnectingToServer = false
        shouldTryReconnect = false
        connectionStatus = ConnectionStatus.Disconnected.rawValue
        takServerUrl = ""
        takServerUsername = ""
        takServerPassword = ""
        takServerPort = TAKConstants.DEFAULT_STREAMING_PORT
        takServerCSRPort = TAKConstants.DEFAULT_CSR_PORT
        takServerSecureAPIPort = TAKConstants.DEFAULT_SECURE_API_PORT
        serverCertificateTruststore = []
        keychainDelete(key: "serverCertificatePassword")
        keychainDelete(key: "userCertificatePassword")
        keychainDelete(key: "takServerUsername")
        keychainDelete(key: "takServerPassword")
        clearAllIdentities()
    }

    // MARK: - Multi-Server Management

    @Published var serverConfigurations: [ServerConfiguration] {
        didSet {
            if let encoded = try? JSONEncoder().encode(serverConfigurations) {
                UserDefaults.standard.set(encoded, forKey: "serverConfigurations")
            }
        }
    }

    @Published var activeServerId: UUID? {
        didSet {
            UserDefaults.standard.set(activeServerId?.uuidString, forKey: "activeServerId")
        }
    }

    func saveServerConfiguration(
        _ config: ServerConfiguration,
        username: String = "",
        password: String = "",
        certPassword: String = ""
    ) {
        keychainSave(key: "server-\(config.id)-username", value: username)
        keychainSave(key: "server-\(config.id)-password", value: password)
        keychainSave(key: "server-\(config.id)-certpwd", value: certPassword)
        if let idx = serverConfigurations.firstIndex(where: { $0.id == config.id }) {
            serverConfigurations[idx] = config
        } else {
            serverConfigurations.append(config)
        }
    }

    func deleteServerConfiguration(id: UUID) {
        keychainDelete(key: "server-\(id)-username")
        keychainDelete(key: "server-\(id)-password")
        keychainDelete(key: "server-\(id)-certpwd")
        if let config = serverConfigurations.first(where: { $0.id == id }) {
            let deleteQuery: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                              kSecAttrLabel as String: config.host]
            SecItemDelete(deleteQuery as CFDictionary)
        }
        serverConfigurations.removeAll { $0.id == id }
        if activeServerId == id { clearConnection() }
    }

    func activateServer(id: UUID) {
        guard let config = serverConfigurations.first(where: { $0.id == id }) else { return }
        activeServerId = id
        takServerUrl = config.host
        takServerPort = config.port
        takServerCSRPort = config.csrPort
        takServerSecureAPIPort = config.secureAPIPort
        serverCertificate = config.serverCertificate
        serverCertificateTruststore = config.serverCertificateTruststore
        userCertificate = config.userCertificate
        takServerUsername = keychainLoad(key: "server-\(id)-username")
        takServerPassword = keychainLoad(key: "server-\(id)-password")
        userCertificatePassword = keychainLoad(key: "server-\(id)-certpwd")
        if retrieveIdentity(label: config.host) == nil && !config.userCertificate.isEmpty {
            reimportIdentity(
                p12Data: config.userCertificate,
                password: keychainLoad(key: "server-\(id)-certpwd"),
                label: config.host
            )
        }
        takServerChanged = true
        takServerEnabled = true
    }

    /// Snapshot current flat SettingsStore state into the server list.
    /// Call after any successful enrollment or server update.
    @discardableResult
    func captureCurrentAsServerConfiguration(name: String = "") -> ServerConfiguration {
        let resolvedId = activeServerId ?? UUID()
        let displayName = name.isEmpty ? (takServerUrl.isEmpty ? "Server" : takServerUrl) : name
        let config = ServerConfiguration(
            id: resolvedId,
            name: displayName,
            host: takServerUrl,
            port: takServerPort,
            csrPort: takServerCSRPort,
            secureAPIPort: takServerSecureAPIPort,
            userCertificate: userCertificate,
            serverCertificate: serverCertificate,
            serverCertificateTruststore: serverCertificateTruststore
        )
        saveServerConfiguration(
            config,
            username: takServerUsername,
            password: takServerPassword,
            certPassword: userCertificatePassword
        )
        activeServerId = config.id
        return config
    }

    private func reimportIdentity(p12Data: Data, password: String, label: String) {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let identityRef = array.first?[kSecImportItemIdentity as String]
        else {
            TAKLogger.error("[SettingsStore]: P12 reimport failed for \(label): \(status)")
            return
        }
        storeIdentity(identity: identityRef as! SecIdentity, label: label)
    }

    private func migrateLegacyServerIfNeeded() {
        guard serverConfigurations.isEmpty && !takServerUrl.isEmpty else { return }
        let config = ServerConfiguration(
            name: takServerUrl,
            host: takServerUrl,
            port: takServerPort,
            csrPort: takServerCSRPort,
            secureAPIPort: takServerSecureAPIPort,
            userCertificate: userCertificate,
            serverCertificate: serverCertificate,
            serverCertificateTruststore: serverCertificateTruststore
        )
        saveServerConfiguration(
            config,
            username: takServerUsername,
            password: takServerPassword,
            certPassword: userCertificatePassword
        )
        activeServerId = config.id
        TAKLogger.debug("[SettingsStore]: Migrated legacy server config for \(takServerUrl)")
    }

    @Published var callSign: String {
        didSet {
            UserDefaults.standard.set(callSign, forKey: "callSign")
        }
    }
    
    @Published var team: String {
        didSet {
            UserDefaults.standard.set(team, forKey: "team")
        }
    }
    
    @Published var role: String {
        didSet {
            UserDefaults.standard.set(role, forKey: "role")
        }
    }
    
    @Published var phoneNumber: String {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        }
    }
    
    @Published var cotType: String {
        didSet {
            UserDefaults.standard.set(cotType, forKey: "cotType")
        }
    }
    
    @Published var cotHow: String {
        didSet {
            UserDefaults.standard.set(cotHow, forKey: "cotHow")
        }
    }
    
    @Published var takServerUrl: String {
        didSet {
            UserDefaults.standard.set(takServerUrl, forKey: "takServerUrl")
        }
    }
    
    @Published var takServerPort: String {
        didSet {
            UserDefaults.standard.set(takServerPort, forKey: "takServerPort")
        }
    }
    
    @Published var takServerCSRPort: String {
        didSet {
            UserDefaults.standard.set(takServerCSRPort, forKey: "takServerCSRPort")
        }
    }
    
    @Published var takServerSecureAPIPort: String {
        didSet {
            UserDefaults.standard.set(takServerSecureAPIPort, forKey: "takServerSecureAPIPort")
        }
    }
    
    @Published var takServerProtocol: String {
        didSet {
            UserDefaults.standard.set(takServerProtocol, forKey: "takServerProtocol")
        }
    }
    
    @Published var staleTimeMinutes: Double {
        didSet {
            UserDefaults.standard.set(staleTimeMinutes, forKey: "staleTimeMinutes")
        }
    }
    
    @Published var broadcastIntervalSeconds: Double {
        didSet {
            UserDefaults.standard.set(broadcastIntervalSeconds, forKey: "broadcastIntervalSeconds")
        }
    }
    
    @Published var disableScreenSleep: Bool {
        didSet {
            UserDefaults.standard.set(disableScreenSleep, forKey: "disableScreenSleep")
        }
    }
    
    @Published var serverCertificateTruststore: [Data] {
        didSet {
            UserDefaults.standard.set(serverCertificateTruststore, forKey: "serverCertificateTruststore")
            UserDefaults.standard.set(true, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var serverCertificate: Data {
        didSet {
            UserDefaults.standard.set(serverCertificate, forKey: "serverCertificate")
            UserDefaults.standard.set(true, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var serverCertificatePassword: String {
        didSet {
            keychainSave(key: "serverCertificatePassword", value: serverCertificatePassword)
            UserDefaults.standard.set(true, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var userCertificate: Data {
        didSet {
            UserDefaults.standard.set(userCertificate, forKey: "userCertificate")
            UserDefaults.standard.set(true, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var userCertificatePassword: String {
        didSet {
            keychainSave(key: "userCertificatePassword", value: userCertificatePassword)
            UserDefaults.standard.set(true, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var takServerUsername: String {
        didSet {
            keychainSave(key: "takServerUsername", value: takServerUsername)
        }
    }
    
    @Published var takServerPassword: String {
        didSet {
            keychainSave(key: "takServerPassword", value: takServerPassword)
        }
    }
    
    @Published var shouldTryReconnect: Bool {
        didSet {
            UserDefaults.standard.set(shouldTryReconnect, forKey: "shouldTryReconnect")
        }
    }
    
    @Published var isConnectedToServer: Bool {
        didSet {
            UserDefaults.standard.set(isConnectedToServer, forKey: "isConnectedToServer")
        }
    }
    
    @Published var isConnectingToServer: Bool {
        didSet {
            UserDefaults.standard.set(isConnectingToServer, forKey: "isConnectingToServer")
        }
    }
    
    @Published var connectionStatus: String {
        didSet {
            UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")
        }
    }
    
    @Published var takServerChanged: Bool {
        didSet {
            UserDefaults.standard.set(takServerChanged, forKey: "takServerChanged")
        }
    }
    
    @Published var takServerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(takServerEnabled, forKey: "takServerEnabled")
            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_TAK_SERVER_AVAILABILITY_TOGGLED), object: nil)
        }
    }
    
    // Note: overlayActiveMapSources in MapView also updates this value directly without going through here
    @Published var mapTypeDisplay: UInt {
        didSet {
            UserDefaults.standard.set(mapTypeDisplay, forKey: "mapTypeDisplay")
            NotificationCenter.default.post(name: Notification.Name(AppConstants.NOTIFY_MAP_SOURCE_UPDATED), object: nil)
        }
    }
    
    @Published var isAlertActivated: Bool {
        didSet {
            UserDefaults.standard.set(isAlertActivated, forKey: "isAlertActivated")
        }
    }
    
    @Published var activeAlertType: String {
        didSet {
            UserDefaults.standard.set(activeAlertType, forKey: "activeAlertType")
        }
    }
    
    @Published var hasOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(hasOnboarded, forKey: "hasOnboarded")
        }
    }
    
    @Published var lastAppVersionRun: String {
        didSet {
            UserDefaults.standard.set(lastAppVersionRun, forKey: "lastAppVersionRun")
        }
    }
    
    @Published var preferredInterface: String {
        didSet {
            UserDefaults.standard.set(preferredInterface, forKey: "preferredInterface")
        }
    }
    
    @Published var enableTrafficDisplay: Bool {
        didSet {
            UserDefaults.standard.set(enableTrafficDisplay, forKey: "enableTrafficDisplay")
        }
    }
    
    @Published var enable2525ForRoles: Bool {
        didSet {
            UserDefaults.standard.set(enable2525ForRoles, forKey: "enable2525ForRoles")
            DataController.shared.clearTransientItems()
        }
    }
    
    @Published var mapLabelDisplayOption: MapLabelDisplayOption {
        didSet {
            UserDefaults.standard.set(mapLabelDisplayOption.rawValue, forKey: "mapLabelDisplayOption")
        }
    }
    
    var mapLabelShouldTruncate: Bool {
        get { mapLabelDisplayOption == .Truncate }
        set {
            mapLabelDisplayOption = newValue ? MapLabelDisplayOption.Truncate : MapLabelDisplayOption.ShowFullLabel
        }
    }

    private init() {
        let defaultSign = SettingsStore.generateDefaultCallSign()
        self.lastAppVersionRun = (UserDefaults.standard.object(forKey: "lastAppVersionRun") == nil ? "" : UserDefaults.standard.object(forKey: "lastAppVersionRun") as! String)
        
        self.enable2525ForRoles = (UserDefaults.standard.object(forKey: "enable2525ForRoles") == nil ? false : UserDefaults.standard.object(forKey: "enable2525ForRoles") as! Bool)
        
        self.mapLabelDisplayOption = (UserDefaults.standard.object(forKey: "mapLabelDisplayOption") == nil ? .Truncate : MapLabelDisplayOption(rawValue: UserDefaults.standard.object(forKey: "mapLabelDisplayOption") as! Int) ?? .Truncate)
        
        self.enableTrafficDisplay = (UserDefaults.standard.object(forKey: "enableTrafficDisplay") == nil ? true : UserDefaults.standard.object(forKey: "enableTrafficDisplay") as! Bool)
        
        self.preferredInterface = (UserDefaults.standard.object(forKey: "preferredInterface") == nil ? "" : UserDefaults.standard.object(forKey: "preferredInterface") as! String)
        
        self.callSign = (UserDefaults.standard.object(forKey: "callSign") == nil ? defaultSign : UserDefaults.standard.object(forKey: "callSign") as! String)
        
        self.team = (UserDefaults.standard.object(forKey: "team") == nil ? TeamColor.Cyan.rawValue : UserDefaults.standard.object(forKey: "team") as! String)
        
        self.role = (UserDefaults.standard.object(forKey: "role") == nil ? TeamRole.TeamMember.rawValue : UserDefaults.standard.object(forKey: "role") as! String)
        
        self.phoneNumber = (UserDefaults.standard.object(forKey: "phoneNumber") == nil ? "" : UserDefaults.standard.object(forKey: "phoneNumber") as! String)
        
        self.cotType = (UserDefaults.standard.object(forKey: "cotType") == nil ? "a-f-G-U-C" : UserDefaults.standard.object(forKey: "cotType") as! String)
        
        self.cotHow = (UserDefaults.standard.object(forKey: "cotHow") == nil ? "m-g" : UserDefaults.standard.object(forKey: "cotHow") as! String)
        
        self.takServerUrl = (UserDefaults.standard.object(forKey: "takServerUrl") == nil ? "" : UserDefaults.standard.object(forKey: "takServerUrl") as! String)
        
        self.takServerPort = (UserDefaults.standard.object(forKey: "takServerPort") == nil ? TAKConstants.DEFAULT_STREAMING_PORT : UserDefaults.standard.object(forKey: "takServerPort") as! String)
        
        self.takServerCSRPort = (UserDefaults.standard.object(forKey: "takServerCSRPort") == nil ? TAKConstants.DEFAULT_CSR_PORT : UserDefaults.standard.object(forKey: "takServerCSRPort") as! String)
        
        self.takServerSecureAPIPort = (UserDefaults.standard.object(forKey: "takServerSecureAPIPort") == nil ? TAKConstants.DEFAULT_SECURE_API_PORT : UserDefaults.standard.object(forKey: "takServerSecureAPIPort") as! String)
        
        self.takServerProtocol = (UserDefaults.standard.object(forKey: "takServerProtocol") == nil ? "ssl" : UserDefaults.standard.object(forKey: "takServerProtocol") as! String)
        
        self.staleTimeMinutes = (UserDefaults.standard.object(forKey: "staleTimeMinutes") == nil ? 5.0 : UserDefaults.standard.object(forKey: "staleTimeMinutes") as! Double)
        
        self.broadcastIntervalSeconds = (UserDefaults.standard.object(forKey: "broadcastIntervalSeconds") == nil ? 10.0 : UserDefaults.standard.object(forKey: "broadcastIntervalSeconds") as! Double)
        
        self.disableScreenSleep = (UserDefaults.standard.object(forKey: "disableScreenSleep") == nil ? true : UserDefaults.standard.object(forKey: "disableScreenSleep") as! Bool)
        
        self.serverCertificateTruststore = (UserDefaults.standard.object(forKey: "serverCertificateTruststore") == nil ? [] : UserDefaults.standard.object(forKey: "serverCertificateTruststore") as! [Data])
        
        self.serverCertificate = (UserDefaults.standard.object(forKey: "serverCertificate") == nil ? Data() : UserDefaults.standard.object(forKey: "serverCertificate") as! Data)
        
        self.serverCertificatePassword = ""
        
        self.userCertificate = (UserDefaults.standard.object(forKey: "userCertificate") == nil ? Data() : UserDefaults.standard.object(forKey: "userCertificate") as! Data)
        
        self.userCertificatePassword = ""
        
        self.takServerUsername = ""
        
        self.takServerPassword = ""
        
        self.shouldTryReconnect = (UserDefaults.standard.object(forKey: "shouldTryReconnect") == nil ? true : UserDefaults.standard.object(forKey: "shouldTryReconnect") as! Bool)
        
        self.isConnectedToServer = (UserDefaults.standard.object(forKey: "isConnectedToServer") == nil ? false : UserDefaults.standard.object(forKey: "isConnectedToServer") as! Bool)
        
        self.isConnectingToServer = (UserDefaults.standard.object(forKey: "isConnectingToServer") == nil ? false : UserDefaults.standard.object(forKey: "isConnectingToServer") as! Bool)
        
        self.connectionStatus = (UserDefaults.standard.object(forKey: "connectionStatus") == nil ? "Disconnected" : UserDefaults.standard.object(forKey: "connectionStatus") as! String)
        
        self.takServerChanged = (UserDefaults.standard.object(forKey: "takServerChanged") == nil ? false : UserDefaults.standard.object(forKey: "takServerChanged") as! Bool)
        
        self.takServerEnabled = (UserDefaults.standard.object(forKey: "takServerEnabled") == nil ? true : UserDefaults.standard.object(forKey: "takServerEnabled") as! Bool)
        
        self.mapTypeDisplay = (UserDefaults.standard.object(forKey: "mapTypeDisplay") == nil ? MKMapType.standard.rawValue : UserDefaults.standard.object(forKey: "mapTypeDisplay") as! UInt)

        self.isAlertActivated = (UserDefaults.standard.object(forKey: "isAlertActivated") == nil ? false : UserDefaults.standard.object(forKey: "isAlertActivated") as! Bool)
        
        self.activeAlertType = (UserDefaults.standard.object(forKey: "activeAlertType") == nil ? "" : UserDefaults.standard.object(forKey: "activeAlertType") as! String)
        
        self.hasOnboarded = (UserDefaults.standard.object(forKey: "hasOnboarded") == nil ? false : UserDefaults.standard.object(forKey: "hasOnboarded") as! Bool)
        
        // Multi-server list
        if let data = UserDefaults.standard.data(forKey: "serverConfigurations"),
           let configs = try? JSONDecoder().decode([ServerConfiguration].self, from: data) {
            self.serverConfigurations = configs
        } else {
            self.serverConfigurations = []
        }

        if let idStr = UserDefaults.standard.string(forKey: "activeServerId"),
           let id = UUID(uuidString: idStr) {
            self.activeServerId = id
        } else {
            self.activeServerId = nil
        }

        // Migrate passwords from UserDefaults to Keychain, then load from Keychain
        migratePasswordsToKeychain()
        self.serverCertificatePassword = keychainLoad(key: "serverCertificatePassword")
        self.userCertificatePassword = keychainLoad(key: "userCertificatePassword")
        self.takServerUsername = keychainLoad(key: "takServerUsername")
        self.takServerPassword = keychainLoad(key: "takServerPassword")

        migrateLegacyServerIfNeeded()
    }
}
