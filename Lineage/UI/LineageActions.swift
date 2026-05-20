import AppKit

// Compile-time-checked selector surface for the responder chain.
// Menu items and `NSApp.sendAction(_:to:from:)` reference these via
// `#selector(LineageActions.foo(_:))` so a typo is a build error rather than
// a silently-disabled menu item. No type needs to actually conform — the
// `@objc` declarations are enough for `#selector` to resolve the name.
@MainActor @objc protocol LineageActions {
    // Document
    func reloadProject(_ sender: Any?)

    // View / zoom
    func zoomInGraph(_ sender: Any?)
    func zoomOutGraph(_ sender: Any?)
    func resetZoomGraph(_ sender: Any?)
    func zoomToFitGraph(_ sender: Any?)
    func toggleInspector(_ sender: Any?)
    func toggleShowAllEdges(_ sender: Any?)

    // Filters
    func toggleShowTests(_ sender: Any?)
    func toggleShowSources(_ sender: Any?)
    func toggleShowOrphanSources(_ sender: Any?)
    func toggleShowSeeds(_ sender: Any?)
    func toggleShowExposures(_ sender: Any?)
    func resetFilter(_ sender: Any?)

    // Search / focus
    func focusFilterField(_ sender: Any?)
    func focusOnSelection(_ sender: Any?)
    func clearFocus(_ sender: Any?)
    func focusBack(_ sender: Any?)
    func focusForward(_ sender: Any?)
    func expandFocus(_ sender: Any?)
    func contractFocus(_ sender: Any?)

    // Help
    func openReleasesPage(_ sender: Any?)
}
