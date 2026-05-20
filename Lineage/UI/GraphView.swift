import AppKit
import QuartzCore

@MainActor
final class GraphView: NSView, NSMenuItemValidation {

    let renderer: GraphRenderer
    let selection: SelectionModel

    private var viewport: Viewport = .identity
    private var hasContent = false
    private var trackingArea: NSTrackingArea?
    private var magnifyRecognizer: NSMagnificationGestureRecognizer!

    private enum DragState {
        case none
        case marquee(start: CGPoint)
    }
    private var dragState: DragState = .none
    private var selectionObserverID: UUID?

    init(selection: SelectionModel, renderer: GraphRenderer = CALayerGraphRenderer()) {
        self.selection = selection
        self.renderer = renderer
        super.init(frame: .zero)
        wantsLayer = true
        layer = renderer.rootLayer
        renderer.rootLayer.frame = bounds

        magnifyRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handleMagnify(_:)))
        addGestureRecognizer(magnifyRecognizer)

        selectionObserverID = selection.addObserver { [weak self] model in
            self?.renderer.setSelection(model.selected, primary: model.primary)
        }
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        if let id = selectionObserverID {
            Task { @MainActor [selection] in selection.removeObserver(id) }
        }
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var wantsUpdateLayer: Bool { true }

    override var frame: NSRect {
        didSet {
            renderer.rootLayer.frame = bounds
        }
    }

    override func layout() {
        super.layout()
        renderer.rootLayer.frame = bounds
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        if let scale = window?.backingScaleFactor, let r = renderer as? CALayerGraphRenderer {
            r.updateBackingScale(scale)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance { [renderer] in
            renderer.refreshColors()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let scale = window?.backingScaleFactor, let r = renderer as? CALayerGraphRenderer {
            r.updateBackingScale(scale)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    func install(graph: Graph, layout: GraphLayout) {
        renderer.install(graph: graph, layout: layout)
        hasContent = true
        zoomToFit()
    }

    func zoomToFit() {
        guard hasContent else { return }
        viewport = Viewport.fitting(renderer.contentBounds, in: bounds)
        applyViewport()
    }

    func zoomIn() { zoom(by: 1.25, around: CGPoint(x: bounds.midX, y: bounds.midY)) }
    func zoomOut() { zoom(by: 1 / 1.25, around: CGPoint(x: bounds.midX, y: bounds.midY)) }
    func resetZoom() {
        viewport = Viewport(translation: CGPoint(x: bounds.midX, y: bounds.midY), scale: 1)
        applyViewport()
    }

    private func zoom(by factor: CGFloat, around pivot: CGPoint) {
        let newScale = max(0.05, min(viewport.scale * factor, 6.0))
        let actualFactor = newScale / viewport.scale
        viewport.translation.x = pivot.x - (pivot.x - viewport.translation.x) * actualFactor
        viewport.translation.y = pivot.y - (pivot.y - viewport.translation.y) * actualFactor
        viewport.scale = newScale
        applyViewport()
    }

    private func applyViewport(animationDuration: CFTimeInterval = 0) {
        renderer.setViewport(viewport.transform, animationDuration: animationDuration)
        renderer.setLevelOfDetail(zoomScale: viewport.scale)
    }

    func applyFocus(scope: SelectionScope?, animationDuration: CFTimeInterval, reframe: Bool = true) {
        renderer.setFocus(scope, animationDuration: animationDuration)
        guard reframe else { return }
        let target = renderer.focusBounds()
        if target.width > 0, target.height > 0 {
            viewport = Viewport.fitting(target, in: bounds, padding: 48)
            applyViewport(animationDuration: animationDuration)
        }
    }

    func setColoring(_ mode: NodeColoring) {
        renderer.setColoring(mode)
    }

    func setBuildTimings(_ timings: BuildTimings) {
        renderer.setBuildTimings(timings)
    }

    func setBulkEdgesEnabled(_ enabled: Bool) {
        renderer.setBulkEdgesEnabled(enabled)
    }

    func areBulkEdgesEnabled() -> Bool {
        renderer.areBulkEdgesEnabled()
    }

    func resetBulkEdgesToAuto() {
        renderer.resetBulkEdgesToAuto()
    }

    // MARK: - Input

    override func scrollWheel(with event: NSEvent) {
        guard hasContent else { return }
        var dx = event.scrollingDeltaX
        var dy = event.scrollingDeltaY
        if !event.hasPreciseScrollingDeltas {
            dx *= 8
            dy *= 8
        }
        viewport.translation.x += dx
        viewport.translation.y += dy
        applyViewport()
    }

    @objc private func handleMagnify(_ recognizer: NSMagnificationGestureRecognizer) {
        guard hasContent else { return }
        let pivot = recognizer.location(in: self)
        let factor = 1 + recognizer.magnification
        recognizer.magnification = 0
        zoom(by: factor, around: pivot)
    }

    override func mouseDown(with event: NSEvent) {
        guard hasContent else { return }
        let viewPoint = convert(event.locationInWindow, from: nil)
        let contentPoint = viewport.contentPoint(fromView: viewPoint)

        if let id = renderer.nodeID(atContentPoint: contentPoint) {
            if event.modifierFlags.contains(.command) {
                selection.toggle(id)
            } else if event.modifierFlags.contains(.shift) {
                selection.extend(with: id)
            } else {
                selection.replace(with: id)
            }
            dragState = .none
            window?.makeFirstResponder(self)
            if event.clickCount == 2 {
                NSApp.sendAction(#selector(LineageActions.focusOnSelection(_:)), to: nil, from: self)
            }
            return
        }

        if !event.modifierFlags.contains(.shift), !event.modifierFlags.contains(.command) {
            selection.clear()
        }
        dragState = .marquee(start: contentPoint)
        renderer.setMarquee(CGRect(origin: contentPoint, size: .zero))
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        // Raw Return/Enter focuses the selection without requiring the Cmd modifier
        // the menu shortcut uses (Cmd+Return). Esc clears focus. Menu key equivalents
        // cover the modifier-prefixed forms; this override adds the plain-key UX
        // for when GraphView is firstResponder.
        switch event.specialKey {
        case .carriageReturn, .enter:
            if selection.primary != nil {
                NSApp.sendAction(#selector(LineageActions.focusOnSelection(_:)), to: nil, from: self)
            }
        default:
            if event.charactersIgnoringModifiers == "\u{1B}" {
                NSApp.sendAction(#selector(LineageActions.clearFocus(_:)), to: nil, from: self)
            } else {
                super.keyDown(with: event)
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard case .marquee(let start) = dragState else { return }
        let viewPoint = convert(event.locationInWindow, from: nil)
        let contentPoint = viewport.contentPoint(fromView: viewPoint)
        let rect = CGRect(
            x: min(start.x, contentPoint.x),
            y: min(start.y, contentPoint.y),
            width: abs(contentPoint.x - start.x),
            height: abs(contentPoint.y - start.y)
        )
        renderer.setMarquee(rect)
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragState = .none; renderer.setMarquee(nil) }
        guard case .marquee(let start) = dragState else { return }
        let viewPoint = convert(event.locationInWindow, from: nil)
        let contentPoint = viewport.contentPoint(fromView: viewPoint)
        let rect = CGRect(
            x: min(start.x, contentPoint.x),
            y: min(start.y, contentPoint.y),
            width: abs(contentPoint.x - start.x),
            height: abs(contentPoint.y - start.y)
        )
        guard rect.width > 4 || rect.height > 4 else { return }
        let ids = Set(renderer.nodeIDs(inContentRect: rect))
        if event.modifierFlags.contains(.shift) {
            selection.replace(with: selection.selected.union(ids))
        } else {
            selection.replace(with: ids)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let contentPoint = viewport.contentPoint(fromView: viewPoint)
        let id = renderer.nodeID(atContentPoint: contentPoint)
        renderer.setHover(id)
        updateTooltip(for: id)
    }

    override func mouseExited(with event: NSEvent) {
        renderer.setHover(nil)
        updateTooltip(for: nil)
    }

    private func updateTooltip(for id: NodeID?) {
        guard let id, let name = renderer.displayName(for: id), NodeLabelMetrics.isTruncated(name) else {
            if toolTip != nil { toolTip = nil }
            return
        }
        if toolTip != name { toolTip = name }
    }

    // MARK: - Menu actions (responder chain)

    @objc func zoomInGraph(_ sender: Any?) { zoomIn() }
    @objc func zoomOutGraph(_ sender: Any?) { zoomOut() }
    @objc func zoomToFitGraph(_ sender: Any?) { zoomToFit() }
    @objc func resetZoomGraph(_ sender: Any?) { resetZoom() }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let zoomActions: Set<Selector> = [
            #selector(zoomInGraph(_:)),
            #selector(zoomOutGraph(_:)),
            #selector(zoomToFitGraph(_:)),
            #selector(resetZoomGraph(_:)),
        ]
        if let action = menuItem.action, zoomActions.contains(action) {
            return hasContent
        }
        return true
    }
}
