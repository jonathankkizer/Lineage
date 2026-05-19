import AppKit

nonisolated enum ResourceKind: String, Sendable, CaseIterable {
    case model
    case source
    case seed
    case test
    case snapshot
    case exposure
    case metric
    case semanticModel
    case savedQuery
    case unitTest
    case unknown

    init(prefix: String) {
        switch prefix {
        case "model": self = .model
        case "source": self = .source
        case "seed": self = .seed
        case "test": self = .test
        case "snapshot": self = .snapshot
        case "exposure": self = .exposure
        case "metric": self = .metric
        case "semantic_model": self = .semanticModel
        case "saved_query": self = .savedQuery
        case "unit_test": self = .unitTest
        default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .model: "Model"
        case .source: "Source"
        case .seed: "Seed"
        case .test: "Test"
        case .snapshot: "Snapshot"
        case .exposure: "Exposure"
        case .metric: "Metric"
        case .semanticModel: "Semantic Model"
        case .savedQuery: "Saved Query"
        case .unitTest: "Unit Test"
        case .unknown: "Unknown"
        }
    }
}
