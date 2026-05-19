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
    private var focusSet: Set<NodeID>?
    private var lastAffected: Set<NodeID> = []
    private var coloringMode: NodeColoring = .kind
    private var buildTimings: BuildTimings = .empty

    static let focusedOpacity: Float = 1.0
    static let unfocusedOpacity: Float = 0.07

    private enum LODBucket: Int { case full, noLabels, simplified, hidden }
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
        index = SpatialIndex.build(positions: layout.positions, nodeSize: layout.nodeSize)

        nodeContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        nodeLayers.removeAll(keepingCapacity: true)
        nodeLayers.reserveCapacity(graph.nodes.count)
        lastAffected.removeAll(keepingCapacity: true)
        focusSet = nil

        for (id, point) in layout.positions {
            guard let node = graph.nodes[id] else { continue }
            let layer = makeNodeLayer(node: node, center: point, size: layout.nodeSize)
            nodeLayers[id] = layer
            nodeContainerLayer.addSublayer(layer)
        }

        rebuildEdgePath()
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
        if zoomScale < 0.1 { bucket = .hidden }
        else if zoomScale < 0.3 { bucket = .simplified }
        else if zoomScale < 0.5 { bucket = .noLabels }
        else { bucket = .full }

        guard bucket != lastLOD else { return }
        lastLOD = bucket

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let showLabels = (bucket == .full)
        let showNodes = (bucket != .hidden)

        for (id, layer) in nodeLayers {
            layer.isHidden = !showNodes
            if showLabels {
                if layer.contents == nil, let node = graph?.nodes[id], let size = layout?.nodeSize {
                    layer.contents = labelCache.image(text: node.id.displayName, kind: node.kind, size: size, backingScale: backingScale)
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

    func setFocus(_ ids: Set<NodeID>?, animationDuration: CFTimeInterval) {
        focusSet = ids
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
        guard let focusSet, !focusSet.isEmpty, let layout else { return contentBounds }
        let halfW = layout.nodeSize.width / 2
        let halfH = layout.nodeSize.height / 2
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for id in focusSet {
            guard let p = layout.positions[id] else { continue }
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

    private func reapplyNodeColors() {
        guard let graph else { return }
        for (id, layer) in nodeLayers {
            guard let node = graph.nodes[id] else { continue }
            let fill = resolveFill(id: id, kind: node.kind)
            layer.backgroundColor = fill.cgColor
            layer.borderColor = RendererColors.border(for: fill).cgColor
        }
    }

    private func resolveFill(id: NodeID, kind: ResourceKind) -> NSColor {
        switch coloringMode {
        case .kind:
            return RendererColors.fill(for: kind)
        case .buildTime:
            if let p = buildTimings.colorScore[id] {
                return RendererColors.buildTimeFill(score: p)
            }
            return RendererColors.untimedFill(for: kind)
        }
    }

    private func applyFocus() {
        for (id, layer) in nodeLayers {
            let opacity = isInFocus(id) ? Self.focusedOpacity : Self.unfocusedOpacity
            layer.opacity = opacity
        }
    }

    private func isInFocus(_ id: NodeID) -> Bool {
        guard let focusSet else { return true }
        return focusSet.contains(id)
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

    func nodeIDs(inContentRect rect: CGRect) -> [NodeID] {
        index?.query(rect: rect) ?? []
    }

    private func makeNodeLayer(node: GraphNode, center: CGPoint, size: CGSize) -> CALayer {
        let layer = CALayer()
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.bounds = CGRect(origin: .zero, size: size)
        layer.position = center
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        let fill = resolveFill(id: node.id, kind: node.kind)
        layer.backgroundColor = fill.cgColor
        layer.borderColor = RendererColors.border(for: fill).cgColor
        layer.contentsScale = backingScale
        layer.contentsGravity = .center
        layer.opacity = isInFocus(node.id) ? Self.focusedOpacity : Self.unfocusedOpacity
        layer.actions = ["contents": NSNull(), "borderColor": NSNull(), "borderWidth": NSNull(), "backgroundColor": NSNull()]
        layer.contents = labelCache.image(text: node.id.displayName, kind: node.kind, size: size, backingScale: backingScale)
        return layer
    }

    private func rebuildLabels() {
        guard let graph, let size = layout?.nodeSize else { return }
        for (id, layer) in nodeLayers {
            guard let node = graph.nodes[id] else { continue }
            layer.contents = labelCache.image(text: node.id.displayName, kind: node.kind, size: size, backingScale: backingScale)
        }
    }

    private func rebuildEdgePath() {
        guard let graph, let layout else { return }
        let path = CGMutablePath()
        let half = layout.nodeSize.height / 2

        for (parent, children) in graph.forward {
            guard let p = layout.positions[parent] else { continue }
            let parentInFocus = isInFocus(parent)
            for child in children {
                guard let c = layout.positions[child] else { continue }
                if focusSet != nil, !(parentInFocus && isInFocus(child)) { continue }
                path.move(to: CGPoint(x: p.x, y: p.y + half))
                path.addLine(to: CGPoint(x: c.x, y: c.y - half))
            }
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeLayer.path = path
        CATransaction.commit()
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
            let fill = resolveFill(id: id, kind: kind)
            layer.borderColor = RendererColors.border(for: fill).cgColor
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
                let fill = resolveFill(id: id, kind: kind)
                layer.borderColor = RendererColors.border(for: fill).cgColor
                layer.borderWidth = 1
            }
        }

        lastAffected = affected

        guard let graph, let layout else {
            selectionRingLayer.path = nil
            edgeUpstreamLayer.path = nil
            edgeDownstreamLayer.path = nil
            return
        }

        let halfH = layout.nodeSize.height / 2
        if let anchor = highlightAnchor, let ap = layout.positions[anchor] {
            let upPath = CGMutablePath()
            for parent in graph.parents(of: anchor) {
                guard let p = layout.positions[parent] else { continue }
                upPath.move(to: CGPoint(x: p.x, y: p.y + halfH))
                upPath.addLine(to: CGPoint(x: ap.x, y: ap.y - halfH))
            }
            edgeUpstreamLayer.path = upPath

            let downPath = CGMutablePath()
            for child in graph.children(of: anchor) {
                guard let c = layout.positions[child] else { continue }
                downPath.move(to: CGPoint(x: ap.x, y: ap.y + halfH))
                downPath.addLine(to: CGPoint(x: c.x, y: c.y - halfH))
            }
            edgeDownstreamLayer.path = downPath
        } else {
            edgeUpstreamLayer.path = nil
            edgeDownstreamLayer.path = nil
        }
        selectionRingLayer.path = nil
    }
}
