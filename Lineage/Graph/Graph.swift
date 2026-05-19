import Foundation

nonisolated struct GraphNode: Sendable {
    let id: NodeID
    let kind: ResourceKind
    let name: String
    let database: String?
    let schema: String?
    let originalFilePath: String?
    let tags: [String]
    let materialization: String?
    let description: String?
    let columns: [GraphColumn]
    let manifestRef: ManifestRef
}

nonisolated struct GraphColumn: Sendable {
    let name: String
    let description: String?
    let dataType: String?
}

nonisolated struct FolderNode: Sendable {
    let name: String
    let path: String
    let directCount: Int
    let totalCount: Int
    let children: [FolderNode]
}

nonisolated enum ManifestRef: Sendable {
    case node(ManifestNode)
    case source(ManifestSource)
    case exposure(ManifestExposure)
}

nonisolated struct Graph: Sendable {
    let nodes: [NodeID: GraphNode]
    let forward: [NodeID: [NodeID]]
    let reverse: [NodeID: [NodeID]]
    let invocationID: String

    nonisolated static func build(from manifest: Manifest) -> Graph {
        var nodes: [NodeID: GraphNode] = [:]
        nodes.reserveCapacity(manifest.nodes.count + manifest.sources.count + manifest.exposures.count)

        for (id, n) in manifest.nodes {
            let key = NodeID(id)
            let cols = (n.columns ?? [:])
                .sorted { $0.key < $1.key }
                .map { GraphColumn(name: $0.value.name, description: $0.value.description, dataType: $0.value.dataType) }
            nodes[key] = GraphNode(
                id: key,
                kind: key.resourceKind,
                name: n.name,
                database: n.database,
                schema: n.schema,
                originalFilePath: n.originalFilePath,
                tags: n.tags,
                materialization: n.config?.materialized,
                description: n.description,
                columns: cols,
                manifestRef: .node(n)
            )
        }

        for (id, s) in manifest.sources {
            let key = NodeID(id)
            let cols = (s.columns ?? [:])
                .sorted { $0.key < $1.key }
                .map { GraphColumn(name: $0.value.name, description: $0.value.description, dataType: $0.value.dataType) }
            nodes[key] = GraphNode(
                id: key,
                kind: .source,
                name: "\(s.sourceName).\(s.name)",
                database: s.database,
                schema: s.schema,
                originalFilePath: s.originalFilePath,
                tags: s.tags,
                materialization: nil,
                description: s.description,
                columns: cols,
                manifestRef: .source(s)
            )
        }

        for (id, e) in manifest.exposures {
            let key = NodeID(id)
            nodes[key] = GraphNode(
                id: key,
                kind: .exposure,
                name: e.name,
                database: nil,
                schema: nil,
                originalFilePath: e.originalFilePath,
                tags: e.tags,
                materialization: nil,
                description: e.description,
                columns: [],
                manifestRef: .exposure(e)
            )
        }

        var forward: [NodeID: [NodeID]] = [:]
        var reverse: [NodeID: [NodeID]] = [:]
        forward.reserveCapacity(nodes.count)
        reverse.reserveCapacity(nodes.count)

        for (parentStr, children) in manifest.childMap {
            let parent = NodeID(parentStr)
            guard nodes[parent] != nil else { continue }
            let kept = children.compactMap { childStr -> NodeID? in
                let child = NodeID(childStr)
                return nodes[child] != nil ? child : nil
            }
            if !kept.isEmpty { forward[parent] = kept }
        }

        for (childStr, parents) in manifest.parentMap {
            let child = NodeID(childStr)
            guard nodes[child] != nil else { continue }
            let kept = parents.compactMap { parentStr -> NodeID? in
                let parent = NodeID(parentStr)
                return nodes[parent] != nil ? parent : nil
            }
            if !kept.isEmpty { reverse[child] = kept }
        }

        return Graph(
            nodes: nodes,
            forward: forward,
            reverse: reverse,
            invocationID: manifest.metadata.invocationId ?? UUID().uuidString
        )
    }

    nonisolated func parents(of id: NodeID) -> [NodeID] { reverse[id] ?? [] }
    nonisolated func children(of id: NodeID) -> [NodeID] { forward[id] ?? [] }

    nonisolated static func scopeMatches(node: GraphNode, scope: FilterScope) -> Bool {
        switch scope {
        case .all:
            return true
        case .folder(let folder):
            guard let path = node.originalFilePath else { return false }
            return path.hasPrefix("models/\(folder)/")
        case .tag(let tag):
            return node.tags.contains(tag)
        }
    }

    nonisolated func folderTree() -> [FolderNode] {
        final class TrieNode {
            let name: String
            let path: String
            var directCount: Int = 0
            var children: [String: TrieNode] = [:]
            init(name: String, path: String) {
                self.name = name
                self.path = path
            }
        }

        let root = TrieNode(name: "", path: "")

        for node in nodes.values where node.kind == .model {
            guard let path = node.originalFilePath, path.hasPrefix("models/") else { continue }
            let trimmed = String(path.dropFirst("models/".count))
            guard let lastSlash = trimmed.lastIndex(of: "/") else { continue }
            let folderPath = String(trimmed[..<lastSlash])
            let segments = folderPath.split(separator: "/").map(String.init)
            if segments.isEmpty { continue }

            var current = root
            var accum = ""
            for seg in segments {
                accum = accum.isEmpty ? seg : "\(accum)/\(seg)"
                if let child = current.children[seg] {
                    current = child
                } else {
                    let new = TrieNode(name: seg, path: accum)
                    current.children[seg] = new
                    current = new
                }
            }
            current.directCount += 1
        }

        func convert(_ node: TrieNode) -> FolderNode {
            let children = node.children.values
                .map { convert($0) }
                .sorted { lhs, rhs in
                    if lhs.totalCount != rhs.totalCount { return lhs.totalCount > rhs.totalCount }
                    return lhs.name < rhs.name
                }
            let total = node.directCount + children.reduce(0) { $0 + $1.totalCount }
            return FolderNode(
                name: node.name,
                path: node.path,
                directCount: node.directCount,
                totalCount: total,
                children: children
            )
        }

        return root.children.values
            .map { convert($0) }
            .sorted { lhs, rhs in
                if lhs.totalCount != rhs.totalCount { return lhs.totalCount > rhs.totalCount }
                return lhs.name < rhs.name
            }
    }

    nonisolated func allTags() -> [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for node in nodes.values {
            for tag in node.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts
            .map { (tag: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.tag < rhs.tag
            }
    }

    nonisolated func filtered(by filter: NodeFilter) -> Graph {
        var kept: [NodeID: GraphNode] = [:]
        kept.reserveCapacity(nodes.count)
        for (id, node) in nodes {
            var keep: Bool
            switch node.kind {
            case .test:
                keep = filter.showTests
            case .source:
                if !filter.showSources {
                    keep = false
                } else if filter.showOrphanSources {
                    keep = true
                } else {
                    keep = !children(of: id).isEmpty
                }
            case .seed:
                keep = filter.showSeeds
            case .snapshot:
                keep = filter.showSnapshots
            case .exposure:
                keep = filter.showExposures
            default:
                keep = true
            }
            if keep {
                keep = Self.scopeMatches(node: node, scope: filter.scope)
            }
            if keep { kept[id] = node }
        }

        var newForward: [NodeID: [NodeID]] = [:]
        var newReverse: [NodeID: [NodeID]] = [:]
        newForward.reserveCapacity(kept.count)
        newReverse.reserveCapacity(kept.count)

        for (parent, children) in forward where kept[parent] != nil {
            let kc = children.filter { kept[$0] != nil }
            if !kc.isEmpty { newForward[parent] = kc }
        }
        for (child, parents) in reverse where kept[child] != nil {
            let kp = parents.filter { kept[$0] != nil }
            if !kp.isEmpty { newReverse[child] = kp }
        }

        return Graph(nodes: kept, forward: newForward, reverse: newReverse, invocationID: invocationID)
    }
}
