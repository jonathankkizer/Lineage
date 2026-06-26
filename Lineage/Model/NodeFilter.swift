import Foundation

nonisolated enum FilterScope: Equatable, Hashable, Sendable {
    case all
    case folder(String)
    case tag(String)

    var displayLabel: String {
        switch self {
        case .all: return "All"
        case .folder(let name): return name
        case .tag(let name): return name
        }
    }
}

nonisolated struct NodeFilter: Equatable, Hashable, Sendable {
    var showTests: Bool
    var showSources: Bool
    var showOrphanSources: Bool
    var showSeeds: Bool
    var showSnapshots: Bool
    var showExposures: Bool
    var scope: FilterScope

    static let `default` = NodeFilter(
        showTests: false,
        showSources: true,
        showOrphanSources: false,
        showSeeds: true,
        showSnapshots: true,
        showExposures: false,
        scope: .all
    )

    var isDefault: Bool { self == .default }
}
