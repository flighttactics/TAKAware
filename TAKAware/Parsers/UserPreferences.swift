//
//  UserPreferences.swift
//  TAKAware
//
//  Created by Craig Clayton on 5/26/25.
//
import Foundation

final class UserPreferences {
    static let shared = UserPreferences()
    private let defaults = UserDefaults.standard

    func set(value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func get(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }
}
