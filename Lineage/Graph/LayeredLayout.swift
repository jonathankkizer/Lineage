import CoreGraphics
import Foundation

nonisolated struct GraphLayout: Sendable {
    let positions: [NodeID: CGPoint]
    let layerCount: Int
    let layerY: [CGFloat]
    let bounds: CGRect
    let nodeSize: CGSize

    static let empty = GraphLayout(
        positions: [:], layerCount: 0, layerY: [],
        bounds: .zero, nodeSize: .zero
    )
}

enum LayeredLayout {

    nonisolated static let nodeSize = CGSize(width: 160, height: 36)
    nonisolated static let horizontalSpacing: CGFloat = 24
    nonisolated static let verticalSpacing: CGFloat = 56
    nonisolated static let rowSpacing: CGFloat = 12
    nonisolated static let maxRowWidth: CGFloat = 4500
    nonisolated static let crossingIterations = 4
    nonisolated static let folderCohesionWeight: CGFloat = 0.30

    nonisolated static func compute(graph: Graph) -> GraphLayout {
        guard !graph.nodes.isEmpty else { return .empty }

        let topo = Topology.topologicallySort(graph)

        // Dependency-based sub-layer for the model/snapshot band only:
        // longest path from any other model/snapshot parent.
        var modelSubLayer: [NodeID: Int] = [:]
        for id in topo {
            guard let node = graph.nodes[id] else { continue }
            guard node.kind == .model || node.kind == .snapshot else { continue }
            let parentLayers = graph.parents(of: id).compactMap { pid -> Int? in
                guard let pk = graph.nodes[pid]?.kind, pk == .model || pk == .snapshot else { return nil }
                return modelSubLayer[pid]
            }
            modelSubLayer[id] = (parentLayers.max() ?? -1) + 1
        }

        // Assign each node a (band, sub-layer) key. Compact into contiguous layer indices.
        var keyOf: [NodeID: LayerKey] = [:]
        keyOf.reserveCapacity(graph.nodes.count)
        for (id, node) in graph.nodes {
            keyOf[id] = layerKey(for: node, modelSubLayer: modelSubLayer[id] ?? 0)
        }
        let uniqueKeys = Array(Set(keyOf.values)).sorted()
        var keyToIndex: [LayerKey: Int] = [:]
        for (i, k) in uniqueKeys.enumerated() {
            keyToIndex[k] = i
        }

        let maxLayer = uniqueKeys.count - 1
        var layers: [[NodeID]] = Array(repeating: [], count: maxLayer + 1)
        for (id, key) in keyOf {
            if let idx = keyToIndex[key] { layers[idx].append(id) }
        }
        for i in 0...maxLayer {
            layers[i].sort { $0.rawValue < $1.rawValue }
        }

        var positions: [NodeID: CGPoint] = [:]
        positions.reserveCapacity(graph.nodes.count)
        var layerY: [CGFloat] = Array(repeating: 0, count: maxLayer + 1)

        placeAllLayers(layers: layers, positions: &positions, layerY: &layerY)

        for _ in 0..<crossingIterations {
            sweepDown(layers: &layers, graph: graph, positions: positions)
            placeAllLayers(layers: layers, positions: &positions, layerY: &layerY)
            sweepUp(layers: &layers, graph: graph, positions: positions)
            placeAllLayers(layers: layers, positions: &positions, layerY: &layerY)
        }

        return finalize(positions: positions, layerY: layerY, layerCount: maxLayer + 1)
    }

    nonisolated private struct LayerKey: Hashable, Comparable {
        let band: Int
        let sub: Int
        static func < (l: LayerKey, r: LayerKey) -> Bool {
            if l.band != r.band { return l.band < r.band }
            return l.sub < r.sub
        }
    }

    nonisolated private static func layerKey(for node: GraphNode, modelSubLayer: Int) -> LayerKey {
        switch node.kind {
        case .source:                   return LayerKey(band: 0, sub: 0)
        case .seed:                     return LayerKey(band: 1, sub: 0)
        case .model, .snapshot:         return LayerKey(band: 2, sub: modelSubLayer)
        case .exposure:                 return LayerKey(band: 3, sub: 0)
        case .metric, .semanticModel, .savedQuery:
                                        return LayerKey(band: 3, sub: 1)
        case .test, .unitTest:          return LayerKey(band: 4, sub: 0)
        case .unknown:                  return LayerKey(band: 4, sub: 1)
        }
    }

    // MARK: - Placement

    nonisolated private static func placeAllLayers(
        layers: [[NodeID]],
        positions: inout [NodeID: CGPoint],
        layerY: inout [CGFloat]
    ) {
        let stride = nodeSize.width + horizontalSpacing
        let rowStride = nodeSize.height + rowSpacing
        let maxNodesPerRow = max(1, Int(maxRowWidth / stride))

        var currentTopY: CGFloat = 0
        for i in 0..<layers.count {
            let ids = layers[i]
            let nodeCount = ids.count
            let rowCount = max(1, (nodeCount + maxNodesPerRow - 1) / maxNodesPerRow)
            layerY[i] = currentTopY + nodeSize.height / 2

            var idx = 0
            var remaining = nodeCount
            for r in 0..<rowCount {
                let take = min(remaining, maxNodesPerRow)
                let rowWidth = CGFloat(max(0, take - 1)) * stride
                let startX = -rowWidth / 2
                let rowY = currentTopY + CGFloat(r) * rowStride + nodeSize.height / 2
                for col in 0..<take {
                    let id = ids[idx]
                    positions[id] = CGPoint(x: startX + CGFloat(col) * stride, y: rowY)
                    idx += 1
                }
                remaining -= take
            }

            let layerHeight = CGFloat(rowCount) * nodeSize.height + CGFloat(max(0, rowCount - 1)) * rowSpacing
            currentTopY += layerHeight + verticalSpacing
        }
    }

    // MARK: - Barycenter sweeps

    nonisolated private static func sweepDown(
        layers: inout [[NodeID]],
        graph: Graph,
        positions: [NodeID: CGPoint]
    ) {
        guard layers.count > 1 else { return }
        let centroids = folderCentroids(graph: graph, positions: positions)
        for i in 1..<layers.count {
            var bary: [NodeID: CGFloat] = [:]
            bary.reserveCapacity(layers[i].count)
            for id in layers[i] {
                bary[id] = combinedBarycenter(
                    id: id,
                    neighbors: graph.parents(of: id),
                    graph: graph,
                    positions: positions,
                    centroids: centroids
                )
            }
            layers[i].sort { a, b in
                let aB = bary[a] ?? .greatestFiniteMagnitude
                let bB = bary[b] ?? .greatestFiniteMagnitude
                if aB != bB { return aB < bB }
                return a.rawValue < b.rawValue
            }
        }
    }

    nonisolated private static func sweepUp(
        layers: inout [[NodeID]],
        graph: Graph,
        positions: [NodeID: CGPoint]
    ) {
        guard layers.count > 1 else { return }
        let centroids = folderCentroids(graph: graph, positions: positions)
        for i in (0..<(layers.count - 1)).reversed() {
            var bary: [NodeID: CGFloat] = [:]
            bary.reserveCapacity(layers[i].count)
            for id in layers[i] {
                bary[id] = combinedBarycenter(
                    id: id,
                    neighbors: graph.children(of: id),
                    graph: graph,
                    positions: positions,
                    centroids: centroids
                )
            }
            layers[i].sort { a, b in
                let aB = bary[a] ?? .greatestFiniteMagnitude
                let bB = bary[b] ?? .greatestFiniteMagnitude
                if aB != bB { return aB < bB }
                return a.rawValue < b.rawValue
            }
        }
    }

    nonisolated private static func combinedBarycenter(
        id: NodeID,
        neighbors: [NodeID],
        graph: Graph,
        positions: [NodeID: CGPoint],
        centroids: [String: CGFloat]
    ) -> CGFloat {
        let depBary = barycenter(of: neighbors, positions: positions)
        let folderBary: CGFloat? = graph.nodes[id].flatMap { folderPull(for: $0, centroids: centroids) }
        let hasDep = depBary != .greatestFiniteMagnitude
        switch (hasDep, folderBary) {
        case (true, let f?):
            return depBary * (1 - folderCohesionWeight) + f * folderCohesionWeight
        case (true, nil):
            return depBary
        case (false, let f?):
            return f
        case (false, nil):
            return .greatestFiniteMagnitude
        }
    }

    nonisolated private static func folderPath(of node: GraphNode) -> String? {
        guard node.kind == .model || node.kind == .snapshot else { return nil }
        guard let path = node.originalFilePath, path.hasPrefix("models/") else { return nil }
        let trimmed = String(path.dropFirst("models/".count))
        guard let lastSlash = trimmed.lastIndex(of: "/") else { return nil }
        return String(trimmed[..<lastSlash])
    }

    nonisolated private static func folderCentroids(
        graph: Graph,
        positions: [NodeID: CGPoint]
    ) -> [String: CGFloat] {
        var sums: [String: (sum: CGFloat, count: Int)] = [:]
        for (id, node) in graph.nodes {
            guard let path = folderPath(of: node), let pos = positions[id] else { continue }
            var current: String? = path
            while let cur = current {
                var entry = sums[cur, default: (0, 0)]
                entry.sum += pos.x
                entry.count += 1
                sums[cur] = entry
                if let slash = cur.lastIndex(of: "/") {
                    current = String(cur[..<slash])
                } else {
                    current = nil
                }
            }
        }
        var centroids: [String: CGFloat] = [:]
        centroids.reserveCapacity(sums.count)
        for (folder, info) in sums {
            centroids[folder] = info.sum / CGFloat(info.count)
        }
        return centroids
    }

    nonisolated private static func folderPull(
        for node: GraphNode,
        centroids: [String: CGFloat]
    ) -> CGFloat? {
        guard let path = folderPath(of: node) else { return nil }
        var sum: CGFloat = 0
        var totalWeight: CGFloat = 0
        var weight: CGFloat = 1.0
        var current: String? = path
        while let cur = current {
            if let centroid = centroids[cur] {
                sum += centroid * weight
                totalWeight += weight
            }
            weight *= 0.5
            if let slash = cur.lastIndex(of: "/") {
                current = String(cur[..<slash])
            } else {
                current = nil
            }
        }
        guard totalWeight > 0 else { return nil }
        return sum / totalWeight
    }

    nonisolated private static func barycenter(of neighbors: [NodeID], positions: [NodeID: CGPoint]) -> CGFloat {
        let xs = neighbors.compactMap { positions[$0]?.x }
        guard !xs.isEmpty else { return .greatestFiniteMagnitude }
        return xs.reduce(0, +) / CGFloat(xs.count)
    }

    // MARK: - Finalize

    nonisolated private static func finalize(
        positions: [NodeID: CGPoint],
        layerY: [CGFloat],
        layerCount: Int
    ) -> GraphLayout {
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for p in positions.values {
            minX = min(minX, p.x - nodeSize.width / 2)
            maxX = max(maxX, p.x + nodeSize.width / 2)
            minY = min(minY, p.y - nodeSize.height / 2)
            maxY = max(maxY, p.y + nodeSize.height / 2)
        }
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return GraphLayout(
            positions: positions,
            layerCount: layerCount,
            layerY: layerY,
            bounds: bounds,
            nodeSize: nodeSize
        )
    }
}
