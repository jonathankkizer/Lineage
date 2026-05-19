import CoreGraphics
import Foundation

nonisolated struct SpatialIndex: Sendable {
    let cellSize: CGFloat
    let cells: [Cell: [NodeID]]
    let nodeRects: [NodeID: CGRect]

    struct Cell: Hashable, Sendable {
        let x: Int
        let y: Int
    }

    static func build(
        positions: [NodeID: CGPoint],
        widths: [NodeID: CGFloat],
        nodeHeight: CGFloat,
        defaultWidth: CGFloat
    ) -> SpatialIndex {
        let cellSize = max(defaultWidth, nodeHeight) * 3
        var cells: [Cell: [NodeID]] = [:]
        var nodeRects: [NodeID: CGRect] = [:]
        nodeRects.reserveCapacity(positions.count)

        for (id, p) in positions {
            let w = widths[id] ?? defaultWidth
            let r = CGRect(
                x: p.x - w / 2,
                y: p.y - nodeHeight / 2,
                width: w,
                height: nodeHeight
            )
            nodeRects[id] = r
            for cell in Self.cells(spanning: r, cellSize: cellSize) {
                cells[cell, default: []].append(id)
            }
        }

        return SpatialIndex(cellSize: cellSize, cells: cells, nodeRects: nodeRects)
    }

    func query(point: CGPoint) -> NodeID? {
        let cell = Cell(x: Int((point.x / cellSize).rounded(.down)), y: Int((point.y / cellSize).rounded(.down)))
        guard let candidates = cells[cell] else { return nil }
        return candidates.first { nodeRects[$0]?.contains(point) == true }
    }

    func query(rect: CGRect) -> [NodeID] {
        var result: Set<NodeID> = []
        for cell in Self.cells(spanning: rect, cellSize: cellSize) {
            guard let ids = cells[cell] else { continue }
            for id in ids {
                guard let r = nodeRects[id] else { continue }
                if rect.intersects(r) { result.insert(id) }
            }
        }
        return Array(result)
    }

    private static func cells(spanning rect: CGRect, cellSize: CGFloat) -> [Cell] {
        let minX = Int((rect.minX / cellSize).rounded(.down))
        let maxX = Int((rect.maxX / cellSize).rounded(.down))
        let minY = Int((rect.minY / cellSize).rounded(.down))
        let maxY = Int((rect.maxY / cellSize).rounded(.down))
        var out: [Cell] = []
        for x in minX...maxX {
            for y in minY...maxY {
                out.append(Cell(x: x, y: y))
            }
        }
        return out
    }
}
