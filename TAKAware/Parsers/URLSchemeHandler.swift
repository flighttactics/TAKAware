//
//  URLSchemeHandler.swift
//  TAKAware
//
//  Created by Craig Clayton on 5/26/25.
//
import Foundation


final class URLSchemeHandler {
    static let shared = URLSchemeHandler()

    private let aliases: [String: String] = [
        "callsign": "locationCallsign",
        "team": "locationTeam",
        "role": "atakRoleType"
        // Add more if needed
    ]

    func handle(url: URL) {
        guard url.scheme == "tak",
              url.host == "com.atakmap.app",
              url.path == "/preference" else {
            TAKLogger.error("Unsupported URL scheme or path: \(url.absoluteString)")
            return
        }

        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return }

        let itemDict = Dictionary(grouping: items, by: { $0.name.prefix { $0.isLetter } })

        // ✅ Check if using grouped keyN/valueN format
        if let keys = itemDict["key"], let values = itemDict["value"] {
            for (index, keyItem) in keys.enumerated() {
                guard let rawKey = keyItem.value?.lowercased(),
                      let value = values[safe: index]?.value else { continue }

                let mappedKey = aliases[rawKey] ?? rawKey

                if TAKAwarePreferences.allowedKeys.contains(mappedKey) {
                    TAKLogger.debug("Grouped format: \(mappedKey) = \(value)")
                    UserPreferences.shared.set(value: value, forKey: mappedKey)
                } else {
                    TAKLogger.warning("Unrecognized preference key: \(mappedKey)")
                }
            }
        } else {
            // ✅ Fallback to flat key=value format
            for item in items {
                guard let value = item.value else { continue }

                let rawKey = item.name.lowercased()
                let mappedKey = aliases[rawKey] ?? rawKey

                if TAKAwarePreferences.allowedKeys.contains(mappedKey) {
                    TAKLogger.debug("Flat format: \(mappedKey) = \(value)")
                    UserPreferences.shared.set(value: value, forKey: mappedKey)
                } else {
                    TAKLogger.warning("Unrecognized flat key: \(mappedKey)")
                }
            }
        }
    }
}
