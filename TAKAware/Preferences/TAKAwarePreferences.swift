import Foundation

struct TAKPreference: Decodable {
    let key: String
    let defaultValue: String
    let displayName: String
}

struct TAKAwarePreferences {
    static let all: [TAKPreference] = {
        guard let url = Bundle.main.url(forResource: "TAKAwarePreferences", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let preferences = try? PropertyListDecoder().decode([TAKPreference].self, from: data) else {
            print("⚠️ Failed to load preferences from plist.")
            return []
        }
        return preferences
    }()

    static var allowedKeys: Set<String> {
        Set(all.map { $0.key })
    }

    static func preference(forKey key: String) -> TAKPreference? {
        all.first { $0.key == key }
    }
}
