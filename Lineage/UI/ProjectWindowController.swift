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
    private var inspectorVisible = true
    private var loadingShowWorkItem: DispatchWorkItem?
    private static let loadingDeferDelay: TimeInterval = 0.4

    private var searchQuery: String = ""
    private weak var searchToolbarItem: NSSearchToolbarItem?
    private weak var filterToolbarButton: NSButton?
    private var filterPopover: NSPopover?

    private var coloringMode: NodeColoring = .kind
    private weak var coloringSegmented: NSSegmentedControl?

    nonisolated private static let zoomToFitID = NSToolbarItem.Identifier("zoom-to-fit")
    nonisolated private static let searchID = NSToolbarItem.Identifier("search")
    nonisolated private static let filterID = NSToolbarItem.Identifier("filter")
    nonisolated private static let coloringID = NSToolbarItem.Identifier("coloring")
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

        super.init(window: nil)
        self.window = window
        window.delegate = self

        configureSplitView()
        configureToolbar()
        configureLoadingOverlay()
    }

    required init?(coder: NSCoder) { nil }

    private func configureSplitView() {
        let splitController = NSSplitViewController()
        splitController.view.translatesAutoresizingMaskIntoConstraints = false

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
        let toolbar = NSToolbar(identifier: "ProjectToolbar.v2")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = false
        window?.toolbar = toolbar
        toolbar.displayMode = .iconOnly
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
        scheduleLoadingOverlay(message: "Parsing manifest\u{2026}", delay: 0)
    }

    private func scheduleLoadingOverlay(message: String, delay: TimeInterval) {
        loadingShowWorkItem?.cancel()
        if delay <= 0 {
            loadingOverlay.isHidden = false
            loadingOverlay.start(message: message)
            return
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.loadingOverlay.isHidden = false
            self.loadingOverlay.start(message: message)
        }
        loadingShowWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func hideLoadingOverlay() {
        loadingShowWorkItem?.cancel()
        loadingShowWorkItem = nil
        loadingOverlay.stop()
        loadingOverlay.isHidden = true
    }

    func documentDidFinishLoading() {
        hideLoadingOverlay()
        guard let document = projectDocument,
              let graph = document.graph,
              let layout = document.graphLayout else { return }

        window?.title = document.displayName ?? "dbt Project"
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
        graphView.resetBulkEdgesToAuto()
        inspectorView.documentDidLoad(graph: graph)
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
        [.toggleSidebar, .sidebarTrackingSeparator, Self.zoomToFitID, Self.filterID, Self.coloringID, .flexibleSpace, Self.searchID, .flexibleSpace, Self.toggleInspectorID]
    }

    nonisolated func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, Self.zoomToFitID, Self.filterID, Self.coloringID, Self.searchID, Self.toggleInspectorID, .flexibleSpace, .space]
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

        default:
            return nil
        }
    }

    @objc private func zoomToFitAction(_ sender: Any?) {
        graphView.zoomToFit()
    }

    @objc func toggleInspector(_ sender: Any?) {
        inspectorVisible.toggle()
        inspectorSplitItem.animator().isCollapsed = !inspectorVisible
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
        coloringSegmented?.selectedSegment = mode.rawValue
        graphView.setColoring(mode)
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
    }

    private func computeVisibility() -> Visibility {
        var v = Visibility(scope: nil, focusEntry: focusHistory.current, focusNodeCount: 0, searchMatchCount: nil)
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

        switch (focusScope, searchScope) {
        case let (focus?, search?):
            // Both active: intersect node sets; directional info doesn't compose cleanly,
            // so fall back to flat scope. The visible nodes are still correctly clipped.
            v.scope = SelectionScope(
                nodes: focus.nodes.intersection(search.nodes),
                upstream: nil,
                downstream: nil
            )
        case let (focus?, nil):
            v.scope = focus
        case let (nil, search?):
            v.scope = search
        case (nil, nil):
            v.scope = nil
        }
        return v
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

    private func applyCurrentFocus(animated: Bool) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let duration: CFTimeInterval = (animated && !reduceMotion) ? 0.30 : 0
        let v = computeVisibility()
        graphView.applyFocus(scope: v.scope, animationDuration: duration)
        updateSubtitle(v)
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

    // MARK: - Search

    @objc func focusFilterField(_ sender: Any?) {
        guard let field = searchToolbarItem?.searchField else { return }
        window?.makeFirstResponder(field)
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
        applyCurrentFocus(animated: false)
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
        case #selector(reloadProject(_:)):
            return projectDocument?.manifestURL != nil
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
