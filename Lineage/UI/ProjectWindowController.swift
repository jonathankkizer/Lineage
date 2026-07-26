import AppKit

@MainActor
final class ProjectWindowController: NSWindowController, NSToolbarDelegate, NSWindowDelegate, NSMenuItemValidation, NSSearchFieldDelegate {

    private weak var projectDocument: DbtProjectDocument?
    private let selection = SelectionModel()
    private let focusHistory = FocusHistory()

    private let graphView: GraphView
    private let inspectorView: InspectorView
    private let sidebarController = SidebarController()
    private let splitView = NSSplitView()
    private var sidebarSplitItem: NSSplitViewItem!
    private var graphSplitItem: NSSplitViewItem!
    private var inspectorSplitItem: NSSplitViewItem!

    private let loadingOverlay = LoadingOverlayView()
    private var inspectorVisible = ViewPreferences.inspectorVisible
    private var loadingShowTask: Task<Void, Never>?
    private static let loadingDeferDelay: Duration = .milliseconds(400)

    /// View state decoded by `restoreState(with:)`, held until the document
    /// finishes its async load. Restoration and loading race; whichever lands
    /// second calls `applyRestoredStateIfReady()`.
    private var pendingRestoredState: RestoredState?

    private var searchQuery: String = ""
    private weak var searchToolbarItem: NSSearchToolbarItem?
    private weak var filterToolbarButton: NSButton?
    private var filterPopover: NSPopover?

    private var coloringMode: NodeColoring = ViewPreferences.coloringMode
    private weak var coloringSegmented: NSSegmentedControl?

    private weak var layoutSegmented: NSSegmentedControl?

    private var criticalPathActive: Bool = false
    private weak var criticalPathButton: NSButton?

    nonisolated private static let zoomToFitID = NSToolbarItem.Identifier("zoom-to-fit")
    nonisolated private static let searchID = NSToolbarItem.Identifier("search")
    nonisolated private static let filterID = NSToolbarItem.Identifier("filter")
    nonisolated private static let coloringID = NSToolbarItem.Identifier("coloring")
    nonisolated private static let layoutID = NSToolbarItem.Identifier("layout")
    nonisolated private static let criticalPathID = NSToolbarItem.Identifier("critical-path")
    nonisolated private static let toggleInspectorID = NSToolbarItem.Identifier("toggle-inspector")

    init(document: DbtProjectDocument) {
        self.projectDocument = document
        self.graphView = GraphView(selection: selection)
        self.inspectorView = InspectorView(selection: selection, documentProvider: { [weak document] in document })

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 700, height: 500)
        window.titlebarAppearsTransparent = false
        window.tabbingMode = .preferred
        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unified
        }
        window.title = document.displayName ?? "dbt Project"
        window.isRestorable = true
        window.identifier = NSUserInterfaceItemIdentifier("ProjectWindow")
        // Per-document autosave key. A single shared name made every project
        // window fight over one saved frame and open exactly stacked.
        // `setFrameAutosaveName` only names the key — restoring is a separate
        // `setFrameUsingName` call, and it has to happen first.
        let autosaveName = Self.frameAutosaveName(for: document)
        let didRestoreFrame = window.setFrameUsingName(autosaveName)
        window.setFrameAutosaveName(autosaveName)

        super.init(window: nil)
        self.window = window
        window.delegate = self

        // First time this project has been opened: cascade rather than landing
        // on top of whatever is already on screen.
        if !didRestoreFrame {
            Self.cascadePoint = window.cascadeTopLeft(from: Self.cascadePoint)
        }

        configureSplitView()
        configureToolbar()
        configureLoadingOverlay()

        graphView.onLineageFilterRequest = { [weak self] query in
            self?.applyContextLineageQuery(query)
        }
        graphView.lineageAvailabilityProvider = { [weak self] id in
            self?.lineageAvailability(for: id) ?? .both
        }
        graphView.fileURLProvider = { [weak self] id in
            self?.fileURL(forNode: id)
        }
    }

    /// Resolves a node to its source file on disk (project root + the node's
    /// `original_file_path`). Mirrors the inspector's reveal-in-Finder logic.
    private func fileURL(forNode id: NodeID) -> URL? {
        guard let document = projectDocument,
              let root = document.projectRootURL,
              let path = document.graph?.nodes[id]?.originalFilePath,
              !path.isEmpty else { return nil }
        return root.appendingPathComponent(path)
    }

    private func lineageAvailability(for id: NodeID) -> GraphView.LineageAvailability {
        guard let graph = projectDocument?.graph else { return .both }
        return GraphView.LineageAvailability(
            hasUpstream: !graph.parents(of: id).isEmpty,
            hasDownstream: !graph.children(of: id).isEmpty
        )
    }

    required init?(coder: NSCoder) { nil }

    private static var cascadePoint = NSPoint.zero

    private static func frameAutosaveName(for document: DbtProjectDocument) -> String {
        guard let url = document.fileURL ?? document.projectRootURL else { return "ProjectWindow" }
        return "ProjectWindow.\(StableKey.forURL(url))"
    }

    private func configureSplitView() {
        let splitController = NSSplitViewController()
        splitController.view.translatesAutoresizingMaskIntoConstraints = false
        // Shared across windows on purpose: sidebar and inspector widths are an
        // app-wide preference in Finder/Xcode/Mail, not a per-window one.
        splitController.splitView.autosaveName = "ProjectSplitView"

        sidebarSplitItem = NSSplitViewItem(sidebarWithViewController: sidebarController)
        sidebarSplitItem.canCollapse = true
        sidebarSplitItem.minimumThickness = 180
        sidebarSplitItem.maximumThickness = 320
        sidebarSplitItem.preferredThicknessFraction = 0.16
        sidebarSplitItem.holdingPriority = NSLayoutConstraint.Priority(250)
        splitController.addSplitViewItem(sidebarSplitItem)

        graphSplitItem = NSSplitViewItem(viewController: hostController(for: graphView))
        graphSplitItem.minimumThickness = 360
        graphSplitItem.holdingPriority = .defaultLow
        splitController.addSplitViewItem(graphSplitItem)

        let inspectorHost = hostController(for: inspectorView)
        inspectorSplitItem = NSSplitViewItem(inspectorWithViewController: inspectorHost)
        inspectorSplitItem.canCollapse = true
        inspectorSplitItem.canCollapseFromWindowResize = true
        inspectorSplitItem.minimumThickness = 220
        inspectorSplitItem.maximumThickness = 520
        inspectorSplitItem.preferredThicknessFraction = 0.25
        inspectorSplitItem.holdingPriority = NSLayoutConstraint.Priority(260)
        splitController.addSplitViewItem(inspectorSplitItem)
        inspectorSplitItem.isCollapsed = !inspectorVisible

        contentViewController = splitController

        sidebarController.onScopeChange = { [weak self] scope in
            self?.sidebarScopeChanged(scope)
        }
    }

    private func sidebarScopeChanged(_ scope: FilterScope) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        guard filter.scope != scope else { return }
        filter.scope = scope
        document.updateFilter(filter)
    }

    private func hostController(for view: NSView) -> NSViewController {
        let controller = NSViewController()
        controller.view = view
        return controller
    }

    private func configureToolbar() {
        // Identifier bumped alongside re-enabling autosave: a stale saved
        // configuration under the old identifier would otherwise override the
        // programmatic display mode below. Set the default first, then let
        // autosave take over so the user's own customisation wins from here on.
        let toolbar = NSToolbar(identifier: "ProjectToolbar.v3")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.displayMode = .iconOnly
        toolbar.autosavesConfiguration = true
        window?.toolbar = toolbar
    }

    @objc func customizeToolbar(_ sender: Any?) {
        window?.toolbar?.runCustomizationPalette(sender)
    }

    private func configureLoadingOverlay() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.isHidden = true
        guard let contentView = window?.contentView else { return }
        contentView.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Document callbacks

    func showLoading() {
        scheduleLoadingOverlay(message: "Parsing manifest\u{2026}", delay: nil)
    }

    private func scheduleLoadingOverlay(message: String, delay: Duration?) {
        loadingShowTask?.cancel()
        guard let delay else {
            loadingOverlay.isHidden = false
            loadingOverlay.start(message: message)
            return
        }
        loadingShowTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            self.loadingOverlay.isHidden = false
            self.loadingOverlay.start(message: message)
        }
    }

    private func hideLoadingOverlay() {
        loadingShowTask?.cancel()
        loadingShowTask = nil
        loadingOverlay.stop()
        loadingOverlay.isHidden = true
    }

    func documentDidFinishLoading() {
        hideLoadingOverlay()
        guard let document = projectDocument,
              let graph = document.graph,
              let layout = document.graphLayout else { return }

        window?.title = document.displayName ?? "dbt Project"
        // Proxy icon: the opened document (a `.lineagegh` connection) when there
        // is one, otherwise the project root folder. Gives the title bar a
        // draggable, Cmd-clickable proxy like any document window.
        window?.representedURL = document.fileURL ?? document.projectRootURL
        if let subtitle = document.projectRootURL?.path {
            window?.subtitle = subtitle
        }

        if let fullGraph = document.fullGraph {
            sidebarController.populate(
                totalNodes: fullGraph.nodes.count,
                folderTree: fullGraph.folderTree(),
                tags: fullGraph.allTags(),
                scope: document.nodeFilter.scope
            )
        }

        graphView.install(graph: graph, layout: layout)
        graphView.setBuildTimings(document.buildTimings)
        graphView.setColoring(coloringMode)
        layoutSegmented?.selectedSegment = document.layoutAlgorithm.segmentIndex
        graphView.resetBulkEdgesToAuto()
        inspectorView.documentDidLoad(graph: graph)

        // If we reloaded into a project that no longer has timings, turn CP off
        // so the toolbar button doesn't sit in an .on state with no effect.
        if document.criticalPath == nil, criticalPathActive {
            criticalPathActive = false
        }
        criticalPathButton?.state = criticalPathActive ? .on : .off

        if pendingRestoredState != nil {
            applyRestoredStateIfReady()
        } else {
            applyCurrentFocus(animated: false, reframe: false)
        }
    }

    func documentDidFailLoading(_ error: Error) {
        loadingOverlay.stop()
        loadingOverlay.isHidden = true

        let alert = NSAlert(error: error)
        alert.messageText = "Couldn't open dbt project"
        alert.informativeText = error.localizedDescription
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    // MARK: - Toolbar

    nonisolated func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, Self.zoomToFitID, Self.layoutID, Self.filterID, Self.coloringID, Self.criticalPathID, .flexibleSpace, Self.searchID, .flexibleSpace, Self.toggleInspectorID]
    }

    nonisolated func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, Self.zoomToFitID, Self.layoutID, Self.filterID, Self.coloringID, Self.criticalPathID, Self.searchID, Self.toggleInspectorID, .flexibleSpace, .space]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case Self.zoomToFitID:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Zoom to Fit"
            item.paletteLabel = "Zoom to Fit"
            item.toolTip = "Fit the entire graph in the window"
            item.image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Zoom to Fit")
            item.target = self
            item.action = #selector(zoomToFitAction(_:))
            return item

        case Self.searchID:
            let item = NSSearchToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Filter"
            item.paletteLabel = "Filter"
            item.toolTip = "Filter nodes by name. Use +name / name+ / +name+ / N+name / name+N for lineage selection. (⌘F)"
            item.searchField.placeholderString = "Filter"
            item.searchField.delegate = self
            item.preferredWidthForSearchField = 240
            searchToolbarItem = item
            return item

        case Self.filterID:
            let button = NSButton()
            button.image = NSImage(systemSymbolName: "line.3.horizontal.decrease.circle", accessibilityDescription: "Show types")
            button.bezelStyle = .texturedRounded
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.target = self
            button.action = #selector(showFilterPopover(_:))
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 40),
                button.heightAnchor.constraint(equalToConstant: 26),
            ])

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = button
            item.label = "Show"
            item.paletteLabel = "Show"
            item.toolTip = "Show or hide node types"
            filterToolbarButton = button
            return item

        case Self.toggleInspectorID:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Inspector"
            item.paletteLabel = "Inspector"
            item.toolTip = "Show/hide the inspector pane"
            item.image = NSImage(systemSymbolName: "sidebar.right", accessibilityDescription: "Inspector")
            item.target = self
            item.action = #selector(toggleInspector(_:))
            return item

        case Self.criticalPathID:
            let button = NSButton()
            button.image = NSImage(systemSymbolName: "point.bottomleft.forward.to.point.topright.scurvepath", accessibilityDescription: "Critical path")
            button.alternateImage = NSImage(systemSymbolName: "point.bottomleft.forward.to.point.topright.scurvepath.fill", accessibilityDescription: "Critical path")
            button.setButtonType(.pushOnPushOff)
            button.bezelStyle = .texturedRounded
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.state = criticalPathActive ? .on : .off
            button.target = self
            button.action = #selector(toggleCriticalPath(_:))
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 40),
                button.heightAnchor.constraint(equalToConstant: 26),
            ])
            criticalPathButton = button

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = button
            item.label = "Critical Path"
            item.paletteLabel = "Critical Path"
            item.toolTip = "Highlight the build's critical path (longest weighted chain). ⇧⌘P"
            return item

        case Self.coloringID:
            let segmented = NSSegmentedControl(labels: ["Kind", "Build Time"], trackingMode: .selectOne, target: self, action: #selector(coloringSegmentedChanged(_:)))
            segmented.segmentStyle = .texturedRounded
            segmented.selectedSegment = coloringMode.rawValue
            segmented.setToolTip("Color nodes by resource kind", forSegment: 0)
            segmented.setToolTip("Color nodes by build time (green → red, by percentile of last run)", forSegment: 1)
            segmented.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                segmented.heightAnchor.constraint(equalToConstant: 26),
            ])
            coloringSegmented = segmented

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = segmented
            item.label = "Color"
            item.paletteLabel = "Color By"
            item.toolTip = "Color nodes by kind or by build time"
            return item

        case Self.layoutID:
            let labels = GraphLayoutAlgorithm.allCases
                .sorted { $0.segmentIndex < $1.segmentIndex }
                .map(\.displayName)
            let segmented = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: self, action: #selector(layoutSegmentedChanged(_:)))
            segmented.segmentStyle = .texturedRounded
            segmented.selectedSegment = (projectDocument?.layoutAlgorithm ?? .flow).segmentIndex
            for algorithm in GraphLayoutAlgorithm.allCases {
                segmented.setToolTip(algorithm.toolTip, forSegment: algorithm.segmentIndex)
            }
            segmented.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                segmented.heightAnchor.constraint(equalToConstant: 26),
            ])
            layoutSegmented = segmented

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = segmented
            item.label = "Layout"
            item.paletteLabel = "Layout"
            item.toolTip = "Switch graph layout"
            return item

        default:
            return nil
        }
    }

    @objc private func zoomToFitAction(_ sender: Any?) {
        graphView.zoomToFit()
    }

    @objc func toggleInspector(_ sender: Any?) {
        inspectorVisible.toggle()
        ViewPreferences.inspectorVisible = inspectorVisible
        inspectorSplitItem.animator().isCollapsed = !inspectorVisible
        invalidateRestorableState()
    }

    @objc func toggleShowAllEdges(_ sender: Any?) {
        graphView.setBulkEdgesEnabled(!graphView.areBulkEdgesEnabled())
    }

    @objc private func coloringSegmentedChanged(_ sender: NSSegmentedControl) {
        let mode = NodeColoring(rawValue: sender.selectedSegment) ?? .kind
        setColoringMode(mode)
    }

    private func setColoringMode(_ mode: NodeColoring) {
        guard mode != coloringMode else { return }
        coloringMode = mode
        ViewPreferences.coloringMode = mode
        coloringSegmented?.selectedSegment = mode.rawValue
        graphView.setColoring(mode)
        invalidateRestorableState()
    }

    // MARK: - Layout

    @objc private func layoutSegmentedChanged(_ sender: NSSegmentedControl) {
        applyLayoutAlgorithm(GraphLayoutAlgorithm(segmentIndex: sender.selectedSegment))
    }

    @objc func selectLayout(_ sender: Any?) {
        guard let item = sender as? NSMenuItem else { return }
        applyLayoutAlgorithm(GraphLayoutAlgorithm(segmentIndex: item.tag))
    }

    private func applyLayoutAlgorithm(_ algorithm: GraphLayoutAlgorithm) {
        layoutSegmented?.selectedSegment = algorithm.segmentIndex
        projectDocument?.setLayoutAlgorithm(algorithm)
    }

    func didChangeLayout(_ layout: GraphLayout) {
        layoutSegmented?.selectedSegment = (projectDocument?.layoutAlgorithm ?? .flow).segmentIndex
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let duration: CFTimeInterval = reduceMotion ? 0 : 0.45
        // The renderer reuses the existing node layers, so focus dimming and
        // selection survive the transition — no need to re-apply focus (which
        // would snap the edge morph). Just morph + reframe.
        graphView.transitionLayout(to: layout, animationDuration: duration)
    }

    // MARK: - Reload

    @objc func reloadProject(_ sender: Any?) {
        guard let document = projectDocument else { return }
        focusHistory.clear()
        searchQuery = ""
        searchToolbarItem?.searchField.stringValue = ""
        filterPopover?.performClose(nil)
        document.reload()
    }

    // MARK: - Filter actions

    @objc func toggleShowTests(_ sender: Any?) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        filter.showTests.toggle()
        document.updateFilter(filter)
    }

    @objc func toggleShowSources(_ sender: Any?) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        filter.showSources.toggle()
        document.updateFilter(filter)
    }

    @objc func toggleShowOrphanSources(_ sender: Any?) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        filter.showOrphanSources.toggle()
        document.updateFilter(filter)
    }

    @objc func toggleShowSeeds(_ sender: Any?) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        filter.showSeeds.toggle()
        document.updateFilter(filter)
    }

    @objc func toggleShowExposures(_ sender: Any?) {
        guard let document = projectDocument else { return }
        var filter = document.nodeFilter
        filter.showExposures.toggle()
        document.updateFilter(filter)
    }

    @objc func resetFilter(_ sender: Any?) {
        guard let document = projectDocument else { return }
        document.updateFilter(.default)
    }

    func willRefilter(filter: NodeFilter) {
        scheduleLoadingOverlay(message: "Updating filter\u{2026}", delay: Self.loadingDeferDelay)
    }

    func didRefilter() {
        hideLoadingOverlay()
        focusHistory.clear()
        guard let document = projectDocument,
              let graph = document.graph,
              let layout = document.graphLayout else { return }

        if let primary = selection.primary, graph.nodes[primary] == nil {
            selection.clear()
        }
        graphView.install(graph: graph, layout: layout)
        inspectorView.notifyGraphChanged(graph: graph)
        applyCurrentFocus(animated: false)
    }

    // MARK: - Focus actions

    @objc func focusOnSelection(_ sender: Any?) {
        guard let primary = selection.primary else { return }
        let entry = FocusEntry(
            anchor: primary,
            upstreamHops: FocusHistory.defaultUpstreamHops,
            downstreamHops: FocusHistory.defaultDownstreamHops
        )
        focusHistory.push(entry)
        applyCurrentFocus(animated: true)
    }

    @objc func clearFocus(_ sender: Any?) {
        guard focusHistory.current != nil else { return }
        focusHistory.clear()
        applyCurrentFocus(animated: true)
    }

    @objc func focusBack(_ sender: Any?) {
        guard focusHistory.canGoBack else { return }
        _ = focusHistory.goBack()
        applyCurrentFocus(animated: true)
    }

    @objc func focusForward(_ sender: Any?) {
        guard focusHistory.canGoForward else { return }
        _ = focusHistory.goForward()
        applyCurrentFocus(animated: true)
    }

    @objc func expandFocus(_ sender: Any?) {
        guard let cur = focusHistory.current else { return }
        focusHistory.adjustHops(upstream: cur.upstreamHops + 1, downstream: cur.downstreamHops + 1)
        applyCurrentFocus(animated: true)
    }

    @objc func contractFocus(_ sender: Any?) {
        guard let cur = focusHistory.current else { return }
        focusHistory.adjustHops(upstream: cur.upstreamHops - 1, downstream: cur.downstreamHops - 1)
        applyCurrentFocus(animated: true)
    }

    private struct Visibility {
        var scope: SelectionScope?
        var focusEntry: FocusEntry?
        var focusNodeCount: Int
        var searchMatchCount: Int?
        var criticalPathActive: Bool
        var criticalPath: CriticalPath?
    }

    private func computeVisibility() -> Visibility {
        var v = Visibility(
            scope: nil,
            focusEntry: focusHistory.current,
            focusNodeCount: 0,
            searchMatchCount: nil,
            criticalPathActive: criticalPathActive,
            criticalPath: projectDocument?.criticalPath
        )
        guard let graph = projectDocument?.graph else { return v }

        var focusScope: SelectionScope?
        if let entry = focusHistory.current {
            focusScope = Self.lineageScope(
                graph: graph,
                anchor: entry.anchor,
                upstreamHops: entry.upstreamHops,
                downstreamHops: entry.downstreamHops
            )
            v.focusNodeCount = focusScope?.nodes.count ?? 0
        }

        var searchScope: SelectionScope?
        if !searchQuery.isEmpty, let selector = NodeSelector.parse(searchQuery) {
            let s = selector.apply(to: graph)
            searchScope = s
            v.searchMatchCount = s.nodes.count
        }

        // Critical path is a flat node-set scope when active. It composes by
        // intersection alongside focus and search, same as the others.
        var cpScope: SelectionScope?
        if criticalPathActive, let cp = v.criticalPath {
            // Clip to the currently-filtered graph so the scope is meaningful;
            // a CP node hidden by the active filter shouldn't reappear.
            let visibleCPNodes = cp.nodeSet.intersection(graph.nodes.keys)
            cpScope = SelectionScope.nodesOnly(visibleCPNodes)
        }

        v.scope = Self.intersectScopes([focusScope, searchScope, cpScope])
        return v
    }

    /// Intersects any non-nil scopes by node set. Directional (upstream/downstream)
    /// info from focus is preserved only if focus is the *only* active scope —
    /// the moment we intersect with anything else, edge directionality stops
    /// composing cleanly so we degrade to a flat node set.
    private static func intersectScopes(_ scopes: [SelectionScope?]) -> SelectionScope? {
        let active = scopes.compactMap { $0 }
        if active.isEmpty { return nil }
        if active.count == 1 { return active[0] }
        var nodes = active[0].nodes
        for s in active.dropFirst() {
            nodes.formIntersection(s.nodes)
        }
        return SelectionScope(nodes: nodes, upstream: nil, downstream: nil)
    }

    private static func lineageScope(graph: Graph, anchor: NodeID, upstreamHops: Int, downstreamHops: Int) -> SelectionScope {
        var upstream: Set<NodeID> = [anchor]
        var downstream: Set<NodeID> = [anchor]
        if upstreamHops > 0 {
            let sub = SubgraphSelector.subgraph(graph: graph, anchor: anchor, upstreamHops: upstreamHops, downstreamHops: 0)
            upstream.formUnion(sub.nodes)
        }
        if downstreamHops > 0 {
            let sub = SubgraphSelector.subgraph(graph: graph, anchor: anchor, upstreamHops: 0, downstreamHops: downstreamHops)
            downstream.formUnion(sub.nodes)
        }
        return SelectionScope(
            nodes: upstream.union(downstream),
            upstream: upstreamHops > 0 ? upstream : nil,
            downstream: downstreamHops > 0 ? downstream : nil
        )
    }

    private func applyCurrentFocus(animated: Bool, reframe: Bool = true) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let duration: CFTimeInterval = (animated && !reduceMotion) ? 0.30 : 0
        let v = computeVisibility()
        graphView.applyFocus(scope: v.scope, animationDuration: duration, reframe: reframe)
        graphView.setVisibleNodes(v.scope?.nodes)
        updateSubtitle(v)
        invalidateRestorableState()
    }

    private func updateSubtitle(_ v: Visibility) {
        var parts: [String] = []
        if let entry = v.focusEntry,
           let name = projectDocument?.graph?.nodes[entry.anchor]?.name ?? projectDocument?.graph?.nodes[entry.anchor].map({ _ in entry.anchor.displayName }) {
            parts.append("Focus: \(name) — ↑\(entry.upstreamHops) ↓\(entry.downstreamHops) — \(v.focusNodeCount) nodes")
        }
        if let n = v.searchMatchCount {
            parts.append("Search: \(n) match\(n == 1 ? "" : "es")")
        }
        if v.criticalPathActive, let cp = v.criticalPath {
            parts.append("Critical path: \(Self.formatDuration(cp.totalSeconds)) · \(cp.nodes.count) node\(cp.nodes.count == 1 ? "" : "s")")
        }
        if parts.isEmpty {
            if let root = projectDocument?.projectRootURL?.lastPathComponent {
                window?.subtitle = root
            } else {
                window?.subtitle = ""
            }
        } else {
            window?.subtitle = parts.joined(separator: "  ·  ")
        }
    }

    /// Mirror of InspectorView.formatDuration — kept local so the subtitle
    /// composer doesn't reach across modules. Update both together.
    static func formatDuration(_ t: TimeInterval) -> String {
        if t < 1 {
            return "\(Int((t * 1000).rounded())) ms"
        }
        if t < 10 {
            return String(format: "%.2f s", t)
        }
        if t < 60 {
            return String(format: "%.1f s", t)
        }
        let total = Int(t.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m \(s)s"
    }

    // MARK: - Critical path actions

    @objc func toggleCriticalPath(_ sender: Any?) {
        guard projectDocument?.criticalPath != nil else {
            criticalPathActive = false
            criticalPathButton?.state = .off
            return
        }
        criticalPathActive.toggle()
        criticalPathButton?.state = criticalPathActive ? .on : .off
        applyCurrentFocus(animated: true, reframe: false)
    }

    // MARK: - Search

    @objc func focusFilterField(_ sender: Any?) {
        guard let field = searchToolbarItem?.searchField else { return }
        window?.makeFirstResponder(field)
    }

    @objc func findNext(_ sender: Any?) { stepSearchMatch(by: 1) }
    @objc func findPrevious(_ sender: Any?) { stepSearchMatch(by: -1) }

    /// Search matches in reading order across the canvas — left to right, then
    /// top to bottom — so stepping through them tracks the layout rather than
    /// jumping around by unique_id.
    private func searchMatches() -> [NodeID] {
        guard !searchQuery.isEmpty,
              let graph = projectDocument?.graph,
              let layout = projectDocument?.graphLayout,
              let selector = NodeSelector.parse(searchQuery) else { return [] }
        return selector.apply(to: graph).nodes.sorted { a, b in
            let ra = layout.rect(for: a) ?? .zero
            let rb = layout.rect(for: b) ?? .zero
            if ra.minX != rb.minX { return ra.minX < rb.minX }
            if ra.minY != rb.minY { return ra.minY < rb.minY }
            return a.rawValue < b.rawValue
        }
    }

    private func stepSearchMatch(by delta: Int) {
        let matches = searchMatches()
        guard !matches.isEmpty else {
            if NavigationSoundPreference.isEnabled { NSSound.beep() }
            return
        }
        let next: NodeID
        if let index = selection.primary.flatMap({ matches.firstIndex(of: $0) }) {
            next = matches[(index + delta + matches.count) % matches.count]
        } else {
            next = delta > 0 ? matches[0] : matches[matches.count - 1]
        }
        selection.replace(with: next)
        graphView.reveal(nodeID: next)
    }

    // MARK: - Filter popover

    @objc func showFilterPopover(_ sender: Any?) {
        if let existing = filterPopover, existing.isShown {
            existing.performClose(nil)
            return
        }
        guard let button = filterToolbarButton ?? (sender as? NSButton) else { return }
        guard let document = projectDocument, document.fullGraph != nil else { return }

        let controller = FilterPopoverController(
            filter: document.nodeFilter,
            onChange: { [weak self] newFilter in
                self?.projectDocument?.updateFilter(newFilter)
            },
            onReset: { [weak self] in
                self?.projectDocument?.updateFilter(.default)
            }
        )

        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.contentViewController = controller
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        filterPopover = popover
    }


    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSSearchField else { return }
        searchQuery = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        applyCurrentFocus(animated: false, reframe: false)
    }

    private func applyContextLineageQuery(_ query: String) {
        searchQuery = query
        if let field = searchToolbarItem?.searchField {
            field.stringValue = query
        }
        applyCurrentFocus(animated: true, reframe: true)
    }

    // MARK: - State restoration

    private struct RestoredState {
        var viewport: Viewport?
        var searchQuery: String = ""
        var selection: [NodeID] = []
        var primary: NodeID?
        var focus: FocusEntry?
        var criticalPathActive = false
    }

    private enum RestoreKey {
        static let viewportX = "viewport.x"
        static let viewportY = "viewport.y"
        static let viewportScale = "viewport.scale"
        static let hasViewport = "viewport.present"
        static let search = "search.query"
        static let selection = "selection.ids"
        static let primary = "selection.primary"
        static let focusAnchor = "focus.anchor"
        static let focusUp = "focus.upstreamHops"
        static let focusDown = "focus.downstreamHops"
        static let criticalPath = "criticalPath.active"
        static let coloring = "coloring.mode"
        static let inspector = "inspector.visible"
        static let filter = "filter.payload"
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        guard ViewPreferences.restoresWindowState else { return }

        let v = graphView.currentViewport
        coder.encode(true, forKey: RestoreKey.hasViewport)
        coder.encode(Double(v.translation.x), forKey: RestoreKey.viewportX)
        coder.encode(Double(v.translation.y), forKey: RestoreKey.viewportY)
        coder.encode(Double(v.scale), forKey: RestoreKey.viewportScale)

        coder.encode(searchQuery, forKey: RestoreKey.search)
        // Newline-joined rather than an array: unique_ids never contain newlines,
        // and a plain String sidesteps NSSecureCoding's array-of-class dance.
        coder.encode(selection.selected.map(\.rawValue).sorted().joined(separator: "\n"), forKey: RestoreKey.selection)
        coder.encode(selection.primary?.rawValue, forKey: RestoreKey.primary)

        if let entry = focusHistory.current {
            coder.encode(entry.anchor.rawValue, forKey: RestoreKey.focusAnchor)
            coder.encode(entry.upstreamHops, forKey: RestoreKey.focusUp)
            coder.encode(entry.downstreamHops, forKey: RestoreKey.focusDown)
        }

        coder.encode(criticalPathActive, forKey: RestoreKey.criticalPath)
        coder.encode(coloringMode.rawValue, forKey: RestoreKey.coloring)
        coder.encode(inspectorVisible, forKey: RestoreKey.inspector)

        if let filter = projectDocument?.nodeFilter,
           let data = try? JSONEncoder().encode(filter) {
            coder.encode(data, forKey: RestoreKey.filter)
        }
    }

    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        guard ViewPreferences.restoresWindowState else { return }

        var state = RestoredState()
        if coder.decodeBool(forKey: RestoreKey.hasViewport) {
            state.viewport = Viewport(
                translation: CGPoint(
                    x: coder.decodeDouble(forKey: RestoreKey.viewportX),
                    y: coder.decodeDouble(forKey: RestoreKey.viewportY)
                ),
                scale: coder.decodeDouble(forKey: RestoreKey.viewportScale)
            )
        }
        state.searchQuery = coder.decodeObject(of: NSString.self, forKey: RestoreKey.search) as? String ?? ""
        let joinedIDs = coder.decodeObject(of: NSString.self, forKey: RestoreKey.selection) as? String ?? ""
        state.selection = joinedIDs
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { NodeID(rawValue: String($0)) }
        if let rawPrimary = coder.decodeObject(of: NSString.self, forKey: RestoreKey.primary) as? String {
            state.primary = NodeID(rawValue: rawPrimary)
        }
        if let rawAnchor = coder.decodeObject(of: NSString.self, forKey: RestoreKey.focusAnchor) as? String {
            state.focus = FocusEntry(
                anchor: NodeID(rawValue: rawAnchor),
                upstreamHops: coder.decodeInteger(forKey: RestoreKey.focusUp),
                downstreamHops: coder.decodeInteger(forKey: RestoreKey.focusDown)
            )
        }
        state.criticalPathActive = coder.decodeBool(forKey: RestoreKey.criticalPath)

        // Chrome can be applied immediately — it doesn't depend on the graph.
        if coder.containsValue(forKey: RestoreKey.coloring) {
            setColoringMode(NodeColoring(rawValue: coder.decodeInteger(forKey: RestoreKey.coloring)) ?? .kind)
        }
        if coder.containsValue(forKey: RestoreKey.inspector) {
            let visible = coder.decodeBool(forKey: RestoreKey.inspector)
            if visible != inspectorVisible {
                inspectorVisible = visible
                inspectorSplitItem.isCollapsed = !visible
            }
        }
        if let data = coder.decodeObject(of: NSData.self, forKey: RestoreKey.filter) as? Data,
           let filter = try? JSONDecoder().decode(NodeFilter.self, from: data) {
            projectDocument?.restoreFilter(filter)
        }

        pendingRestoredState = state
        applyRestoredStateIfReady()
    }

    /// Restoration and the document's async load race each other. Both call
    /// this; it no-ops until the graph exists, then consumes the state once.
    private func applyRestoredStateIfReady() {
        guard let state = pendingRestoredState else { return }
        guard let graph = projectDocument?.graph else { return }
        pendingRestoredState = nil

        criticalPathActive = state.criticalPathActive && projectDocument?.criticalPath != nil
        criticalPathButton?.state = criticalPathActive ? .on : .off

        searchQuery = state.searchQuery
        searchToolbarItem?.searchField.stringValue = state.searchQuery

        // Nodes can disappear between launches (the manifest was rebuilt, or a
        // filter now hides them) — drop anything that no longer resolves.
        let surviving = state.selection.filter { graph.nodes[$0] != nil }
        if !surviving.isEmpty {
            selection.replace(with: Set(surviving), primary: state.primary.flatMap { graph.nodes[$0] != nil ? $0 : nil })
        }
        if let focus = state.focus, graph.nodes[focus.anchor] != nil {
            focusHistory.restore(focus)
        }

        applyCurrentFocus(animated: false, reframe: state.viewport == nil)
        if let viewport = state.viewport, viewport.scale > 0 {
            graphView.restoreViewport(viewport)
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return true }
        let filter = projectDocument?.nodeFilter ?? .default
        switch action {
        case #selector(toggleInspector(_:)):
            menuItem.title = inspectorVisible ? "Hide Inspector" : "Show Inspector"
            return true
        case #selector(toggleShowAllEdges(_:)):
            let enabled = graphView.areBulkEdgesEnabled()
            menuItem.title = enabled ? "Hide Edges" : "Show Edges"
            return projectDocument?.graph != nil
        case #selector(focusOnSelection(_:)):
            return selection.primary != nil
        case #selector(clearFocus(_:)):
            return focusHistory.current != nil
        case #selector(focusBack(_:)):
            return focusHistory.canGoBack
        case #selector(focusForward(_:)):
            return focusHistory.canGoForward
        case #selector(expandFocus(_:)), #selector(contractFocus(_:)):
            return focusHistory.current != nil
        case #selector(toggleShowTests(_:)):
            menuItem.state = filter.showTests ? .on : .off
            return projectDocument?.fullGraph != nil
        case #selector(toggleShowSources(_:)):
            menuItem.state = filter.showSources ? .on : .off
            return projectDocument?.fullGraph != nil
        case #selector(toggleShowOrphanSources(_:)):
            menuItem.state = filter.showOrphanSources ? .on : .off
            return filter.showSources && projectDocument?.fullGraph != nil
        case #selector(toggleShowSeeds(_:)):
            menuItem.state = filter.showSeeds ? .on : .off
            return projectDocument?.fullGraph != nil
        case #selector(toggleShowExposures(_:)):
            menuItem.state = filter.showExposures ? .on : .off
            return projectDocument?.fullGraph != nil
        case #selector(resetFilter(_:)):
            return !(projectDocument?.nodeFilter ?? .default).isDefault
        case #selector(focusFilterField(_:)):
            return searchToolbarItem?.searchField != nil
        case #selector(findNext(_:)), #selector(findPrevious(_:)):
            return !searchQuery.isEmpty && projectDocument?.graph != nil
        case #selector(customizeToolbar(_:)):
            return window?.toolbar != nil
        case #selector(reloadProject(_:)):
            return projectDocument?.manifestURL != nil
        case #selector(toggleCriticalPath(_:)):
            let available = projectDocument?.criticalPath != nil
            menuItem.state = (available && criticalPathActive) ? .on : .off
            return available
        case #selector(selectLayout(_:)):
            let current = projectDocument?.layoutAlgorithm ?? .flow
            menuItem.state = (menuItem.tag == current.segmentIndex) ? .on : .off
            return projectDocument?.graph != nil
        default:
            return true
        }
    }
}

@MainActor
private final class LoadingOverlayView: NSView {

    private let visualEffect = NSVisualEffectView()
    private let spinner = NSProgressIndicator()
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .withinWindow
        visualEffect.state = .active
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffect)

        spinner.style = .spinning
        spinner.isIndeterminate = true
        spinner.controlSize = .regular
        spinner.translatesAutoresizingMaskIntoConstraints = false

        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [spinner, label])
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func start(message: String) {
        label.stringValue = message
        spinner.startAnimation(nil)
    }

    func stop() {
        spinner.stopAnimation(nil)
    }
}
