import Foundation

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

    func apply(to graph: Graph) -> Set<NodeID> {
        switch self {
        case .substring(let query):
            let needle = query.lowercased()
            var result: Set<NodeID> = []
            for (id, node) in graph.nodes where node.name.lowercased().contains(needle) {
                result.insert(id)
            }
            return result

        case .lineage(let name, let up, let down):
            let anchors = Self.findAnchors(name: name, in: graph)
            var result: Set<NodeID> = []
            for anchor in anchors {
                let sub = SubgraphSelector.subgraph(
                    graph: graph,
                    anchor: anchor,
                    upstreamHops: up,
                    downstreamHops: down
                )
                result.formUnion(sub.nodes)
            }
            return result
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
