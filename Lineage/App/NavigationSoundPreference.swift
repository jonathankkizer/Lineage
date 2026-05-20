import Foundation

@MainActor
enum NavigationSoundPreference {

    private static let defaultsKey = "NavigationSoundPreference.enabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }
}
