import Foundation

/// The longest-weighted path through the build DAG, where weights are per-node
/// execution times from `run_results.json`. Conceptually: the wall-clock floor
/// on the project's build assuming infinite warehouse concurrency. Optimizing a
/// node that isn't on this path can't reduce overall build time; optimizing one
/// that is on it shortens the whole project (until the path shifts).
nonisolated struct CriticalPath: Sendable, Equatable {
    /// Nodes on the path, ordered root → leaf (topological).
    let nodes: [NodeID]
    /// Edge set as (parent, child) pairs along the path.
    let edges: Set<EdgePair>
    /// Sum of executionTime across `nodes`.
    let totalSeconds: TimeInterval

    var nodeSet: Set<NodeID> { Set(nodes) }
    var isEmpty: Bool { nodes.isEmpty }

    struct EdgePair: Hashable, Sendable {
        let parent: NodeID
        let child: NodeID
    }

    /// Standard topological longest-weighted-path. Nodes with no recorded
    /// execution time contribute 0. Returns nil if the graph has no timed
    /// nodes — caller treats nil as "feature unavailable for this project".
    nonisolated static func compute(graph: Graph, timings: BuildTimings) -> CriticalPath? {
        guard !timings.executionTime.isEmpty else { return nil }

        let order = topologicallySorted(graph: graph)
        guard !order.isEmpty else { return nil }

        // best[n] = total elapsed time of the heaviest root→n path ending at n
        // (inclusive of n's own cost). pred[n] = the parent on that path, or nil
        // if n is the start.
        var best: [NodeID: TimeInterval] = [:]
        var pred: [NodeID: NodeID] = [:]
        best.reserveCapacity(graph.nodes.count)

        var heaviestTerminal: NodeID?
        var heaviestTotal: TimeInterval = -1

        for node in order {
            let nodeCost = timings.executionTime[node] ?? 0
            var bestParentTotal: TimeInterval = 0
            var bestParent: NodeID?
            for parent in graph.parents(of: node) {
                let candidate = best[parent] ?? 0
                if candidate > bestParentTotal {
                    bestParentTotal = candidate
                    bestParent = parent
                }
            }
            let total = bestParentTotal + nodeCost
            best[node] = total
            if let bestParent { pred[node] = bestParent }
            if total > heaviestTotal {
                heaviestTotal = total
                heaviestTerminal = node
            }
        }

        guard let terminal = heaviestTerminal, heaviestTotal > 0 else { return nil }

        var reversed: [NodeID] = [terminal]
        var cursor: NodeID = terminal
        while let parent = pred[cursor] {
            reversed.append(parent)
            cursor = parent
        }
        let path = Array(reversed.reversed())

        var edgeSet: Set<EdgePair> = []
        edgeSet.reserveCapacity(max(0, path.count - 1))
        for i in 0..<(path.count - 1) {
            edgeSet.insert(EdgePair(parent: path[i], child: path[i + 1]))
        }

        return CriticalPath(nodes: path, edges: edgeSet, totalSeconds: heaviestTotal)
    }

    /// Kahn's algorithm. dbt's DAG should always be acyclic; if a cycle were
    /// present we'd silently drop the unreachable tail, which is fine — the
    /// caller treats a partial result the same as a normal one.
    private nonisolated static func topologicallySorted(graph: Graph) -> [NodeID] {
        var indegree: [NodeID: Int] = [:]
        indegree.reserveCapacity(graph.nodes.count)
        for id in graph.nodes.keys {
            indegree[id] = graph.parents(of: id).count
        }
        var queue: [NodeID] = indegree.compactMap { $0.value == 0 ? $0.key : nil }
        var order: [NodeID] = []
        order.reserveCapacity(graph.nodes.count)
        var head = 0
        while head < queue.count {
            let node = queue[head]
            head += 1
            order.append(node)
            for child in graph.children(of: node) {
                let remaining = (indegree[child] ?? 0) - 1
                indegree[child] = remaining
                if remaining == 0 {
                    queue.append(child)
                }
            }
        }
        return order
    }
}
