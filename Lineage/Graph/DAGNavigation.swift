import CoreGraphics
import Foundation

nonisolated enum DAGNavigation {

    enum Direction: Sendable {
        case up, down, left, right
    }

    /// Returns the next node when navigating in `direction` from `id`.
    ///
    /// The layout is band-stacked vertically (sources at the top → models →
    /// exposures → tests at the bottom), so:
    /// - `up`   walks one edge upstream (a parent), picking the candidate
    ///   whose x position is closest to the current node's x.
    /// - `down` walks one edge downstream (a child), same x-proximity rule.
    /// - `left` / `right` move to the previous / next visible node sharing the
    ///   current node's row (same y within a node-height tolerance).
    ///
    /// `visible`, when non-nil, restricts navigation to that set so focus and
    /// search dim out-of-scope nodes.
    nonisolated static func neighbor(
        of id: NodeID,
        direction: Direction,
        graph: Graph,
        layout: GraphLayout,
        visible: Set<NodeID>? = nil
    ) -> NodeID? {
        guard let pos = layout.positions[id] else { return nil }
        let allowed: (NodeID) -> Bool = { nid in
            visible.map { $0.contains(nid) } ?? true
        }

        switch direction {
        case .up:
            return pickAlongEdge(graph.parents(of: id), referenceX: pos.x, layout: layout, allowed: allowed)
        case .down:
            return pickAlongEdge(graph.children(of: id), referenceX: pos.x, layout: layout, allowed: allowed)
        case .left:
            return pickInRow(of: id, currentPos: pos, going: .left, graph: graph, layout: layout, allowed: allowed)
        case .right:
            return pickInRow(of: id, currentPos: pos, going: .right, graph: graph, layout: layout, allowed: allowed)
        }
    }

    /// Returns the nearest visible node to `point` in content space. Used to
    /// pick a starting selection when the user hits an arrow key with nothing
    /// selected.
    nonisolated static func nearest(
        to point: CGPoint,
        graph: Graph,
        layout: GraphLayout,
        visible: Set<NodeID>? = nil
    ) -> NodeID? {
        var best: (id: NodeID, d2: CGFloat)?
        for (id, p) in layout.positions {
            if let visible, !visible.contains(id) { continue }
            guard graph.nodes[id] != nil else { continue }
            let dx = p.x - point.x
            let dy = p.y - point.y
            let d2 = dx * dx + dy * dy
            if best == nil || d2 < best!.d2 {
                best = (id, d2)
            }
        }
        return best?.id
    }

    // MARK: - Private

    private nonisolated static func pickAlongEdge(
        _ candidates: [NodeID],
        referenceX: CGFloat,
        layout: GraphLayout,
        allowed: (NodeID) -> Bool
    ) -> NodeID? {
        var best: (id: NodeID, dx: CGFloat)?
        for cid in candidates {
            guard allowed(cid), let cp = layout.positions[cid] else { continue }
            let dx = abs(cp.x - referenceX)
            if best == nil || dx < best!.dx {
                best = (cid, dx)
            }
        }
        return best?.id
    }

    private enum Horizontal { case left, right }

    private nonisolated static func pickInRow(
        of id: NodeID,
        currentPos: CGPoint,
        going dir: Horizontal,
        graph: Graph,
        layout: GraphLayout,
        allowed: (NodeID) -> Bool
    ) -> NodeID? {
        let yTolerance = max(layout.nodeHeight * 0.5, 1)
        var best: (id: NodeID, dx: CGFloat)?
        for (other, otherPos) in layout.positions {
            if other == id { continue }
            guard graph.nodes[other] != nil, allowed(other) else { continue }
            if abs(otherPos.y - currentPos.y) > yTolerance { continue }
            let signedDx = otherPos.x - currentPos.x
            switch dir {
            case .left where signedDx >= -0.5: continue
            case .right where signedDx <= 0.5: continue
            default: break
            }
            let absDx = abs(signedDx)
            if best == nil || absDx < best!.dx {
                best = (other, absDx)
            }
        }
        return best?.id
    }
}
