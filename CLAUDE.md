# Lineage

A native macOS app for exploring a dbt-core project as a graph. AppKit, Swift 6, no Electron, no browser tab.

See `docs/design.md` for the original pitch.

## The goal

dbt's graph story is owned by web frontends — `dbt docs serve`, dbt Cloud lineage, Dagster's asset graph — and they all hit the same wall: laggy pan/zoom past a few hundred nodes, weak selection models, no keyboard navigation, no real platform integration. A native Mac app can be dramatically better at the things that actually matter — 120Hz trackpad-driven pan/zoom, real selection and focus models, keyboard-first navigation, Mac-native window management. The graph is the right showcase for native rendering: sparse enough to lay out cleanly, dense enough to be interesting, semantically rich enough that hover and selection states have meaningful content.

This is a personal project that happens to be defensible as a small indie app. The target user is the dbt practitioner who prefers BBEdit/Nova/Transmit over Electron, and who finds dbt-docs' graph view unusable past ~100 nodes.

## The Mac-assed bar

The whole reason this app exists rather than another web view. The rules are not negotiable:

- **AppKit only, no SwiftUI.** The apps universally cited as Mac-assed (Transmit, BBEdit, Acorn, OmniFocus, Tower, Xcode) are AppKit. SwiftUI on the Mac is still incomplete and retrofitted from iOS.
- **Programmatic UI, no XIBs or Storyboards.** Auto Layout in code, NSStackView for composition. Easier to diff, refactor, and edit with assistance.
- **Modern Swift wrapped around AppKit.** Swift 6, strict concurrency, async/await throughout. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set project-wide; pure value/compute types are explicitly `nonisolated` and `Sendable`.
- **Target macOS 26+.** Latest APIs everywhere. No back-compat overhead.
- **Document architecture via NSDocument.** A dbt project is the document. File menu, Open Recent, multi-window, sandbox-friendly URL bookmarks all flow through standard plumbing.
- **Sandboxed.** `com.apple.security.app-sandbox`, `files.user-selected.read-only`, `files.bookmarks.app-scope`. Recent documents survive relaunch through bookmark resolution.
- **Light/dark mode adapts cleanly.** All CALayer-cached `CGColor` values re-resolve on `viewDidChangeEffectiveAppearance` via `performAsCurrentDrawingAppearance`.
- **Native idioms before invention.** Source-list sidebar (NSOutlineView with `.sourceList` style), proper NSToolbar with `toggleSidebar` + `sidebarTrackingSeparator`, NSSplitViewItem with `.inspector` behavior for snap-collapse, Cmd+I to toggle the inspector (the Finder-style "Get Info" convention, not Cmd+Option+I which is Web Inspector / Xcode), Cmd+[/Cmd+] for Safari-style focus history, Cmd+F to focus the search field.

If a change feels like it requires fighting AppKit, the change is wrong. Find the native pattern.

## Architecture

Source tree under `Lineage/`:

```
App/                        @main, AppDelegate, menu bar construction
Document/                   NSDocument + NSDocumentController subclasses
Model/                      Manifest types (Codable), NodeID, ResourceKind, NodeFilter
Graph/                      Graph value type, Topology, LayeredLayout, LayoutCache, SubgraphSelector
Rendering/                  GraphRenderer protocol, CALayerGraphRenderer, SpatialIndex,
                            NodeLabelCache, RendererColors
UI/                         ProjectWindowController, GraphView, SidebarController,
                            InspectorView, FilterPopoverController, SelectionModel,
                            Viewport, FocusState
Info.plist                  ← actually at /Resources/Info.plist (outside synced group)
Lineage.entitlements
```

The `Lineage/` folder is wired into Xcode as a `PBXFileSystemSynchronizedRootGroup` — new files dropped into the folder are auto-included; no pbxproj edits needed when adding Swift sources. Info.plist lives in `Resources/` at repo root so the synced group doesn't accidentally double-include it as a bundle resource.

### Data flow

```
fixtures/.../target/manifest.json
   ↓ (background, Task.detached)
ManifestParser.parse  →  Manifest (Codable, Sendable)
   ↓
Graph.build(from:)    →  Graph (Sendable, unfiltered "fullGraph")
   ↓
Graph.filtered(by:)   →  Graph (filtered per NodeFilter)
   ↓
LayeredLayout.compute →  GraphLayout (positions + bounds, type-banded + barycenter-ordered)
   ↓ (back on MainActor)
CALayerGraphRenderer.install + GraphView.zoomToFit
```

### Renderer protocol

Rendering is hidden behind `GraphRenderer` (in `Rendering/GraphRenderer.swift`). The CALayer implementation is the only one shipped, but a `MetalGraphRenderer` could drop in without touching the rest of the app — same protocol surface for install, viewport, hit testing, selection, hover, focus.

### Threading

- All UI types are implicitly `@MainActor` (project default).
- Heavy lifting (manifest parse, graph build, layout) runs in `Task.detached` and returns to MainActor on resume.
- Value types (`Manifest`, `Graph`, `GraphLayout`, `NodeFilter`, etc.) are `nonisolated struct ... : Sendable` and cross actor boundaries cleanly.

## Core decisions

These are the non-obvious ones — read them before second-guessing the code.

1. **Edges are stored in ONE CAShapeLayer with a compound CGPath.** Never one CAShapeLayer per edge. At 3k+ edges the per-layer overhead crushes pan FPS.
2. **Labels are pre-rendered to `CGImage` and assigned to `layer.contents`.** Never `CATextLayer` (slow composition at scale).
3. **No layer shadows anywhere.** Shadow rendering forces offscreen passes that cripple frame rates. Borders + fills only.
4. **Selection/hover updates are incremental.** `rebuildHighlights` tracks the previously-affected node set and only touches layers that entered or left highlight state. Walking all 1,600 layers per hover was the main lag source before this.
5. **Filter changes are debounced (250ms).** Rapid sidebar/popover clicks coalesce into one re-filter + re-layout.
6. **Loading overlay is deferred 400ms.** Fast filter changes (the common case) never flash the overlay at all.
7. **Sidebar is only populated on full document load, not on every filter change.** Folders/tags come from `fullGraph` which doesn't change with filtering. Re-running `reloadData()` per filter caused a visual flash.
8. **Type-banded layout.** `LayeredLayout` lays out sources → seeds → models → exposures → tests as primary bands, with dependency depth as a sub-layer within the model band. Folder-cohesion is added as a 30% bias on top of dependency barycenter, hierarchically weighted (deepest folder pulls hardest).
9. **Focus mode is a visibility overlay, not a separate graph.** `setFocus(Set<NodeID>?)` dims out-of-focus nodes to 7% opacity and filters edges. The full graph layout is preserved — your spatial memory of where a node lives persists across focus changes. Focus history works like Safari Back/Forward (`Cmd+[`/`Cmd+]`).
10. **Filter scope applies uniformly to all node types.** Clicking `datamart` in the sidebar shows only nodes whose `originalFilePath` starts with `models/datamart/` — sources living in `staging/sources.yml` do not slip through. If you want to see a node's full lineage including out-of-scope ancestors, double-click it (or Cmd+Return) to enter focus mode, which computes a subgraph from the unfiltered graph.

## What ships (v1)

- AppKit shell: `@main enum AppMain`, programmatic menu bar with App / File / Edit / View / Navigate / Window / Help, Open Recent integration.
- Document architecture: opens a folder containing `dbt_project.yml + target/manifest.json`, OR a bare `target/` directly. Sandbox-safe via NSDocument's bookmark mechanism. Cmd+R reloads from disk.
- Manifest parsing (~10MB JSON): off-main, ~0.5–1.5s. Codable types narrowed to v1 fields only.
- Graph build: unifies models + sources + exposures from `parent_map`/`child_map`. Filters edges to nodes that exist in the unified set (drops macros, disabled refs).
- Layered layout with: (a) type bands, (b) barycenter crossing minimization × 4 iterations, (c) per-layer x-centering, (d) wide-layer wrapping (the 411-source layer becomes a tile, not a 65kpt strip), (e) hierarchical folder cohesion bias.
- CALayer-based rendering at ~1,600 nodes / ~3k edges. Trackpad pan/zoom with pinch-around-cursor. Click selection, marquee drag selection, hover state with directional upstream/downstream edge highlighting (blue/orange).
- Live search (`Cmd+F`): dim non-matching nodes; composes with focus.
- Filter system (`Cmd+Shift+F` opens the toolbar popover): show/hide types (Sources, Orphan Sources, Seeds, Tests, Exposures). Same toggles available under View > Show. Defaults: tests off, orphan sources off, exposures off.
- Source-list sidebar with All / FOLDERS (nested hierarchy from `original_file_path`) / TAGS sections. Single-select scopes the visible graph. Counts on every row.
- Focus mode: double-click a node or `Cmd+Return` on a selection → N hops up/down subgraph, animated viewport transition, `Cmd+[` / `Cmd+]` history, `Esc` returns to overview.
- Inspector pane (`Cmd+I` toggles): title + kind chip, schema.database subtitle, properties (right-aligned key column), tag chips with wrapping flow, file path with reveal-in-Finder arrow, description, DEPENDS ON / REFERENCED BY / COLUMNS in bordered boxes with first-8-then-disclosure truncation. List dots match edge colors (upstream=blue, downstream=orange).
- Light/dark mode + accent color adapt correctly across all custom-rendered surfaces.

## What's deferred

The architecture absorbs each of these without restructure:

- FSEvents-based reload when `target/` changes on disk
- Quick Look preview (Space bar) for compiled SQL
- `run_results.json` status badges on nodes
- `catalog.json` integration for actual column types + row counts
- Compiled SQL viewer pane
- Preferences window (classic NSToolbar pane-switcher style; not SwiftUI Settings scene)
- AppleScript dictionary + App Intents / Shortcuts
- Drag and drop (folder onto dock; node out as URL or .sql reference)
- Services menu integration
- Tabs within a window for multiple views of the same project
- Full state restoration (window position, zoom, selection, filter)
- Lineage mode (linearized ancestors → node → descendants)
- Multiple layout algorithms with toolbar picker
- Metal renderer (drop-in `MetalGraphRenderer: GraphRenderer`). Trigger: sustained <60fps pan on M-series at full project, OR projects with >5k nodes.
- Full Sugiyama (Brandes-Köpf x-coord assignment for nicer alignments)
- Edge bundling
- Tag/folder multi-select (currently single-select)
- Notarization, code signing for distribution

## Working in this codebase

### Conventions

- **No comments unless WHY is non-obvious.** Identifiers + types tell the WHAT.
- **No tests for now.** This is a personal project optimizing for velocity. Add them when something stops feeling tractable to mentally verify.
- **No SPM dependencies.** Stdlib + AppKit + UniformTypeIdentifiers. The renderer's hand-rolled bits (label cache, spatial index, layered layout) are intentional — they're either the fun part or where a dependency would lock us out of a future swap (e.g., to Metal).
- **Programmatic everything.** If you find yourself wanting a XIB, find the AppKit pattern that doesn't need one.

### Swift 6 concurrency gotchas

- **Subclasses of nonisolated AppKit classes** (`NSView`, `NSDocument`, `NSWindowController`) need explicit `nonisolated` on overrides that override nonisolated parent declarations. Example: `nonisolated override class var readableTypes: [String]` on `DbtProjectDocument`.
- **`@main` pattern**: use `@main enum AppMain { static func main() { ... } }` constructing `NSApplication.shared` manually. Do not rely on `@main class AppDelegate` or the legacy `NSApplicationMain` attribute.
- **`validateMenuItem(_:)` is not an override.** It's an `NSMenuItemValidation` protocol method. Conform explicitly; do not write `override func validateMenuItem`.
- **`NSDocument.read(from:ofType:)`** is `nonisolated` in the SDK. Override with `nonisolated`, then use `MainActor.assumeIsolated { ... }` to set MainActor stored properties.
- **Decodable conformance on value types** picks up MainActor isolation from the project default unless the type is explicitly `nonisolated struct`. Mark all `Manifest`-shape types `nonisolated` so they decode from background tasks.

### Light/dark mode

If you write anything that calls `someColor.cgColor` and caches it on a CALayer, you MUST refresh on `viewDidChangeEffectiveAppearance`. Pattern:

```swift
override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    effectiveAppearance.performAsCurrentDrawingAppearance {
        // re-resolve and re-assign CGColors here
    }
}
```

For the renderer, this is handled by `CALayerGraphRenderer.refreshColors()`. For the inspector it's a `refresh()` call (the row builders re-resolve NSColors).

### Toolbar gotchas

- `NSToolbarItem` with `image` + `action` (default style) does NOT expose its internal button view via `.view`. If you need to anchor a popover to a toolbar button, you must build the toolbar item with a CUSTOM NSButton view and keep a reference to it. See `filterToolbarButton` in `ProjectWindowController`.
- `autosavesConfiguration = true` will override your programmatic `displayMode` from previously-saved user defaults. Either disable autosave or bump the toolbar identifier when changing the default display mode. Current: identifier `ProjectToolbar.v2`, autosave off, `iconOnly`.

### NSOutlineView feedback-loop gotcha

`reloadData()` on an outline view with `allowsEmptySelection = false` auto-selects row 0, which fires `outlineViewSelectionDidChange`. If your delegate forwards changes to a model that then triggers another `reloadData()`, you've made a loop. Fix: suppress notifications around all programmatic mutations via a flag. See `SidebarController.suppressSelectionChange`.

### Performance budget

- Layout for 1,200 nodes: ~200–400ms (Sugiyama with 4 barycenter sweeps + folder cohesion).
- Renderer install for 1,200 nodes: ~50–100ms.
- Hover update with incremental highlight: under 1ms (only touches ~10 layers).
- Manifest parse (~10MB JSON): 0.5–1.5s in Release.

If anything regresses past these numbers, the cause is usually one of: (a) re-resolving colors on every frame, (b) walking all layers on a mouse event, (c) a `CATransaction` that didn't disable implicit animations.

## Running

Open `Lineage.xcodeproj` in Xcode 16+. Cmd+R. Requires macOS 26+.

For a built-in demo: File → Open Demo Project (the bundled `fixtures/demo-coffee-shop/` fixture). To exercise with real data: Cmd+O → any local `target/` from a real dbt project — keep your own copy outside the repo since the dev fixture isn't checked in.
