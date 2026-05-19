import Foundation

nonisolated struct FocusEntry: Equatable, Sendable {
    let anchor: NodeID
    let upstreamHops: Int
    let downstreamHops: Int
}

@MainActor
final class FocusHistory {

    static let defaultUpstreamHops = 3
    static let defaultDownstreamHops = 3
    static let maxHops = 8
    static let minHops = 0

    private(set) var current: FocusEntry?
    private var back: [FocusEntry] = []
    private var forward: [FocusEntry?] = []

    var canGoBack: Bool { !back.isEmpty || current != nil }
    var canGoForward: Bool { !forward.isEmpty }

    func push(_ entry: FocusEntry) {
        if let cur = current { back.append(cur) }
        current = entry
        forward.removeAll(keepingCapacity: true)
    }

    func clear() {
        if let cur = current { back.append(cur) }
        current = nil
        forward.removeAll(keepingCapacity: true)
    }

    func adjustHops(upstream: Int? = nil, downstream: Int? = nil) {
        guard let cur = current else { return }
        let up = clampHops(upstream ?? cur.upstreamHops)
        let down = clampHops(downstream ?? cur.downstreamHops)
        current = FocusEntry(anchor: cur.anchor, upstreamHops: up, downstreamHops: down)
    }

    @discardableResult
    func goBack() -> FocusEntry? {
        guard let cur = current else {
            // Already at overview; nothing to do.
            return nil
        }
        forward.append(cur)
        if let prev = back.popLast() {
            current = prev
        } else {
            current = nil
        }
        return current
    }

    @discardableResult
    func goForward() -> FocusEntry? {
        guard let next = forward.popLast() else { return nil }
        if let cur = current {
            back.append(cur)
        }
        current = next
        return current
    }

    private func clampHops(_ value: Int) -> Int {
        max(Self.minHops, min(Self.maxHops, value))
    }
}
