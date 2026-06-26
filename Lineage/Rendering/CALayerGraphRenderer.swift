import AppKit
import QuartzCore

@MainActor
final class CALayerGraphRenderer: GraphRenderer {

    let rootLayer: CALayer
    private(set) var contentBounds: CGRect = .zero

    private let contentLayer = CALayer()
    private let edgeLayer = CAShapeLayer()
    private let edgeUpstreamLayer = CAShapeLayer()
    private let edgeDownstreamLayer = CAShapeLayer()
    private let nodeContainerLayer = CALayer()
    private let selectionRingLayer = CAShapeLayer()
    private let marqueeLayer = CAShapeLayer()

    private var graph: Graph?
    private var layout: GraphLayout?
    private var index: SpatialIndex?
    private var nodeLayers: [NodeID: CALayer] = [:]
    private let labelCache = NodeLabelCache()
    private var backingScale: CGFloat = 2.0

    private var currentSelection: Set<NodeID> = []
    private var primarySelection: NodeID?
    private var currentHover: NodeID?
    private var focusScope: SelectionScope?
    private var lastAffected: Set<NodeID> = []
    private var filledSelection: Set<NodeID> = []
    private var coloringMode: NodeColoring = .kind
    private var buildTimings: BuildTimings = .empty
    private var totalEdgeCount: Int = 0
    private var bulkEdgesEnabled: Bool = true

    static let focusedOpacity: Float = 1.0
    static let unfocusedOpacity: Float = 0.07
    static let bulkEdgeRenderCap = 800

    private enum LODBucket: Int { case full, noLabels, overview }
    private var lastLOD: LODBucket = .full

    init() {
        rootLayer = CALayer()
        rootLayer.backgroundColor = RendererColors.background.cgColor
        rootLayer.masksToBounds = true

        contentLayer.anchorPoint = .zero
        contentLayer.bounds = .zero

        edgeLayer.fillColor = nil
        edgeLayer.strokeColor = RendererColors.edge.cgColor
        edgeLayer.lineWidth = 1
        edgeLayer.lineJoin = .round
        edgeLayer.lineCap = .round

        edgeUpstreamLayer.fillColor = nil
        edgeUpstreamLayer.strokeColor = RendererColors.edgeUpstream.cgColor
        edgeUpstreamLayer.lineWidth = 1.5
        edgeUpstreamLayer.lineJoin = .round
        edgeUpstreamLayer.lineCap = .round

        edgeDownstreamLayer.fillColor = nil
        edgeDownstreamLayer.strokeColor = RendererColors.edgeDownstream.cgColor
        edgeDownstreamLayer.lineWidth = 1.5
        edgeDownstreamLayer.lineJoin = .round
        edgeDownstreamLayer.lineCap = .round

        selectionRingLayer.fillColor = nil
        selectionRingLayer.strokeColor = RendererColors.selection.cgColor
        selectionRingLayer.lineWidth = 2

        marqueeLayer.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        marqueeLayer.strokeColor = RendererColors.selection.cgColor
        marqueeLayer.lineWidth = 1

        contentLayer.addSublayer(edgeLayer)
        contentLayer.addSublayer(edgeUpstreamLayer)
        contentLayer.addSublayer(edgeDownstreamLayer)
        contentLayer.addSublayer(nodeContainerLayer)
        contentLayer.addSublayer(selectionRingLayer)
        rootLayer.addSublayer(contentLayer)
        rootLayer.addSublayer(marqueeLayer)
    }

    func updateBackingScale(_ scale: CGFloat) {
        guard scale != backingScale else { return }
        backingScale = scale
        rootLayer.contentsScale = scale
        contentLayer.contentsScale = scale
        for layer in nodeLayers.values {
            layer.contentsScale = scale
        }
        labelCache.clear()
        rebuildLabels()
    }

    func install(graph: Graph, layout: GraphLayout) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        self.graph = graph
        self.layout = layout
        contentBounds = layout.bounds
        index = SpatialIndex.build(
            positions: layout.positions,
            widths: layout.widths,
            nodeHeight: layout.nodeHeight,
            defaultWidth: NodeLabelMetrics.minWidth
        )

        nodeContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        nodeLayers.removeAll(keepingCapacity: true)
        nodeLayers.reserveCapacity(graph.nodes.count)
        lastAffected.removeAll(keepingCapacity: true)
        filledSelection.removeAll(keepingCapacity: true)
        focusScope = nil

        for (id, point) in layout.positions {
            guard let node = graph.nodes[id] else { continue }
            let size = CGSize(width: layout.width(for: id), height: layout.nodeHeight)
            let layer = makeNodeLayer(node: node, center: point, size: size)
            nodeLayers[id] = layer
            nodeContainerLayer.addSublayer(layer)
        }

        totalEdgeCount = graph.forward.values.reduce(0) { $0 + $1.count }

        rebuildEdgePath()
        applyBulkEdgeVisibility()
        rebuildHighlights()
    }

    /// Animate to a new layout for the SAME node set (e.g. switching layout
    /// algorithm). Reuses the existing node layers and morphs the edge path
    /// instead of tearing everything down, so positions glide.
    func setLayout(_ newLayout: GraphLayout, animationDuration: CFTimeInterval) {
        guard graph != nil else {
            return
        }
        layout = newLayout
        contentBounds = newLayout.bounds
        index = SpatialIndex.build(
            positions: newLayout.positions,
            widths: newLayout.widths,
            nodeHeight: newLayout.nodeHeight,
            defaultWidth: NodeLabelMetrics.minWidth
        )

        CATransaction.begin()
        if animationDuration > 0 {
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        for (id, layer) in nodeLayers {
            guard let p = newLayout.positions[id] else { continue }
            layer.position = p
        }
        edgeLayer.path = buildEdgePath()
        CATransaction.commit()

        applyBulkEdgeVisibility()
        rebuildHighlights()
    }

    func setViewport(_ transform: CGAffineTransform, animationDuration: CFTimeInterval) {
        CATransaction.begin()
        if animationDuration > 0 {
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        contentLayer.setAffineTransform(transform)
        CATransaction.commit()
    }

    func setLevelOfDetail(zoomScale: CGFloat) {
        let bucket: LODBucket
        if zoomScale < 0.2 { bucket = .overview }
        else if zoomScale < 0.5 { bucket = .noLabels }
        else { bucket = .full }

        guard bucket != lastLOD else { return }
        lastLOD = bucket

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let showLabels = (bucket == .full)
        let nonOverview = (bucket != .overview)

        applyBulkEdgeVisibility()
        edgeUpstreamLayer.isHidden = !nonOverview
        edgeDownstreamLayer.isHidden = !nonOverview

        for (id, layer) in nodeLayers {
            layer.isHidden = false
            if showLabels {
                if layer.contents == nil, let node = graph?.nodes[id], let layout {
                    let size = CGSize(width: layout.width(for: id), height: layout.nodeHeight)
                    layer.contents = nodeImage(node: node, size: size, selected: currentSelection.contains(id))
                }
            } else {
                layer.contents = nil
            }
        }
    }

    func setSelection(_ ids: Set<NodeID>, primary: NodeID?) {
        currentSelection = ids
        primarySelection = primary
        rebuildHighlights()
    }

    func setHover(_ id: NodeID?) {
        guard currentHover != id else { return }
        currentHover = id
        rebuildHighlights()
    }

    func setFocus(_ scope: SelectionScope?, animationDuration: CFTimeInterval) {
        focusScope = scope
        CATransaction.begin()
        if animationDuration > 0 {
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        defer { CATransaction.commit() }
        applyFocus()
        rebuildEdgePath()
        rebuildHighlights()
    }

    func focusBounds() -> CGRect {
        guard let focusScope, !focusScope.nodes.isEmpty, let layout else { return contentBounds }
        let halfH = layout.nodeHeight / 2
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for id in focusScope.nodes {
            guard let p = layout.positions[id] else { continue }
            let halfW = layout.width(for: id) / 2
            minX = min(minX, p.x - halfW)
            maxX = max(maxX, p.x + halfW)
            minY = min(minY, p.y - halfH)
            maxY = max(maxY, p.y + halfH)
        }
        guard minX <= maxX else { return contentBounds }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func refreshColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        rootLayer.backgroundColor = RendererColors.background.cgColor
        edgeLayer.strokeColor = RendererColors.edge.cgColor
        edgeUpstreamLayer.strokeColor = RendererColors.edgeUpstream.cgColor
        edgeDownstreamLayer.strokeColor = RendererColors.edgeDownstream.cgColor
        selectionRingLayer.strokeColor = RendererColors.selection.cgColor
        marqueeLayer.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        marqueeLayer.strokeColor = RendererColors.selection.cgColor

        reapplyNodeColors()

        labelCache.clear()
        rebuildLabels()
        lastAffected.removeAll(keepingCapacity: true)
        rebuildHighlights()
    }

    func setColoring(_ mode: NodeColoring) {
        guard mode != coloringMode else { return }
        coloringMode = mode
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        reapplyNodeColors()
        lastAffected.removeAll(keepingCapacity: true)
        rebuildHighlights()
    }

    func setBuildTimings(_ timings: BuildTimings) {
        buildTimings = timings
        guard coloringMode == .buildTime else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        reapplyNodeColors()
        lastAffected.removeAll(keepingCapacity: true)
        rebuildHighlights()
    }

    func setBulkEdgesEnabled(_ enabled: Bool) {
        guard bulkEdgesEnabled != enabled else { return }
        bulkEdgesEnabled = enabled
        applyBulkEdgeVisibility()
    }

    func areBulkEdgesEnabled() -> Bool { bulkEdgesEnabled }

    func resetBulkEdgesToAuto() {
        bulkEdgesEnabled = true
        applyBulkEdgeVisibility()
    }

    private func applyBulkEdgeVisibility() {
        let shouldShow = bulkEdgesEnabled && lastLOD != .overview
        guard edgeLayer.isHidden == shouldShow else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeLayer.isHidden = !shouldShow
        CATransaction.commit()
    }

    private func reapplyNodeColors() {
        guard let graph else { return }
        for (id, layer) in nodeLayers {
            guard let node = graph.nodes[id] else { continue }
            let style = resolveChipStyle(id: id, kind: node.kind)
            layer.backgroundColor = style.fill.cgColor
            layer.borderColor = style.border.cgColor
        }
    }

    private struct ChipStyle {
        let fill: NSColor
        let border: NSColor
    }

    private func resolveChipStyle(id: NodeID, kind: ResourceKind) -> ChipStyle {
        switch coloringMode {
        case .kind:
            return ChipStyle(
                fill: RendererColors.nodeBodyFill,
                border: RendererColors.nodeBodyBorder
            )
        case .buildTime:
            if let p = buildTimings.colorScore[id] {
                return ChipStyle(
                    fill: RendererColors.buildTimeChipFill(score: p),
                    border: RendererColors.buildTimeChipBorder(score: p)
                )
            }
            return ChipStyle(
                fill: RendererColors.untimedChipFill(for: kind),
                border: RendererColors.untimedChipBorder(for: kind)
            )
        }
    }

    private func applyFocus() {
        for (id, layer) in nodeLayers {
            let opacity = isInFocus(id) ? Self.focusedOpacity : Self.unfocusedOpacity
            layer.opacity = opacity
        }
    }

    private func isInFocus(_ id: NodeID) -> Bool {
        guard let focusScope else { return true }
        return focusScope.nodes.contains(id)
    }

    private func edgeBelongsToScope(parent: NodeID, child: NodeID) -> Bool {
        guard let focusScope else { return true }
        // Lineage scope: an edge belongs iff both ends are in the same direction set.
        // Anchor lives in both sets, so anchor-incident edges always pass.
        if let upstream = focusScope.upstream, let downstream = focusScope.downstream {
            return (upstream.contains(parent) && upstream.contains(child)) ||
                   (downstream.contains(parent) && downstream.contains(child))
        }
        if let upstream = focusScope.upstream {
            return upstream.contains(parent) && upstream.contains(child)
        }
        if let downstream = focusScope.downstream {
            return downstream.contains(parent) && downstream.contains(child)
        }
        // Non-lineage scope (substring): fall back to node-set membership only.
        return focusScope.nodes.contains(parent) && focusScope.nodes.contains(child)
    }

    func setMarquee(_ rect: CGRect?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        guard let rect else {
            marqueeLayer.path = nil
            return
        }
        let path = CGPath(rect: rect, transform: nil)
        marqueeLayer.path = path
    }

    func nodeID(atContentPoint point: CGPoint) -> NodeID? {
        index?.query(point: point)
    }

    func displayName(for id: NodeID) -> String? {
        graph?.nodes[id]?.name
    }

    func nodeIDs(inContentRect rect: CGRect) -> [NodeID] {
        index?.query(rect: rect) ?? []
    }

    private func nodeImage(node: GraphNode, size: CGSize, selected: Bool) -> CGImage? {
        labelCache.image(text: node.name, kind: node.kind, size: size, backingScale: backingScale, selected: selected)
    }

    private func makeNodeLayer(node: GraphNode, center: CGPoint, size: CGSize) -> CALayer {
        let layer = CALayer()
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = center
        layer.cornerRadius = NodeLabelMetrics.cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        let selected = currentSelection.contains(node.id)
        let style = resolveChipStyle(id: node.id, kind: node.kind)
        layer.backgroundColor = (selected ? RendererColors.nodeBodyFillSelected : style.fill).cgColor
        layer.borderColor = style.border.cgColor
        layer.contentsScale = backingScale
        layer.contentsGravity = .center
        layer.opacity = isInFocus(node.id) ? Self.focusedOpacity : Self.unfocusedOpacity
        layer.actions = ["contents": NSNull(), "borderColor": NSNull(), "borderWidth": NSNull(), "backgroundColor": NSNull()]
        layer.contents = nodeImage(node: node, size: size, selected: selected)
        return layer
    }

    private func rebuildLabels() {
        guard let graph, let layout else { return }
        for (id, layer) in nodeLayers {
            guard let node = graph.nodes[id] else { continue }
            let size = CGSize(width: layout.width(for: id), height: layout.nodeHeight)
            layer.contents = nodeImage(node: node, size: size, selected: currentSelection.contains(id))
        }
    }

    private func rebuildEdgePath() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeLayer.path = buildEdgePath()
        CATransaction.commit()
    }

    private func buildEdgePath() -> CGPath {
        guard let graph, let layout else { return CGMutablePath() }
        let path = CGMutablePath()

        let useCap = focusScope == nil && totalEdgeCount > Self.bulkEdgeRenderCap
        let stride = useCap ? max(1, totalEdgeCount / Self.bulkEdgeRenderCap) : 1

        var emitIndex = 0
        let sortedParents = graph.forward.keys.sorted { $0.rawValue < $1.rawValue }
        for parent in sortedParents {
            guard let children = graph.forward[parent], let pr = layout.rect(for: parent) else { continue }
            for child in children {
                let take = (emitIndex % stride == 0)
                emitIndex += 1
                guard take else { continue }
                guard let cr = layout.rect(for: child) else { continue }
                guard edgeBelongsToScope(parent: parent, child: child) else { continue }
                Self.appendEdge(path, from: pr, to: cr, orientation: layout.orientation)
            }
        }
        return path
    }

    /// One curved (cubic-bezier) edge that exits the downstream face of the
    /// parent and enters the upstream face of the child. Orientation picks the
    /// axis: LR → right→left, TB → bottom→top.
    nonisolated private static func appendEdge(
        _ path: CGMutablePath,
        from p: CGRect,
        to c: CGRect,
        orientation: LayoutOrientation
    ) {
        let start: CGPoint, end: CGPoint, c1: CGPoint, c2: CGPoint
        switch orientation {
        case .topToBottom:
            start = CGPoint(x: p.midX, y: p.maxY)
            end = CGPoint(x: c.midX, y: c.minY)
            let dy = (end.y - start.y) * 0.5
            c1 = CGPoint(x: start.x, y: start.y + dy)
            c2 = CGPoint(x: end.x, y: end.y - dy)
        case .leftToRight:
            start = CGPoint(x: p.maxX, y: p.midY)
            end = CGPoint(x: c.minX, y: c.midY)
            let dx = (end.x - start.x) * 0.5
            c1 = CGPoint(x: start.x + dx, y: start.y)
            c2 = CGPoint(x: end.x - dx, y: end.y)
        }
        path.move(to: start)
        path.addCurve(to: end, control1: c1, control2: c2)
    }

    private func rebuildHighlights() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let highlightAnchor: NodeID? = primarySelection ?? currentHover
        let upstreamNeighbors: Set<NodeID> = highlightAnchor.flatMap { Set(graph?.parents(of: $0) ?? []) } ?? []
        let downstreamNeighbors: Set<NodeID> = highlightAnchor.flatMap { Set(graph?.children(of: $0) ?? []) } ?? []

        var affected: Set<NodeID> = currentSelection
        if let hover = currentHover { affected.insert(hover) }
        if let anchor = highlightAnchor { affected.insert(anchor) }
        affected.formUnion(upstreamNeighbors)
        affected.formUnion(downstreamNeighbors)

        let toReset = lastAffected.subtracting(affected)
        for id in toReset {
            guard let layer = nodeLayers[id], let kind = graph?.nodes[id]?.kind else { continue }
            let style = resolveChipStyle(id: id, kind: kind)
            layer.borderColor = style.border.cgColor
            layer.borderWidth = 1
        }

        for id in affected {
            guard let layer = nodeLayers[id] else { continue }
            if currentSelection.contains(id) {
                layer.borderColor = RendererColors.selection.cgColor
                layer.borderWidth = 2
            } else if id == currentHover {
                layer.borderColor = RendererColors.hover.cgColor
                layer.borderWidth = 2
            } else if upstreamNeighbors.contains(id) {
                layer.borderColor = RendererColors.edgeUpstream.cgColor
                layer.borderWidth = 1.5
            } else if downstreamNeighbors.contains(id) {
                layer.borderColor = RendererColors.edgeDownstream.cgColor
                layer.borderWidth = 1.5
            } else if let kind = graph?.nodes[id]?.kind {
                let style = resolveChipStyle(id: id, kind: kind)
                layer.borderColor = style.border.cgColor
                layer.borderWidth = 1
            }
        }

        lastAffected = affected

        // Native selection: fill the body with the accent color and swap to the
        // high-contrast label variant. Only the (small) selection set is touched.
        let showLabels = lastLOD == .full
        for id in filledSelection.subtracting(currentSelection) {
            guard let layer = nodeLayers[id], let node = graph?.nodes[id] else { continue }
            let style = resolveChipStyle(id: id, kind: node.kind)
            layer.backgroundColor = style.fill.cgColor
            if showLabels, let layout {
                let size = CGSize(width: layout.width(for: id), height: layout.nodeHeight)
                layer.contents = nodeImage(node: node, size: size, selected: false)
            }
        }
        for id in currentSelection {
            guard let layer = nodeLayers[id], let node = graph?.nodes[id] else { continue }
            layer.backgroundColor = RendererColors.nodeBodyFillSelected.cgColor
            if showLabels, let layout {
                let size = CGSize(width: layout.width(for: id), height: layout.nodeHeight)
                layer.contents = nodeImage(node: node, size: size, selected: true)
            }
        }
        filledSelection = currentSelection

        guard let graph, let layout else {
            selectionRingLayer.path = nil
            edgeUpstreamLayer.path = nil
            edgeDownstreamLayer.path = nil
            return
        }

        if let anchor = highlightAnchor, let ar = layout.rect(for: anchor), isInFocus(anchor) {
            let upPath = CGMutablePath()
            for parent in graph.parents(of: anchor) where edgeBelongsToScope(parent: parent, child: anchor) {
                guard let pr = layout.rect(for: parent) else { continue }
                Self.appendEdge(upPath, from: pr, to: ar, orientation: layout.orientation)
            }
            edgeUpstreamLayer.path = upPath

            let downPath = CGMutablePath()
            for child in graph.children(of: anchor) where edgeBelongsToScope(parent: anchor, child: child) {
                guard let cr = layout.rect(for: child) else { continue }
                Self.appendEdge(downPath, from: ar, to: cr, orientation: layout.orientation)
            }
            edgeDownstreamLayer.path = downPath
        } else {
            edgeUpstreamLayer.path = nil
            edgeDownstreamLayer.path = nil
        }
        selectionRingLayer.path = nil
    }
}
