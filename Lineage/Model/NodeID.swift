import Foundation

nonisolated struct NodeID: Hashable, Sendable, RawRepresentable, Codable, CustomStringConvertible {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String { rawValue }

    var resourceKind: ResourceKind {
        guard let prefix = rawValue.split(separator: ".").first else { return .unknown }
        return ResourceKind(prefix: String(prefix))
    }

    var displayName: String {
        let parts = rawValue.split(separator: ".")
        return parts.last.map(String.init) ?? rawValue
    }
}
