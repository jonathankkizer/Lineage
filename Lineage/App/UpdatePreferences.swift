import Foundation

@MainActor
struct UpdatePreferences {

    private enum Key {
        static let autoCheckEnabled = "UpdatePreferences.autoCheckEnabled"
        static let consentPromptShown = "UpdatePreferences.consentPromptShown"
        static let lastCheckDate = "UpdatePreferences.lastCheckDate"
        static let skippedVersion = "UpdatePreferences.skippedVersion"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var autoCheckEnabled: Bool {
        get { defaults.object(forKey: Key.autoCheckEnabled) as? Bool ?? false }
        nonmutating set { defaults.set(newValue, forKey: Key.autoCheckEnabled) }
    }

    var consentPromptShown: Bool {
        get { defaults.bool(forKey: Key.consentPromptShown) }
        nonmutating set { defaults.set(newValue, forKey: Key.consentPromptShown) }
    }

    var lastCheckDate: Date? {
        get { defaults.object(forKey: Key.lastCheckDate) as? Date }
        nonmutating set { defaults.set(newValue, forKey: Key.lastCheckDate) }
    }

    var skippedVersion: String? {
        get { defaults.string(forKey: Key.skippedVersion) }
        nonmutating set {
            if let newValue {
                defaults.set(newValue, forKey: Key.skippedVersion)
            } else {
                defaults.removeObject(forKey: Key.skippedVersion)
            }
        }
    }
}
