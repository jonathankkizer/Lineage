import Foundation

nonisolated struct SubgraphSelection: Sendable, Equatable {
    let nodes: Set<NodeID>
    let upstreamHops: Int
    let downstreamHops: Int
    let anchor: NodeID
}

enum SubgraphSelector {

    nonisolated static func subgraph(
        graph: Graph,
        anchor: NodeID,
        upstreamHops: Int,
        downstreamHops: Int
    ) -> SubgraphSelection {
        var visited: Set<NodeID> = [anchor]

        var upFrontier: Set<NodeID> = [anchor]
        for _ in 0..<max(0, upstreamHops) {
            var next: Set<NodeID> = []
            for id in upFrontier {
                for parent in graph.parents(of: id) where !visited.contains(parent) {
                    next.insert(parent)
                    visited.insert(parent)
                }
            }
            if next.isEmpty { break }
            upFrontier = next
        }

        var downFrontier: Set<NodeID> = [anchor]
        for _ in 0..<max(0, downstreamHops) {
            var next: Set<NodeID> = []
            for id in downFrontier {
                for child in graph.children(of: id) where !visited.contains(child) {
                    next.insert(child)
                    visited.insert(child)
                }
            }
            if next.isEmpty { break }
            downFrontier = next
        }

        return SubgraphSelection(
            nodes: visited,
            upstreamHops: upstreamHops,
            downstreamHops: downstreamHops,
            anchor: anchor
        )
    }
}
