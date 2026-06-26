import Foundation

nonisolated enum LayoutPreference {

    private static let defaultsKey = "LayoutPreference.algorithm"

    static var algorithm: GraphLayoutAlgorithm {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey) else { return .flow }
            return GraphLayoutAlgorithm(rawValue: raw) ?? .flow
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }
}
