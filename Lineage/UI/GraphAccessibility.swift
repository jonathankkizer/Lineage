import AppKit

/// Sendable handle to the owning canvas.
///
/// `GraphNodeAccessibilityElement`'s overrides are nonisolated (that's how the
/// SDK declares them) but everything they read lives on the MainActor, so each
/// one hops through `MainActor.assumeIsolated`. Those closures can't capture the
/// element itself — a non-Sendable class instance crossing into a MainActor
/// closure is exactly what region isolation rejects — so the view reference is
/// held in this box and captured on its own instead.
nonisolated final class GraphViewBox: @unchecked Sendable {
    nonisolated(unsafe) weak var view: GraphView?

    init(_ view: GraphView) {
        self.view = view
    }
}

/// Accessibility proxy for one node on the graph canvas.
///
/// The canvas is a single `NSView` over CALayers, so without these VoiceOver
/// sees one unlabeled group where a sighted user sees the whole project. Values
/// and frames are computed on demand from the live graph and viewport rather
/// than cached — the user pans and zooms constantly, and a stale frame is worse
/// than a slow one.
///
/// AppKit delivers accessibility callbacks on the main thread, which is what
/// makes the `assumeIsolated` hops safe — the same assumption
/// `DbtProjectDocument.read(from:ofType:)` relies on.
nonisolated final class GraphNodeAccessibilityElement: NSAccessibilityElement {

    let nodeID: NodeID
    private let box: GraphViewBox

    init(nodeID: NodeID, graphView: GraphView) {
        self.nodeID = nodeID
        self.box = GraphViewBox(graphView)
        super.init()
        setAccessibilityParent(graphView)
    }

    override func accessibilityRole() -> NSAccessibility.Role? { .button }

    override func accessibilityRoleDescription() -> String? { "graph node" }

    override func isAccessibilityElement() -> Bool { true }

    override func accessibilityLabel() -> String? {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated { box.view?.accessibilityNodeLabel(for: id) }
    }

    override func accessibilityValue() -> Any? {
        let (box, id) = (self.box, self.nodeID)
        // Bound to String? rather than returned straight through: the declared
        // `Any?` return isn't Sendable, so it can't cross the isolation hop.
        let value: String? = MainActor.assumeIsolated { box.view?.accessibilityNodeValue(for: id) }
        return value
    }

    override func accessibilityHelp() -> String? {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated { box.view?.accessibilityNodeHelp(for: id) }
    }

    override func accessibilityFrame() -> NSRect {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated { box.view?.accessibilityScreenRect(for: id) ?? .zero }
    }

    override func isAccessibilitySelected() -> Bool {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated { box.view?.selection.selected.contains(id) ?? false }
    }

    override func setAccessibilitySelected(_ accessibilitySelected: Bool) {
        let (box, id) = (self.box, self.nodeID)
        MainActor.assumeIsolated {
            guard let view = box.view else { return }
            if accessibilitySelected {
                view.selection.replace(with: id)
                view.reveal(nodeID: id)
            } else {
                view.selection.toggle(id)
            }
        }
    }

    override func isAccessibilityFocused() -> Bool {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated { box.view?.selection.primary == id }
    }

    override func setAccessibilityFocused(_ accessibilityFocused: Bool) {
        guard accessibilityFocused else { return }
        let (box, id) = (self.box, self.nodeID)
        MainActor.assumeIsolated {
            guard let view = box.view else { return }
            view.selection.replace(with: id)
            view.reveal(nodeID: id)
        }
    }

    /// VO-Space on a node enters focus mode on it, matching double-click.
    override func accessibilityPerformPress() -> Bool {
        let (box, id) = (self.box, self.nodeID)
        return MainActor.assumeIsolated {
            guard let view = box.view else { return false }
            view.selection.replace(with: id)
            NSApp.sendAction(#selector(LineageActions.focusOnSelection(_:)), to: nil, from: view)
            return true
        }
    }
}
