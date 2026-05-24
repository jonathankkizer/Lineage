import AppKit

@MainActor
final class InspectorView: NSView {

    private let selection: SelectionModel
    private let documentProvider: () -> DbtProjectDocument?

    private let scrollView = NSScrollView()
    private let contentStack = NSStackView()
    private var observerID: UUID?

    private static let keyColumnWidth: CGFloat = 80
    private static let listTruncateLimit = 8

    private var expandedSections: Set<String> = []

    init(selection: SelectionModel, documentProvider: @escaping () -> DbtProjectDocument?) {
        self.selection = selection
        self.documentProvider = documentProvider
        super.init(frame: .zero)
        wantsLayer = true
        applyBackgroundColor()

        configureScrollView()
        observerID = selection.addObserver { [weak self] _ in
            self?.expandedSections.removeAll(keepingCapacity: true)
            self?.refresh()
        }
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        if let observerID {
            Task { @MainActor [selection] in selection.removeObserver(observerID) }
        }
    }

    private func applyBackgroundColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance { [weak self] in
            self?.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyBackgroundColor()
        refresh()
    }

    func documentDidLoad(graph: Graph) {
        refresh()
    }

    func notifyGraphChanged(graph: Graph) {
        refresh()
    }

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.automaticallyAdjustsContentInsets = true
        addSubview(scrollView)

        let flipped = FlippedView()
        flipped.translatesAutoresizingMaskIntoConstraints = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.distribution = .fill
        contentStack.spacing = 6

        flipped.addSubview(contentStack)
        scrollView.documentView = flipped

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            flipped.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            contentStack.leadingAnchor.constraint(equalTo: flipped.leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: flipped.trailingAnchor, constant: -14),
            contentStack.topAnchor.constraint(equalTo: flipped.topAnchor, constant: 14),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: flipped.bottomAnchor, constant: -14),
        ])

        refresh()
    }

    // MARK: - Refresh

    private func refresh() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let graph = documentProvider()?.graph else {
            contentStack.addArrangedSubview(emptyState("Open a dbt project to inspect nodes."))
            return
        }

        guard let primary = selection.primary, let node = graph.nodes[primary] else {
            contentStack.addArrangedSubview(emptyState("No selection \u{2014} click a node."))
            contentStack.addArrangedSubview(spacer(16))
            contentStack.addArrangedSubview(sectionHeader("GRAPH"))
            contentStack.addArrangedSubview(labeledRow("Nodes", value: monoText("\(graph.nodes.count)")))
            let edgeCount = graph.forward.reduce(0) { $0 + $1.value.count }
            contentStack.addArrangedSubview(labeledRow("Edges", value: monoText("\(edgeCount)")))
            contentStack.addArrangedSubview(labeledRow("Invocation", value: monoText(graph.invocationID, truncates: true)))

            if let doc = documentProvider() {
                addLastBuildSection(document: doc)
            }
            return
        }

        // Title row: name (large) + kind chip (small, trailing)
        contentStack.addArrangedSubview(titleRow(node: node))

        // Subtitle: schema.database
        if node.schema != nil || node.database != nil {
            let parts = [node.database, node.schema].compactMap { $0 }.filter { !$0.isEmpty }
            if !parts.isEmpty {
                contentStack.addArrangedSubview(subtitleLabel(parts.joined(separator: "  ·  ")))
            }
        }

        contentStack.addArrangedSubview(spacer(10))

        // Properties section
        contentStack.addArrangedSubview(sectionHeader("PROPERTIES"))
        if let mat = node.materialization, !mat.isEmpty {
            contentStack.addArrangedSubview(labeledRow("Materialized", value: monoText(mat)))
        }
        if let runtime = documentProvider()?.buildTimings.executionTime[node.id] {
            contentStack.addArrangedSubview(labeledRow("Run Time", value: monoText(Self.formatDuration(runtime))))
        }
        if let path = node.originalFilePath, !path.isEmpty {
            contentStack.addArrangedSubview(labeledRow("Path", value: pathRow(path)))
        }
        if !node.tags.isEmpty {
            contentStack.addArrangedSubview(labeledRow("Tags", value: tagChipsView(node.tags)))
        }

        // Description
        if let desc = node.description, !desc.isEmpty {
            contentStack.addArrangedSubview(spacer(8))
            contentStack.addArrangedSubview(sectionHeader("DESCRIPTION"))
            contentStack.addArrangedSubview(wrappedText(desc))
        }

        // Depends on
        let parents = graph.parents(of: node.id)
        if !parents.isEmpty {
            contentStack.addArrangedSubview(spacer(8))
            contentStack.addArrangedSubview(sectionHeader("DEPENDS ON  (\(parents.count))"))
            addFullWidthBox(nodeListBox(ids: parents, graph: graph, sectionKey: "parents", dotColor: RendererColors.edgeUpstream))
        }

        // Referenced by
        let children = graph.children(of: node.id)
        if !children.isEmpty {
            contentStack.addArrangedSubview(spacer(8))
            contentStack.addArrangedSubview(sectionHeader("REFERENCED BY  (\(children.count))"))
            addFullWidthBox(nodeListBox(ids: children, graph: graph, sectionKey: "children", dotColor: RendererColors.edgeDownstream))
        }

        // Columns
        if !node.columns.isEmpty {
            contentStack.addArrangedSubview(spacer(8))
            contentStack.addArrangedSubview(sectionHeader("COLUMNS  (\(node.columns.count))"))
            addFullWidthBox(columnsBox(node.columns, sectionKey: "columns"))
        }
    }

    private func addFullWidthBox(_ view: NSView) {
        contentStack.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    // MARK: - Row builders

    private func titleRow(node: GraphNode) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8

        let title = NSTextField(labelWithString: node.name)
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.lineBreakMode = .byTruncatingMiddle
        title.maximumNumberOfLines = 2
        title.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(spacerFill())
        stack.addArrangedSubview(kindChip(node.kind))
        return stack
    }

    private func subtitleLabel(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }

    private func kindChip(_ kind: ResourceKind) -> NSView {
        let chip = ChipView()
        chip.configure(text: kind.displayName.uppercased(),
                       backgroundColor: RendererColors.fill(for: kind).withAlphaComponent(0.18),
                       textColor: RendererColors.border(for: kind),
                       isBordered: true,
                       borderColor: RendererColors.border(for: kind).withAlphaComponent(0.6),
                       fontSize: 9.5,
                       fontWeight: .bold)
        return chip
    }

    private func sectionHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func labeledRow(_ key: String, value: NSView, tooltip: String? = nil) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8

        let keyLabel = NSTextField(labelWithString: key)
        keyLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        keyLabel.textColor = .secondaryLabelColor
        keyLabel.alignment = .right
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.widthAnchor.constraint(equalToConstant: Self.keyColumnWidth).isActive = true
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)

        value.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(keyLabel)
        stack.addArrangedSubview(value)
        if let tooltip {
            stack.toolTip = tooltip
        }
        return stack
    }

    private func monoText(_ s: String, truncates: Bool = false) -> NSView {
        let label = NSTextField(labelWithString: s)
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    private func wrappedText(_ s: String) -> NSView {
        let label = NSTextField(wrappingLabelWithString: s)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .labelColor
        return label
    }

    private func pathRow(_ path: String) -> NSView {
        let button = NSButton(title: path, target: self, action: #selector(revealFile(_:)))
        button.bezelStyle = .inline
        button.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        button.alignment = .left
        button.lineBreakMode = .byTruncatingMiddle
        button.identifier = NSUserInterfaceItemIdentifier(path)
        button.imagePosition = .imageRight
        button.image = NSImage(systemSymbolName: "arrow.up.forward.square", accessibilityDescription: "Reveal in Finder")
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = .secondaryLabelColor
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }

    @objc private func revealFile(_ sender: NSButton) {
        guard let rel = sender.identifier?.rawValue,
              let projectRoot = documentProvider()?.projectRootURL else { return }
        let url = projectRoot.appendingPathComponent(rel)
        let needsRelease = projectRoot.startAccessingSecurityScopedResource()
        defer { if needsRelease { projectRoot.stopAccessingSecurityScopedResource() } }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func tagChipsView(_ tags: [String]) -> NSView {
        let flow = WrappingHStack()
        flow.translatesAutoresizingMaskIntoConstraints = false
        let chips = tags.map { tag -> NSView in
            let chip = ChipView()
            chip.configure(text: tag,
                           backgroundColor: NSColor.tertiaryLabelColor.withAlphaComponent(0.18),
                           textColor: .secondaryLabelColor,
                           isBordered: false,
                           borderColor: .clear,
                           fontSize: 10,
                           fontWeight: .medium)
            return chip
        }
        flow.setChips(chips)
        return flow
    }

    private func nodeListBox(ids: [NodeID], graph: Graph, sectionKey: String, dotColor: NSColor) -> NSView {
        let isExpanded = expandedSections.contains(sectionKey)
        let total = ids.count
        let visibleIds: [NodeID]
        let needsTruncate = total > Self.listTruncateLimit
        if needsTruncate, !isExpanded {
            visibleIds = Array(ids.prefix(Self.listTruncateLimit))
        } else {
            visibleIds = ids
        }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

        for id in visibleIds {
            stack.addArrangedSubview(nodeRow(id: id, graph: graph, dotColor: dotColor))
        }
        if needsTruncate {
            stack.addArrangedSubview(disclosureRow(sectionKey: sectionKey, isExpanded: isExpanded, hiddenCount: total - Self.listTruncateLimit))
        }

        return borderedBox(stack)
    }

    private func nodeRow(id: NodeID, graph: Graph, dotColor: NSColor) -> NSView {
        let title = graph.nodes[id]?.name ?? id.displayName

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY

        let dot = NSView()
        dot.wantsLayer = true
        dot.layer?.backgroundColor = dotColor.cgColor
        dot.layer?.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
        ])

        let button = NSButton(title: title, target: self, action: #selector(jumpToNode(_:)))
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 11)
        button.alignment = .left
        button.lineBreakMode = .byTruncatingMiddle
        button.identifier = NSUserInterfaceItemIdentifier(id.rawValue)
        button.contentTintColor = .labelColor
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(dot)
        stack.addArrangedSubview(button)
        return stack
    }

    @objc private func jumpToNode(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue else { return }
        selection.replace(with: NodeID(raw))
    }

    private func disclosureRow(sectionKey: String, isExpanded: Bool, hiddenCount: Int) -> NSView {
        let title = isExpanded ? "Show less" : "Show \(hiddenCount) more"
        let button = NSButton(title: title, target: self, action: #selector(toggleDisclosure(_:)))
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        button.contentTintColor = .linkColor
        button.identifier = NSUserInterfaceItemIdentifier(sectionKey)
        button.alignment = .left
        return button
    }

    @objc private func toggleDisclosure(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        if expandedSections.contains(key) {
            expandedSections.remove(key)
        } else {
            expandedSections.insert(key)
        }
        refresh()
    }

    private func columnsBox(_ columns: [GraphColumn], sectionKey: String) -> NSView {
        let isExpanded = expandedSections.contains(sectionKey)
        let needsTruncate = columns.count > Self.listTruncateLimit
        let visible = (needsTruncate && !isExpanded) ? Array(columns.prefix(Self.listTruncateLimit)) : columns

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

        for col in visible {
            stack.addArrangedSubview(columnRow(col))
        }
        if needsTruncate {
            stack.addArrangedSubview(disclosureRow(sectionKey: sectionKey, isExpanded: isExpanded, hiddenCount: columns.count - Self.listTruncateLimit))
        }
        return borderedBox(stack)
    }

    private func columnRow(_ col: GraphColumn) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        let name = NSTextField(labelWithString: col.name)
        name.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        name.textColor = .labelColor
        name.lineBreakMode = .byTruncatingTail
        name.maximumNumberOfLines = 1
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(name)
        if let type = col.dataType, !type.isEmpty {
            let typeLabel = NSTextField(labelWithString: type)
            typeLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            typeLabel.textColor = .tertiaryLabelColor
            typeLabel.lineBreakMode = .byTruncatingTail
            typeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stack.addArrangedSubview(typeLabel)
        }
        return stack
    }

    private func borderedBox(_ content: NSView) -> NSView {
        let box = NSView()
        box.wantsLayer = true
        box.layer?.borderWidth = 1
        box.layer?.borderColor = NSColor.separatorColor.cgColor
        box.layer?.cornerRadius = 4
        box.layer?.cornerCurve = .continuous

        content.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            content.topAnchor.constraint(equalTo: box.topAnchor),
            content.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        ])
        return box
    }

    private func emptyState(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .tertiaryLabelColor
        return label
    }

    private func spacer(_ height: CGFloat) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    private func spacerFill() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func addLastBuildSection(document: DbtProjectDocument) {
        let timings = document.buildTimings
        guard !timings.isEmpty || timings.wallClockSeconds != nil else { return }

        contentStack.addArrangedSubview(spacer(16))
        contentStack.addArrangedSubview(sectionHeader("LAST BUILD"))

        if let wall = timings.wallClockSeconds {
            contentStack.addArrangedSubview(labeledRow(
                "Wall clock",
                value: monoText(Self.formatDuration(wall)),
                tooltip: "Real elapsed time of the last dbt build, end to end. Read from run_results.json's elapsed_time."
            ))
        }
        if timings.cpuSeconds > 0 {
            contentStack.addArrangedSubview(labeledRow(
                "Total CPU",
                value: monoText(Self.formatDuration(timings.cpuSeconds)),
                tooltip: "Sum of every model's execution time. Total warehouse work performed, regardless of how it was parallelised. Always ≥ wall clock."
            ))
        }
        if let cp = document.criticalPath {
            let nodeCount = cp.nodes.count
            let suffix = nodeCount == 1 ? "1 node" : "\(nodeCount) nodes"
            contentStack.addArrangedSubview(labeledRow(
                "Critical path",
                value: monoText("\(Self.formatDuration(cp.totalSeconds))  ·  \(suffix)"),
                tooltip: "The longest dependency chain by build time — the theoretical floor on wall clock assuming infinite warehouse concurrency. Optimizing a node on this path shortens the whole build; optimizing one off it doesn't."
            ))
            if let wall = timings.wallClockSeconds, wall > 0, cp.totalSeconds > 0, cp.totalSeconds < wall {
                let ratio = cp.totalSeconds / wall
                let pct = Int((ratio * 100).rounded())
                contentStack.addArrangedSubview(labeledRow(
                    "Floor / actual",
                    value: monoText("\(pct)%"),
                    tooltip: "Critical path as a percent of actual wall clock. High (near 100%) means the build is already well-parallelised — next wins require model optimization. Low means there's slack — check dbt thread count and warehouse concurrency."
                ))
            }
        }
    }

    private static func formatDuration(_ t: TimeInterval) -> String {
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
}

@MainActor
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
private final class ChipView: NSView {
    private let label = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 3
        layer?.cornerCurve = .continuous
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(
        text: String,
        backgroundColor: NSColor,
        textColor: NSColor,
        isBordered: Bool,
        borderColor: NSColor,
        fontSize: CGFloat,
        fontWeight: NSFont.Weight
    ) {
        label.stringValue = text
        label.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        label.textColor = textColor
        layer?.backgroundColor = backgroundColor.cgColor
        layer?.borderWidth = isBordered ? 0.5 : 0
        layer?.borderColor = borderColor.cgColor
    }

    override var intrinsicContentSize: NSSize {
        let labelSize = label.intrinsicContentSize
        return NSSize(width: labelSize.width + 10, height: labelSize.height + 2)
    }

    override var firstBaselineOffsetFromTop: CGFloat {
        1 + label.firstBaselineOffsetFromTop
    }
}

@MainActor
private final class WrappingHStack: NSView {

    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 4

    private var cachedHeight: CGFloat = 0
    private var cachedWidth: CGFloat = -1

    override var isFlipped: Bool { true }

    func setChips(_ chips: [NSView]) {
        subviews.forEach { $0.removeFromSuperview() }
        for chip in chips {
            chip.translatesAutoresizingMaskIntoConstraints = false
            addSubview(chip)
        }
        cachedWidth = -1
        invalidateIntrinsicContentSize()
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let info = computeLayout(maxWidth: bounds.width)
        for (view, frame) in zip(subviews, info.frames) {
            view.frame = frame
        }
        if abs(info.height - cachedHeight) > 0.5 || cachedWidth != bounds.width {
            cachedHeight = info.height
            cachedWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: NSSize {
        let width = bounds.width > 0 ? bounds.width : 200
        let info = computeLayout(maxWidth: width)
        return NSSize(width: NSView.noIntrinsicMetric, height: info.height)
    }

    override var firstBaselineOffsetFromTop: CGFloat {
        subviews.first?.firstBaselineOffsetFromTop ?? 0
    }

    private func computeLayout(maxWidth: CGFloat) -> (frames: [NSRect], height: CGFloat) {
        var frames: [NSRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for v in subviews {
            let size = v.fittingSize
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            frames.append(NSRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (frames, y + rowHeight)
    }
}
