import CoreGraphics
import Foundation

nonisolated enum LayoutOrientation: Sendable {
    case topToBottom
    case leftToRight
}

nonisolated struct GraphLayout: Sendable {
    let positions: [NodeID: CGPoint]
    let widths: [NodeID: CGFloat]
    let nodeHeight: CGFloat
    let orientation: LayoutOrientation
    let layerCount: Int
    let layerDepths: [CGFloat]
    let bounds: CGRect

    static let empty = GraphLayout(
        positions: [:], widths: [:], nodeHeight: 0, orientation: .leftToRight,
        layerCount: 0, layerDepths: [], bounds: .zero
    )

    func width(for id: NodeID) -> CGFloat {
        widths[id] ?? NodeLabelMetrics.minWidth
    }

    func rect(for id: NodeID) -> CGRect? {
        guard let p = positions[id] else { return nil }
        let w = width(for: id)
        return CGRect(x: p.x - w / 2, y: p.y - nodeHeight / 2, width: w, height: nodeHeight)
    }
}

enum LayeredLayout {

    nonisolated static let crossSpacing: CGFloat = 14
    nonisolated static let depthSpacing: CGFloat = 56
    nonisolated static let laneSpacing: CGFloat = 10
    nonisolated static let maxLaneExtent: CGFloat = 4500
    nonisolated static let crossingIterations = 4
    nonisolated static let alignmentIterations = 2
    nonisolated static let folderCohesionWeight: CGFloat = 0.30

    nonisolated static func compute(graph: Graph, orientation: LayoutOrientation = .leftToRight) -> GraphLayout {
        guard !graph.nodes.isEmpty else { return .empty }

        var widths: [NodeID: CGFloat] = [:]
        widths.reserveCapacity(graph.nodes.count)
        for (id, node) in graph.nodes {
            widths[id] = NodeLabelMetrics.nodeWidth(for: node.name)
        }

        let nodeHeight = NodeLabelMetrics.height
        let axis = Axis(orientation: orientation, widths: widths, nodeHeight: nodeHeight)

        // Dependency rank across the WHOLE DAG (dagre-style longest-path), no
        // per-type bands. Roots (sources/seeds) fall to rank 0; leaves
        // (tests/exposures) drift to the far edge naturally.
        let topo = Topology.topologicallySort(graph)
        let rank = Topology.longestPathLayers(graph, topoOrder: topo)
        let maxRank = rank.values.max() ?? 0

        var layers: [[NodeID]] = Array(repeating: [], count: maxRank + 1)
        for (id, r) in rank where r >= 0 && r <= maxRank {
            layers[r].append(id)
        }
        for i in layers.indices {
            layers[i].sort { $0.rawValue < $1.rawValue }
        }

        // Canonical frame: cross = x (breadth within a layer), depth = y (layer
        // progression). Orientation is applied only in finalize().
        var canonical: [NodeID: CGPoint] = [:]
        canonical.reserveCapacity(graph.nodes.count)
        var layerDepths: [CGFloat] = Array(repeating: 0, count: maxRank + 1)

        placeLayers(layers: layers, axis: axis, canonical: &canonical, layerDepths: &layerDepths)

        for _ in 0..<crossingIterations {
            sweepDown(layers: &layers, graph: graph, canonical: canonical)
            placeLayers(layers: layers, axis: axis, canonical: &canonical, layerDepths: &layerDepths)
            sweepUp(layers: &layers, graph: graph, canonical: canonical)
            placeLayers(layers: layers, axis: axis, canonical: &canonical, layerDepths: &layerDepths)
        }

        // Position by barycenter (not just order): pulls each node toward its
        // neighbours instead of evenly centering the layer — kills the "static
        // grid" feel and aligns dependency chains into clean columns.
        for _ in 0..<alignmentIterations {
            alignLayers(layers: layers, graph: graph, axis: axis, downward: true, canonical: &canonical)
            alignLayers(layers: layers, graph: graph, axis: axis, downward: false, canonical: &canonical)
        }

        return finalize(
            canonical: canonical, widths: widths, nodeHeight: nodeHeight,
            orientation: orientation, layerDepths: layerDepths, layerCount: maxRank + 1
        )
    }

    // MARK: - Axis

    nonisolated private struct Axis {
        let orientation: LayoutOrientation
        let widths: [NodeID: CGFloat]
        let nodeHeight: CGFloat

        // Extent along the in-layer packing axis.
        func cross(_ id: NodeID) -> CGFloat {
            switch orientation {
            case .topToBottom: return widths[id] ?? NodeLabelMetrics.minWidth
            case .leftToRight: return nodeHeight
            }
        }

        // Extent along the layer-progression axis.
        func depth(_ id: NodeID) -> CGFloat {
            switch orientation {
            case .topToBottom: return nodeHeight
            case .leftToRight: return widths[id] ?? NodeLabelMetrics.minWidth
            }
        }
    }

    // MARK: - Placement (canonical: cross = x, depth = y)

    nonisolated private static func placeLayers(
        layers: [[NodeID]],
        axis: Axis,
        canonical: inout [NodeID: CGPoint],
        layerDepths: inout [CGFloat]
    ) {
        var currentDepth: CGFloat = 0
        for i in 0..<layers.count {
            let ids = layers[i]
            let lanes = wrapLayer(ids: ids, axis: axis)
            let maxDepth = ids.map { axis.depth($0) }.max() ?? axis.nodeHeight
            let laneStride = maxDepth + laneSpacing

            layerDepths[i] = currentDepth + maxDepth / 2

            for (laneIdx, lane) in lanes.enumerated() {
                let laneTotal = lane.reduce(CGFloat(0)) { $0 + axis.cross($1) }
                    + CGFloat(max(0, lane.count - 1)) * crossSpacing
                let laneDepthCenter = currentDepth + CGFloat(laneIdx) * laneStride + maxDepth / 2
                var c = -laneTotal / 2
                for id in lane {
                    let e = axis.cross(id)
                    canonical[id] = CGPoint(x: c + e / 2, y: laneDepthCenter)
                    c += e + crossSpacing
                }
            }

            let laneCount = max(1, lanes.count)
            let span = CGFloat(laneCount) * maxDepth + CGFloat(laneCount - 1) * laneSpacing
            currentDepth += span + depthSpacing
        }
    }

    nonisolated private static func wrapLayer(ids: [NodeID], axis: Axis) -> [[NodeID]] {
        guard !ids.isEmpty else { return [[]] }
        var lanes: [[NodeID]] = [[]]
        var current: CGFloat = 0
        for id in ids {
            let e = axis.cross(id)
            let needed = current == 0 ? e : current + crossSpacing + e
            if needed > maxLaneExtent, let last = lanes.last, !last.isEmpty {
                lanes.append([id])
                current = e
            } else {
                lanes[lanes.count - 1].append(id)
                current = needed
            }
        }
        return lanes
    }

    // MARK: - Barycenter alignment

    nonisolated private static func alignLayers(
        layers: [[NodeID]],
        graph: Graph,
        axis: Axis,
        downward: Bool,
        canonical: inout [NodeID: CGPoint]
    ) {
        guard layers.count > 1 else { return }
        let centroids = folderCentroids(graph: graph, canonical: canonical)
        let indices = downward ? Array(layers.indices) : Array(layers.indices.reversed())

        for i in indices {
            let ids = layers[i]
            guard ids.count > 1 else { continue }
            // Multi-lane (wrapped) layers stay centered — alignment matters
            // least there and the geometry is awkward.
            guard wrapLayer(ids: ids, axis: axis).count == 1 else { continue }
            guard let depthY = canonical[ids[0]]?.y else { continue }

            var desired: [(id: NodeID, target: CGFloat, half: CGFloat)] = []
            desired.reserveCapacity(ids.count)
            for id in ids {
                let neighbors = downward ? graph.parents(of: id) : graph.children(of: id)
                let target = combinedBarycenter(
                    id: id, neighbors: neighbors, graph: graph,
                    canonical: canonical, centroids: centroids
                ) ?? canonical[id]?.x ?? 0
                desired.append((id, target, axis.cross(id) / 2))
            }

            // Left-to-right de-overlap honouring the desired targets.
            var placed: [(id: NodeID, x: CGFloat, half: CGFloat)] = []
            placed.reserveCapacity(desired.count)
            for d in desired {
                var x = d.target
                if let prev = placed.last {
                    let minX = prev.x + prev.half + crossSpacing + d.half
                    if x < minX { x = minX }
                }
                placed.append((d.id, x, d.half))
            }

            // Re-center the resolved run on the mean of the desired targets so
            // the whole layer doesn't drift rightward across iterations.
            let desiredMean = desired.reduce(CGFloat(0)) { $0 + $1.target } / CGFloat(desired.count)
            let placedMean = placed.reduce(CGFloat(0)) { $0 + $1.x } / CGFloat(placed.count)
            let shift = desiredMean - placedMean
            for p in placed {
                canonical[p.id] = CGPoint(x: p.x + shift, y: depthY)
            }
        }
    }

    // MARK: - Barycenter ordering sweeps

    nonisolated private static func sweepDown(
        layers: inout [[NodeID]],
        graph: Graph,
        canonical: [NodeID: CGPoint]
    ) {
        guard layers.count > 1 else { return }
        let centroids = folderCentroids(graph: graph, canonical: canonical)
        for i in 1..<layers.count {
            sortLayer(&layers[i], graph: graph, canonical: canonical, centroids: centroids, useParents: true)
        }
    }

    nonisolated private static func sweepUp(
        layers: inout [[NodeID]],
        graph: Graph,
        canonical: [NodeID: CGPoint]
    ) {
        guard layers.count > 1 else { return }
        let centroids = folderCentroids(graph: graph, canonical: canonical)
        for i in (0..<(layers.count - 1)).reversed() {
            sortLayer(&layers[i], graph: graph, canonical: canonical, centroids: centroids, useParents: false)
        }
    }

    nonisolated private static func sortLayer(
        _ layer: inout [NodeID],
        graph: Graph,
        canonical: [NodeID: CGPoint],
        centroids: [String: CGFloat],
        useParents: Bool
    ) {
        var bary: [NodeID: CGFloat] = [:]
        bary.reserveCapacity(layer.count)
        for id in layer {
            let neighbors = useParents ? graph.parents(of: id) : graph.children(of: id)
            bary[id] = combinedBarycenter(
                id: id, neighbors: neighbors, graph: graph,
                canonical: canonical, centroids: centroids
            ) ?? .greatestFiniteMagnitude
        }
        layer.sort { a, b in
            let aB = bary[a] ?? .greatestFiniteMagnitude
            let bB = bary[b] ?? .greatestFiniteMagnitude
            if aB != bB { return aB < bB }
            return a.rawValue < b.rawValue
        }
    }

    nonisolated private static func combinedBarycenter(
        id: NodeID,
        neighbors: [NodeID],
        graph: Graph,
        canonical: [NodeID: CGPoint],
        centroids: [String: CGFloat]
    ) -> CGFloat? {
        let depBary = barycenter(of: neighbors, canonical: canonical)
        let folderBary: CGFloat? = graph.nodes[id].flatMap { folderPull(for: $0, centroids: centroids) }
        switch (depBary, folderBary) {
        case (let d?, let f?):
            return d * (1 - folderCohesionWeight) + f * folderCohesionWeight
        case (let d?, nil):
            return d
        case (nil, let f?):
            return f
        case (nil, nil):
            return nil
        }
    }

    nonisolated private static func barycenter(of neighbors: [NodeID], canonical: [NodeID: CGPoint]) -> CGFloat? {
        let xs = neighbors.compactMap { canonical[$0]?.x }
        guard !xs.isEmpty else { return nil }
        return xs.reduce(0, +) / CGFloat(xs.count)
    }

    // MARK: - Folder cohesion

    nonisolated private static func folderPath(of node: GraphNode) -> String? {
        guard node.kind == .model || node.kind == .snapshot else { return nil }
        guard let path = node.originalFilePath, path.hasPrefix("models/") else { return nil }
        let trimmed = String(path.dropFirst("models/".count))
        guard let lastSlash = trimmed.lastIndex(of: "/") else { return nil }
        return String(trimmed[..<lastSlash])
    }

    nonisolated private static func folderCentroids(
        graph: Graph,
        canonical: [NodeID: CGPoint]
    ) -> [String: CGFloat] {
        var sums: [String: (sum: CGFloat, count: Int)] = [:]
        for (id, node) in graph.nodes {
            guard let path = folderPath(of: node), let pos = canonical[id] else { continue }
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

    // MARK: - Finalize (canonical → oriented)

    nonisolated private static func finalize(
        canonical: [NodeID: CGPoint],
        widths: [NodeID: CGFloat],
        nodeHeight: CGFloat,
        orientation: LayoutOrientation,
        layerDepths: [CGFloat],
        layerCount: Int
    ) -> GraphLayout {
        var positions: [NodeID: CGPoint] = [:]
        positions.reserveCapacity(canonical.count)
        for (id, c) in canonical {
            switch orientation {
            case .topToBottom: positions[id] = c
            case .leftToRight: positions[id] = CGPoint(x: c.y, y: c.x)
            }
        }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for (id, p) in positions {
            let w = widths[id] ?? NodeLabelMetrics.minWidth
            minX = min(minX, p.x - w / 2)
            maxX = max(maxX, p.x + w / 2)
            minY = min(minY, p.y - nodeHeight / 2)
            maxY = max(maxY, p.y + nodeHeight / 2)
        }
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return GraphLayout(
            positions: positions,
            widths: widths,
            nodeHeight: nodeHeight,
            orientation: orientation,
            layerCount: layerCount,
            layerDepths: layerDepths,
            bounds: bounds
        )
    }
}
