import Foundation

/// App-wide view defaults that survive relaunch. Only holds state AppKit won't
/// persist for us — window frames, split dividers, toolbar configuration, and
/// outline disclosure all go through autosave names instead.
@MainActor
enum ViewPreferences {

    private enum Key {
        static let inspectorVisible = "ViewPreferences.inspectorVisible"
        static let coloringMode = "ViewPreferences.coloringMode"
        static let restoresWindowState = "ViewPreferences.restoresWindowState"
    }

    static var inspectorVisible: Bool {
        get { UserDefaults.standard.object(forKey: Key.inspectorVisible) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Key.inspectorVisible) }
    }

    static var coloringMode: NodeColoring {
        get {
            guard let raw = UserDefaults.standard.object(forKey: Key.coloringMode) as? Int else { return .kind }
            return NodeColoring(rawValue: raw) ?? .kind
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.coloringMode) }
    }

    /// When off, `ProjectWindowController` skips encoding per-window view state
    /// so relaunch always lands on a clean zoom-to-fit overview.
    static var restoresWindowState: Bool {
        get { UserDefaults.standard.object(forKey: Key.restoresWindowState) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Key.restoresWindowState) }
    }
}

/// FNV-1a over a file path. `hashValue` is seeded per process and would hand
/// out a different autosave key on every launch, so persistence needs its own.
nonisolated enum StableKey {

    static func forURL(_ url: URL) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in url.standardizedFileURL.path.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 36)
    }
}
