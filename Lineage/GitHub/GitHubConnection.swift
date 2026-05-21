import Foundation

/// Persisted shape of a `.lineagegh` document. Stored as pretty-printed JSON.
nonisolated struct GitHubConnection: Codable, Sendable, Hashable {
    var repo: String
    var workflowFileName: String
    var branch: String
    var artifactName: String
    var refreshInterval: RefreshInterval

    /// Reference to the most recent successful run we've materialised. Lets
    /// reload detect "nothing new" without re-downloading.
    var lastSyncedRunID: Int?
    var lastSyncedAt: Date?

    enum RefreshInterval: String, Codable, CaseIterable, Sendable, Hashable {
        case manual
        case every5Minutes
        case every15Minutes
        case every60Minutes

        var displayName: String {
            switch self {
            case .manual: return "Manual"
            case .every5Minutes: return "Every 5 minutes"
            case .every15Minutes: return "Every 15 minutes"
            case .every60Minutes: return "Every hour"
            }
        }

        var seconds: TimeInterval? {
            switch self {
            case .manual: return nil
            case .every5Minutes: return 5 * 60
            case .every15Minutes: return 15 * 60
            case .every60Minutes: return 60 * 60
            }
        }
    }

    /// Short title like "acme/analytics · main". Used as the document display name.
    var displayName: String {
        "\(repo) · \(branch)"
    }
}
