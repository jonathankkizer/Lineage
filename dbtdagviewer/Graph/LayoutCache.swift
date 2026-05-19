import Foundation

actor LayoutCache {
    static let shared = LayoutCache()

    private var cache: [String: GraphLayout] = [:]

    func layout(for graph: Graph, computeIfMissing: @Sendable () async -> GraphLayout) async -> GraphLayout {
        if let hit = cache[graph.invocationID] { return hit }
        let l = await computeIfMissing()
        cache[graph.invocationID] = l
        return l
    }
}
