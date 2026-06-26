import Foundation

nonisolated enum GraphLayoutAlgorithm: String, Sendable, CaseIterable {
    case flow
    case grouped

    var displayName: String {
        switch self {
        case .flow:    return "Flow"
        case .grouped: return "Grouped"
        }
    }

    var toolTip: String {
        switch self {
        case .flow:    return "Dependency-flow layout: upstream → downstream, left to right"
        case .grouped: return "Group nodes into folder neighbourhoods"
        }
    }

    /// Stable index for the toolbar segmented control / menu tags.
    var segmentIndex: Int {
        switch self {
        case .flow:    return 0
        case .grouped: return 1
        }
    }

    init(segmentIndex: Int) {
        self = Self.allCases.first { $0.segmentIndex == segmentIndex } ?? .flow
    }

    nonisolated func compute(graph: Graph) -> GraphLayout {
        switch self {
        case .flow:    return LayeredLayout.compute(graph: graph, orientation: .leftToRight)
        case .grouped: return GroupedLayout.compute(graph: graph, orientation: .leftToRight)
        }
    }
}
