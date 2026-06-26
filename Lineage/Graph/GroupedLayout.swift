import CoreGraphics
import Foundation

/// Folder-hierarchy clustering. Each folder becomes a spatial neighbourhood:
/// its nodes are laid out internally with the Flow (`LayeredLayout`) algorithm,
/// then the neighbourhoods are packed recursively with gutters. Spatial only —
/// no drawn territory backgrounds; cross-cluster edges are rendered by the
/// renderer from the full graph using the final positions.
enum GroupedLayout {

    nonisolated static let groupGutter: CGFloat = 80
    nonisolated static let shelfGutter: CGFloat = 80

    nonisolated static func compute(graph: Graph, orientation: LayoutOrientation = .leftToRight) -> GraphLayout {
        guard !graph.nodes.isEmpty else { return .empty }

        let nodeHeight = NodeLabelMetrics.height
        var widths: [NodeID: CGFloat] = [:]
        widths.reserveCapacity(graph.nodes.count)
        for (id, node) in graph.nodes {
            widths[id] = NodeLabelMetrics.nodeWidth(for: node.name)
        }

        let topo = Topology.topologicallySort(graph)
        let rank = Topology.longestPathLayers(graph, topoOrder: topo)

        let root = buildTrie(graph: graph)
        let box = layout(root, graph: graph, rank: rank, orientation: orientation)

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for (id, p) in box.positions {
            let w = widths[id] ?? NodeLabelMetrics.minWidth
            minX = min(minX, p.x - w / 2)
            maxX = max(maxX, p.x + w / 2)
            minY = min(minY, p.y - nodeHeight / 2)
            maxY = max(maxY, p.y + nodeHeight / 2)
        }
        let bounds = minX <= maxX
            ? CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            : .zero

        let clusters = topLevelClusters(graph: graph, positions: box.positions, widths: widths, nodeHeight: nodeHeight)

        return GraphLayout(
            positions: box.positions,
            widths: widths,
            nodeHeight: nodeHeight,
            orientation: orientation,
            layerCount: 0,
            layerDepths: [],
            clusters: clusters,
            bounds: bounds
        )
    }

    // MARK: - Cluster bounds (top-level neighbourhoods)

    nonisolated static let clusterPadding: CGFloat = 24

    nonisolated private static func topLevelClusters(
        graph: Graph,
        positions: [NodeID: CGPoint],
        widths: [NodeID: CGFloat],
        nodeHeight: CGFloat
    ) -> [LayoutCluster] {
        struct Box { var minX, minY, maxX, maxY: CGFloat; var count: Int }
        var boxes: [String: Box] = [:]
        for (id, node) in graph.nodes {
            guard let p = positions[id] else { continue }
            let key = groupSegments(for: node).first ?? "models"
            let halfW = (widths[id] ?? NodeLabelMetrics.minWidth) / 2
            let halfH = nodeHeight / 2
            if var b = boxes[key] {
                b.minX = min(b.minX, p.x - halfW); b.maxX = max(b.maxX, p.x + halfW)
                b.minY = min(b.minY, p.y - halfH); b.maxY = max(b.maxY, p.y + halfH)
                b.count += 1
                boxes[key] = b
            } else {
                boxes[key] = Box(minX: p.x - halfW, minY: p.y - halfH, maxX: p.x + halfW, maxY: p.y + halfH, count: 1)
            }
        }
        return boxes
            .map { key, b in
                LayoutCluster(
                    label: key,
                    path: key,
                    bounds: CGRect(
                        x: b.minX - clusterPadding,
                        y: b.minY - clusterPadding,
                        width: (b.maxX - b.minX) + clusterPadding * 2,
                        height: (b.maxY - b.minY) + clusterPadding * 2
                    ),
                    nodeCount: b.count
                )
            }
            .sorted { $0.path < $1.path }
    }

    // MARK: - Cluster trie

    nonisolated private final class GroupTrie {
        let name: String
        var directNodes: [NodeID] = []
        var children: [String: GroupTrie] = [:]
        init(name: String) { self.name = name }
    }

    nonisolated private static func groupSegments(for node: GraphNode) -> [String] {
        switch node.kind {
        case .model, .snapshot:
            guard let path = node.originalFilePath, path.hasPrefix("models/") else { return ["models"] }
            let trimmed = String(path.dropFirst("models/".count))
            guard let lastSlash = trimmed.lastIndex(of: "/") else { return ["models"] }
            let folder = String(trimmed[..<lastSlash])
            let segs = folder.split(separator: "/").map(String.init)
            return segs.isEmpty ? ["models"] : segs
        case .source:                       return ["sources"]
        case .seed:                         return ["seeds"]
        case .exposure:                     return ["exposures"]
        case .test, .unitTest:              return ["tests"]
        case .metric, .semanticModel, .savedQuery:
                                            return ["metrics"]
        case .unknown:                      return ["other"]
        }
    }

    nonisolated private static func buildTrie(graph: Graph) -> GroupTrie {
        let root = GroupTrie(name: "")
        for (id, node) in graph.nodes {
            let segs = groupSegments(for: node)
            var current = root
            for seg in segs {
                if let child = current.children[seg] {
                    current = child
                } else {
                    let new = GroupTrie(name: seg)
                    current.children[seg] = new
                    current = new
                }
            }
            current.directNodes.append(id)
        }
        return root
    }

    // MARK: - Recursive box layout

    nonisolated private struct Box {
        var positions: [NodeID: CGPoint]
        var size: CGSize
    }

    nonisolated private static func layout(
        _ group: GroupTrie,
        graph: Graph,
        rank: [NodeID: Int],
        orientation: LayoutOrientation
    ) -> Box {
        var boxes: [Box] = []

        if !group.directNodes.isEmpty {
            let sub = inducedSubgraph(graph: graph, nodes: group.directNodes)
            let lay = LayeredLayout.compute(graph: sub, orientation: orientation)
            boxes.append(normalize(lay))
        }

        let sortedChildren = group.children.values.sorted { a, b in
            let ra = averageRank(a, rank: rank)
            let rb = averageRank(b, rank: rank)
            if ra != rb { return ra < rb }
            return a.name < b.name
        }
        for child in sortedChildren {
            boxes.append(layout(child, graph: graph, rank: rank, orientation: orientation))
        }

        return pack(boxes)
    }

    nonisolated private static func inducedSubgraph(graph: Graph, nodes ids: [NodeID]) -> Graph {
        let set = Set(ids)
        var nodes: [NodeID: GraphNode] = [:]
        nodes.reserveCapacity(ids.count)
        for id in ids { if let n = graph.nodes[id] { nodes[id] = n } }

        var forward: [NodeID: [NodeID]] = [:]
        var reverse: [NodeID: [NodeID]] = [:]
        for id in ids {
            let kids = graph.children(of: id).filter { set.contains($0) }
            if !kids.isEmpty { forward[id] = kids }
            let parents = graph.parents(of: id).filter { set.contains($0) }
            if !parents.isEmpty { reverse[id] = parents }
        }
        return Graph(nodes: nodes, forward: forward, reverse: reverse, invocationID: graph.invocationID)
    }

    /// Shift a sub-layout so its bounding box starts at the origin.
    nonisolated private static func normalize(_ layout: GraphLayout) -> Box {
        let origin = layout.bounds.origin
        var positions: [NodeID: CGPoint] = [:]
        positions.reserveCapacity(layout.positions.count)
        for (id, p) in layout.positions {
            positions[id] = CGPoint(x: p.x - origin.x, y: p.y - origin.y)
        }
        return Box(positions: positions, size: layout.bounds.size)
    }

    nonisolated private static func averageRank(_ group: GroupTrie, rank: [NodeID: Int]) -> CGFloat {
        var sum = 0
        var count = 0
        func walk(_ g: GroupTrie) {
            for id in g.directNodes { sum += rank[id] ?? 0; count += 1 }
            for c in g.children.values { walk(c) }
        }
        walk(group)
        return count == 0 ? 0 : CGFloat(sum) / CGFloat(count)
    }

    // MARK: - Shelf packing

    nonisolated private static func pack(_ boxes: [Box]) -> Box {
        let nonEmpty = boxes.filter { !$0.positions.isEmpty }
        guard !nonEmpty.isEmpty else { return Box(positions: [:], size: .zero) }
        guard nonEmpty.count > 1 else { return nonEmpty[0] }

        let totalArea = nonEmpty.reduce(CGFloat(0)) { $0 + $1.size.width * $1.size.height }
        let maxBoxWidth = nonEmpty.map { $0.size.width }.max() ?? 0
        let targetShelfWidth = max(maxBoxWidth, sqrt(max(totalArea, 1)) * 1.6)

        var positions: [NodeID: CGPoint] = [:]
        var shelfX: CGFloat = 0
        var shelfY: CGFloat = 0
        var shelfHeight: CGFloat = 0
        var packedWidth: CGFloat = 0

        for box in nonEmpty {
            if shelfX > 0, shelfX + box.size.width > targetShelfWidth {
                shelfY += shelfHeight + shelfGutter
                shelfX = 0
                shelfHeight = 0
            }
            for (id, p) in box.positions {
                positions[id] = CGPoint(x: p.x + shelfX, y: p.y + shelfY)
            }
            shelfX += box.size.width + groupGutter
            shelfHeight = max(shelfHeight, box.size.height)
            packedWidth = max(packedWidth, shelfX - groupGutter)
        }

        let packedHeight = shelfY + shelfHeight
        return Box(positions: positions, size: CGSize(width: packedWidth, height: packedHeight))
    }
}
