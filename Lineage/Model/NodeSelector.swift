import Foundation

nonisolated struct SelectionScope: Sendable, Equatable {
    let nodes: Set<NodeID>
    // For lineage selectors: upstream and downstream sets, each including the anchor.
    // An edge belongs to the scope iff both endpoints lie in the same one of these
    // sets. Either set may be nil, indicating "no lineage scope in that direction"
    // (substring matches set both to nil and rely on `nodes` membership only).
    let upstream: Set<NodeID>?
    let downstream: Set<NodeID>?

    var isEmpty: Bool { nodes.isEmpty }
    var isLineage: Bool { upstream != nil || downstream != nil }

    static let empty = SelectionScope(nodes: [], upstream: nil, downstream: nil)

    static func nodesOnly(_ nodes: Set<NodeID>) -> SelectionScope {
        SelectionScope(nodes: nodes, upstream: nil, downstream: nil)
    }
}

nonisolated enum NodeSelector: Sendable, Equatable {
    case substring(String)
    case lineage(name: String, upstreamHops: Int, downstreamHops: Int)

    static let unboundedHops = Int.max

    static func parse(_ input: String) -> NodeSelector? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var s = trimmed
        var lineageSyntax = false
        var upHops = 0
        var downHops = 0

        if let plusIdx = s.firstIndex(of: "+") {
            let prefix = s[..<plusIdx]
            if prefix.isEmpty || prefix.allSatisfy(\.isNumber) {
                lineageSyntax = true
                upHops = prefix.isEmpty ? unboundedHops : (Int(prefix) ?? unboundedHops)
                s = String(s[s.index(after: plusIdx)...])
            }
        }

        if let plusIdx = s.lastIndex(of: "+") {
            let suffix = s[s.index(after: plusIdx)...]
            if suffix.isEmpty || suffix.allSatisfy(\.isNumber) {
                lineageSyntax = true
                downHops = suffix.isEmpty ? unboundedHops : (Int(suffix) ?? unboundedHops)
                s = String(s[..<plusIdx])
            }
        }

        let name = s.trimmingCharacters(in: .whitespacesAndNewlines)

        if lineageSyntax {
            guard !name.isEmpty else { return nil }
            return .lineage(name: name, upstreamHops: upHops, downstreamHops: downHops)
        }
        return .substring(trimmed)
    }

    func apply(to graph: Graph) -> SelectionScope {
        switch self {
        case .substring(let query):
            let needle = query.lowercased()
            var result: Set<NodeID> = []
            for (id, node) in graph.nodes where node.name.lowercased().contains(needle) {
                result.insert(id)
            }
            return .nodesOnly(result)

        case .lineage(let name, let up, let down):
            let anchors = Self.findAnchors(name: name, in: graph)
            var upstreamSet: Set<NodeID> = []
            var downstreamSet: Set<NodeID> = []
            for anchor in anchors {
                upstreamSet.insert(anchor)
                downstreamSet.insert(anchor)
                if up > 0 {
                    let upSub = SubgraphSelector.subgraph(
                        graph: graph, anchor: anchor, upstreamHops: up, downstreamHops: 0
                    )
                    upstreamSet.formUnion(upSub.nodes)
                }
                if down > 0 {
                    let downSub = SubgraphSelector.subgraph(
                        graph: graph, anchor: anchor, upstreamHops: 0, downstreamHops: down
                    )
                    downstreamSet.formUnion(downSub.nodes)
                }
            }
            return SelectionScope(
                nodes: upstreamSet.union(downstreamSet),
                upstream: up > 0 ? upstreamSet : nil,
                downstream: down > 0 ? downstreamSet : nil
            )
        }
    }

    private static func findAnchors(name: String, in graph: Graph) -> [NodeID] {
        let target = name.lowercased()
        var exact: [NodeID] = []
        var partial: [NodeID] = []
        for (id, node) in graph.nodes {
            let lower = node.name.lowercased()
            if lower == target {
                exact.append(id)
            } else if lower.contains(target) {
                partial.append(id)
            }
        }
        return exact.isEmpty ? partial : exact
    }
}
