import Foundation

nonisolated struct LayoutCacheKey: Hashable, Sendable {
    let invocationID: String
    let algorithm: GraphLayoutAlgorithm
    let filter: NodeFilter
}

/// Memoizes computed layouts so toggling algorithm/filter back to a previous
/// state is instant instead of a 200–400ms recompute. Bounded LRU keyed on
/// (build, algorithm, filter) — the filter is part of the key because a
/// filtered graph keeps the full graph's `invocationID`.
actor LayoutCache {
    static let shared = LayoutCache()

    private var cache: [LayoutCacheKey: GraphLayout] = [:]
    private var order: [LayoutCacheKey] = []
    private let capacity = 16

    func layout(
        key: LayoutCacheKey,
        computeIfMissing: @Sendable () async -> GraphLayout
    ) async -> GraphLayout {
        if let hit = cache[key] {
            touch(key)
            return hit
        }
        let computed = await computeIfMissing()
        // A concurrent caller may have filled it while we awaited.
        if let hit = cache[key] {
            touch(key)
            return hit
        }
        cache[key] = computed
        order.append(key)
        if order.count > capacity {
            let evicted = order.removeFirst()
            cache.removeValue(forKey: evicted)
        }
        return computed
    }

    func clear() {
        cache.removeAll()
        order.removeAll()
    }

    private func touch(_ key: LayoutCacheKey) {
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
            order.append(key)
        }
    }
}
