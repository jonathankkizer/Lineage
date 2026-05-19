import AppKit

@MainActor
final class SidebarController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    final class Row: NSObject {
        enum Kind: Equatable {
            case all
            case foldersGroup
            case tagsGroup
            case folder(String)
            case tag(String)
        }

        let kind: Kind
        let title: String
        let count: Int
        var children: [Row] = []

        init(kind: Kind, title: String, count: Int) {
            self.kind = kind
            self.title = title
            self.count = count
        }

        var isGroup: Bool {
            switch kind {
            case .foldersGroup, .tagsGroup: return true
            default: return false
            }
        }
    }

    private let outlineView = NSOutlineView()
    private let scrollView = NSScrollView()
    private var rootRows: [Row] = []
    private var allRow: Row?
    private var suppressSelectionChange = false

    var onScopeChange: ((FilterScope) -> Void)?

    override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.title = "Name"
        column.minWidth = 100
        column.maxWidth = 600
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        outlineView.style = .sourceList
        outlineView.selectionHighlightStyle = .sourceList
        outlineView.headerView = nil
        outlineView.allowsEmptySelection = false
        outlineView.allowsMultipleSelection = false
        outlineView.rowSizeStyle = .default
        outlineView.indentationPerLevel = 12
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.floatsGroupRows = false
        outlineView.autosaveExpandedItems = false

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        self.view = container
    }

    func populate(
        totalNodes: Int,
        folderTree: [FolderNode],
        tags: [(tag: String, count: Int)],
        scope: FilterScope
    ) {
        suppressSelectionChange = true
        defer { suppressSelectionChange = false }

        let all = Row(kind: .all, title: "All", count: totalNodes)
        self.allRow = all

        let foldersGroup = Row(kind: .foldersGroup, title: "FOLDERS", count: folderTree.count)
        foldersGroup.children = folderTree.map { Self.makeFolderRow($0) }

        let tagsGroup = Row(kind: .tagsGroup, title: "TAGS", count: tags.count)
        tagsGroup.children = tags.map { Row(kind: .tag($0.tag), title: $0.tag, count: $0.count) }

        rootRows = [all]
        if !folderTree.isEmpty { rootRows.append(foldersGroup) }
        if !tags.isEmpty { rootRows.append(tagsGroup) }

        outlineView.reloadData()
        for row in rootRows where row.isGroup {
            outlineView.expandItem(row)
        }
        selectVisualRow(rowMatching: scope)
    }

    private static func makeFolderRow(_ node: FolderNode) -> Row {
        let row = Row(kind: .folder(node.path), title: node.name, count: node.totalCount)
        row.children = node.children.map { makeFolderRow($0) }
        return row
    }

    func clear() {
        suppressSelectionChange = true
        defer { suppressSelectionChange = false }
        rootRows = []
        allRow = nil
        outlineView.reloadData()
    }

    private func selectVisualRow(rowMatching scope: FilterScope) {
        var path: [Row] = []
        guard findPath(in: rootRows, scope: scope, path: &path), let target = path.last else { return }
        for ancestor in path.dropLast() {
            outlineView.expandItem(ancestor)
        }
        let idx = outlineView.row(forItem: target)
        guard idx >= 0 else { return }
        outlineView.selectRowIndexes(IndexSet(integer: idx), byExtendingSelection: false)
        outlineView.scrollRowToVisible(idx)
    }

    private func findPath(in rows: [Row], scope: FilterScope, path: inout [Row]) -> Bool {
        for row in rows {
            path.append(row)
            if row.matches(scope) { return true }
            if findPath(in: row.children, scope: scope, path: &path) { return true }
            path.removeLast()
        }
        return false
    }

    // MARK: - DataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? Row { return item.children.count }
        return rootRows.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? Row { return item.children[index] }
        return rootRows[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let row = item as? Row else { return false }
        return !row.children.isEmpty
    }

    // MARK: - Delegate

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        (item as? Row)?.isGroup ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let row = item as? Row else { return false }
        return !row.isGroup
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let row = item as? Row else { return nil }
        if row.isGroup {
            return groupCell(text: row.title)
        }
        let icon: NSImage? = {
            switch row.kind {
            case .all: return NSImage(systemSymbolName: "circle.grid.2x2", accessibilityDescription: nil)
            case .folder: return NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
            case .tag: return NSImage(systemSymbolName: "tag", accessibilityDescription: nil)
            default: return nil
            }
        }()
        return leafCell(title: row.title, count: row.count, icon: icon)
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        if suppressSelectionChange { return }
        let idx = outlineView.selectedRow
        guard idx >= 0, let row = outlineView.item(atRow: idx) as? Row else { return }
        let scope: FilterScope
        switch row.kind {
        case .all: scope = .all
        case .folder(let name): scope = .folder(name)
        case .tag(let name): scope = .tag(name)
        default: return
        }
        onScopeChange?(scope)
    }

    // MARK: - Cell builders

    private func groupCell(text: String) -> NSView {
        let cell = NSTableCellView()
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        cell.textField = label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    private func leafCell(title: String, count: Int, icon: NSImage?) -> NSView {
        let cell = NSTableCellView()

        let titleField = NSTextField(labelWithString: title)
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.font = NSFont.systemFont(ofSize: 13)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let countField = NSTextField(labelWithString: count > 0 ? "\(count)" : "")
        countField.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        countField.textColor = .tertiaryLabelColor
        countField.alignment = .right
        countField.translatesAutoresizingMaskIntoConstraints = false
        countField.setContentHuggingPriority(.required, for: .horizontal)

        let imageView = NSImageView()
        imageView.image = icon
        imageView.symbolConfiguration = .init(pointSize: 12, weight: .regular)
        imageView.contentTintColor = .secondaryLabelColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        cell.addSubview(imageView)
        cell.addSubview(titleField)
        cell.addSubview(countField)
        cell.textField = titleField
        cell.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),

            titleField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6),
            titleField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            titleField.trailingAnchor.constraint(lessThanOrEqualTo: countField.leadingAnchor, constant: -8),

            countField.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            countField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])

        return cell
    }
}

private extension SidebarController.Row {
    func matches(_ scope: FilterScope) -> Bool {
        switch (kind, scope) {
        case (.all, .all): return true
        case (.folder(let a), .folder(let b)): return a == b
        case (.tag(let a), .tag(let b)): return a == b
        default: return false
        }
    }
}
