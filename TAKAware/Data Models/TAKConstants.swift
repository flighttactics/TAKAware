//
//  TAKConstants.swift
//  TAKTracker
//
//  Created by Cory Foy on 8/25/23.
//

import Foundation
import UIKit

enum AppDirectories: String {
    case overlays = "overlays"
    case dataPackages = "datapackages"
    case iconsets = "iconsets"
}

struct AppConstants {
    // App Information
    static let TAK_PLATFORM = "TAKAware-CIV"    
    
    // Ports
    static let DEFAULT_CSR_PORT = "8446"
    static let DEFAULT_WEB_PORT = "8443"
    static let DEFAULT_STREAMING_PORT = "8089"
    static let UDP_BROADCAST_PORT = "6969"
    
    // Paths
    static let MANIFEST_FILE = "manifest.xml"
    static let PREF_FILE_SUFFIX = ".pref"
    
    static let CERT_CONFIG_PATH = "/Marti/api/tls/config"
    static let CSR_PATH = "/Marti/api/tls/signClient/v2?clientUid=$UID&version=$VERSION"
    static let CHANNELS_LIST_PATH = "/Marti/api/groups/all"
    static let CHANNELS_BIT_UPDATE_PATH = "/Marti/api/groups/activebits"
    
    static let DATA_SYNC_MISSION_LIST_PATH = "/Marti/api/missions?passwordProtected=true" // GET
    static let DATA_SYNC_MISSION_DETAILS_PATH = "/Marti/api/missions/{name}" // GET
    static let DATA_SYNC_MISSION_TOKEN_PATH = "/Marti/api/missions/{name}/token" // GET
    static let DATA_SYNC_MISSION_COT_DETAILS_PATH = "/Marti/api/missions/{name}/cot" // GET
    static let DATA_SYNC_MISSION_SUBSCRIBE_PATH = "/Marti/api/missions/{name}/subscription" // PUT
    static let DATA_SYNC_MISSION_UNSUBSCRIBE_PATH = "/Marti/api/missions/{name}/subscription?disconnectOnly=true" // DELETE

    static let MISSION_PACKAGE_LIST_PATH = "/Marti/api/files/metadata?missionPackage=true"
    //static let MISSION_PACKAGE_LIST_PATH = "/Marti/sync/search?keywords=missionpackage&tool=public"
    static let MISSION_PACKAGE_FILE_PATH = "/Marti/api/files" // Must append the hash to the end
    
    static let UDP_BROADCAST_URL = "239.2.3.1"
    
    static let NOTIFY_KML_FILE_ADDED = "KMLFileAdded"
    static let NOTIFY_KML_FILE_UPDATED = "KMLFileUpdated"
    static let NOTIFY_KML_FILE_REMOVED = "KMLFileRemoved"
    static let NOTIFY_COT_ADDED = "COTAdded"
    static let NOTIFY_COT_UPDATED = "COTUpdated"
    static let NOTIFY_COT_REMOVED = "COTRemoved"
    static let NOTIFY_APP_ACTIVE = "AppScenePhaseActive"
    static let NOTIFY_APP_INACTIVE = "AppScenePhaseInactive"
    static let NOTIFY_APP_BACKGROUND = "AppScenePhaseBackground"
    static let NOTIFY_SCROLL_TO_KML = "ScrollToKML"
    static let NOTIFY_SCROLL_TO_COORDINATE = "ScrollToCoordinate"
    static let NOTIFY_SCROLL_TO_CONTACT = "ScrollToContact"
    static let NOTIFY_MAP_SOURCE_UPDATED = "MapSourceUpdated"
    static let NOTIFY_SERVER_CONNECTED = "TAKServerConnected"
    static let NOTIFY_PHONE_ACTION_REQUESTED = "PhoneActionRequested"
    static let NOTIFY_TAK_SERVER_AVAILABILITY_TOGGLED = "TAKServerAvailabilityToggled"
    
    static func appDirectoryFor(_ directory: AppDirectories) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(directory.rawValue)
    }
    
    // Helper Functions
    static func certificateSigningPath(clientUid: String, appVersion: String) -> String {
        return AppConstants.CSR_PATH
            .replacingOccurrences(of: "$UID", with: clientUid)
            .replacingOccurrences(of: "$VERSION", with: appVersion)
    }
    
    static func getAppReleaseVersion() -> String {
        if let appInfo = Bundle.main.infoDictionary {
            if let appVersion = appInfo["CFBundleShortVersionString"] as? String {
                return appVersion
            }
        }
        return "1.u"
    }
    
    static func getAppReleaseAndBuildVersion() -> String {
        if let appInfo = Bundle.main.infoDictionary {
            if let appVersion = appInfo["CFBundleShortVersionString"] as? String,
               let buildNumber = appInfo["CFBundleVersion"] as? String {
                return "\(appVersion).\(buildNumber)"
            }
        }
        return "0.0.u"
    }
    
    static func getAppName() -> String {
        if let appInfo = Bundle.main.infoDictionary {
            if let appName = appInfo["CFBundleName"] as? String {
                return appName
            }
        }
        return TAK_PLATFORM
    }
    
    static func getClientID() -> String {
        if let identifier = UIDevice.current.identifierForVendor {
            return identifier.uuidString
        }
        TAKLogger.debug("Failed to get identifierForVendor. Returning random clientID")
        return UUID().uuidString
    }
    
    static func getPhoneModel() -> String {
        return UIDevice.current.model
    }
    
    static func getPhoneOS() -> String {
        return UIDevice.current.systemName
    }
    
    static func getPhoneBatteryStatus() -> Float {
        if (UIDevice.current.isBatteryMonitoringEnabled) {
            return UIDevice.current.batteryLevel * 100
        } else {
            TAKLogger.debug("Battery Monitoring is not enabled for this device!")
            return 0.0
        }
    }
}
