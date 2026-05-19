import Foundation

enum Topology {

    nonisolated static func topologicallySort(_ graph: Graph) -> [NodeID] {
        var inDegree: [NodeID: Int] = [:]
        inDegree.reserveCapacity(graph.nodes.count)
        for id in graph.nodes.keys {
            inDegree[id] = graph.parents(of: id).count
        }

        var queue: [NodeID] = inDegree.compactMap { $1 == 0 ? $0 : nil }
        queue.sort { $0.rawValue < $1.rawValue }

        var result: [NodeID] = []
        result.reserveCapacity(graph.nodes.count)

        while !queue.isEmpty {
            let next = queue.removeFirst()
            result.append(next)
            var newlyReady: [NodeID] = []
            for child in graph.children(of: next) {
                guard let d = inDegree[child] else { continue }
                let nd = d - 1
                inDegree[child] = nd
                if nd == 0 { newlyReady.append(child) }
            }
            if !newlyReady.isEmpty {
                newlyReady.sort { $0.rawValue < $1.rawValue }
                queue.append(contentsOf: newlyReady)
            }
        }

        if result.count < graph.nodes.count {
            let remaining = graph.nodes.keys.filter { !result.contains($0) }.sorted { $0.rawValue < $1.rawValue }
            result.append(contentsOf: remaining)
        }

        return result
    }

    nonisolated static func longestPathLayers(_ graph: Graph, topoOrder: [NodeID]) -> [NodeID: Int] {
        var layer: [NodeID: Int] = [:]
        layer.reserveCapacity(graph.nodes.count)
        for id in topoOrder {
            let parents = graph.parents(of: id)
            if parents.isEmpty {
                layer[id] = 0
            } else {
                let maxParent = parents.compactMap { layer[$0] }.max() ?? 0
                layer[id] = maxParent + 1
            }
        }
        return layer
    }

    nonisolated static func roots(_ graph: Graph) -> [NodeID] {
        graph.nodes.keys.filter { graph.parents(of: $0).isEmpty }
    }

    nonisolated static func leaves(_ graph: Graph) -> [NodeID] {
        graph.nodes.keys.filter { graph.children(of: $0).isEmpty }
    }
}
