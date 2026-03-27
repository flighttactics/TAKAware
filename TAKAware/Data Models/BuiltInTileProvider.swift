//
//  BuiltInTileProvider.swift
//  TAKAware
//
//  Built-in tile providers — free, no API key required.
//

import Foundation
import MapKit

enum BuiltInTileProvider: String, CaseIterable, Identifiable {
    case osmStandard
    case osmHumanitarian
    case openTopoMap
    case cartoDark
    case cartoLight
    case esriSatellite
    case esriStreet

    var id: String { rawValue }

    var label: String {
        switch self {
        case .osmStandard:      return "OSM Standard"
        case .osmHumanitarian:  return "OSM Humanitarian"
        case .openTopoMap:      return "OpenTopoMap"
        case .cartoDark:        return "Carto Dark"
        case .cartoLight:       return "Carto Light"
        case .esriSatellite:    return "ESRI Satellite"
        case .esriStreet:       return "ESRI Street"
        }
    }

    var urlTemplate: String {
        switch self {
        case .osmStandard:
            return "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        case .osmHumanitarian:
            return "https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png"
        case .openTopoMap:
            return "https://a.tile.opentopomap.org/{z}/{x}/{y}.png"
        case .cartoDark:
            return "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
        case .cartoLight:
            return "https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png"
        case .esriSatellite:
            return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
        case .esriStreet:
            return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}"
        }
    }

    var maxZoom: Int {
        switch self {
        case .openTopoMap:                  return 17
        case .esriSatellite, .esriStreet:   return 20
        default:                            return 19
        }
    }

    var attribution: String {
        switch self {
        case .osmStandard, .osmHumanitarian:
            return "© OpenStreetMap contributors"
        case .openTopoMap:
            return "© OpenStreetMap contributors, © OpenTopoMap"
        case .cartoDark, .cartoLight:
            return "© OpenStreetMap contributors, © CARTO"
        case .esriSatellite, .esriStreet:
            return "Tiles © Esri"
        }
    }

    /// Prefix used to identify built-in providers in activateMapSource
    static let prefix = "builtin:"

    /// The key stored in UserDefaults when a built-in tile provider is active
    var storageKey: String { Self.prefix + rawValue }

    static func from(storageKey: String) -> BuiltInTileProvider? {
        guard storageKey.hasPrefix(prefix) else { return nil }
        let raw = String(storageKey.dropFirst(prefix.count))
        return BuiltInTileProvider(rawValue: raw)
    }
}
