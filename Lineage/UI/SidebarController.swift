import AppKit

@MainActor
final class SidebarController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate, NSMenuItemValidation {

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

        /// Stable identity for `autosaveExpandedItems`. Rows are rebuilt on every
        /// document load, so AppKit needs a value it can match across launches.
        var persistentKey: String {
            switch kind {
            case .all: return "all"
            case .foldersGroup: return "group:folders"
            case .tagsGroup: return "group:tags"
            case .folder(let path): return "folder:\(path)"
            case .tag(let name): return "tag:\(name)"
            }
        }
    }

    private let outlineView = NSOutlineView()
    private let scrollView = NSScrollView()
    private var rootRows: [Row] = []
    private var allRow: Row?
    private var suppressSelectionChange = false
    private var rowsByPersistentKey: [String: Row] = [:]

    var onScopeChange: ((FilterScope) -> Void)?

    /// Set by the window controller so folder rows can resolve to a real
    /// directory for Reveal in Finder.
    var projectRootProvider: (() -> URL?)?

    override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.title = "Name"
        column.minWidth = 100
        column.maxWidth = 600
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        outlineView.style = .sourceList
        outlineView.headerView = nil
        outlineView.allowsEmptySelection = false
        outlineView.allowsMultipleSelection = false
        outlineView.rowSizeStyle = .default
        outlineView.indentationPerLevel = 12
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.floatsGroupRows = false
        outlineView.autosaveName = "ProjectSidebar"
        outlineView.autosaveExpandedItems = true
        outlineView.autosaveTableColumns = false

        let contextMenu = NSMenu()
        contextMenu.delegate = self
        outlineView.menu = contextMenu

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

        rowsByPersistentKey = [:]
        indexRows(rootRows)

        // `reloadData` re-applies saved disclosure state via autosaveExpandedItems.
        outlineView.reloadData()

        // Only force the section headers open the very first time the app runs;
        // after that the user's own collapse choices are what autosave restored.
        if !UserDefaults.standard.bool(forKey: Self.seededExpansionDefaultsKey) {
            for row in rootRows where row.isGroup {
                outlineView.expandItem(row)
            }
            UserDefaults.standard.set(true, forKey: Self.seededExpansionDefaultsKey)
        }
        selectVisualRow(rowMatching: scope)
    }

    private static let seededExpansionDefaultsKey = "Sidebar.seededDefaultExpansion"

    private func indexRows(_ rows: [Row]) {
        for row in rows {
            rowsByPersistentKey[row.persistentKey] = row
            indexRows(row.children)
        }
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

    // Disclosure-state persistence. `Row` instances are recreated on every
    // document load, so autosaveExpandedItems needs a stable string to key on.

    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        (item as? Row)?.persistentKey
    }

    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        guard let key = object as? String else { return nil }
        return rowsByPersistentKey[key]
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

    // MARK: - Context menu

    /// The row the context menu applies to: the right-clicked row if there is
    /// one, otherwise the current selection — the Finder convention.
    private var contextRow: Row? {
        let index = outlineView.clickedRow >= 0 ? outlineView.clickedRow : outlineView.selectedRow
        guard index >= 0 else { return nil }
        return outlineView.item(atRow: index) as? Row
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let row = contextRow, !row.isGroup else { return }

        menu.addItem(item(title: "Show Only \u{201C}\(row.title)\u{201D}", action: #selector(scopeToContextRow(_:))))
        menu.addItem(item(title: "Show All", action: #selector(scopeToAll(_:))))
        menu.addItem(.separator())

        switch row.kind {
        case .folder:
            menu.addItem(item(title: "Copy Folder Path", action: #selector(copyContextRowValue(_:))))
            menu.addItem(item(title: "Reveal in Finder", action: #selector(revealContextRowInFinder(_:))))
        case .tag:
            menu.addItem(item(title: "Copy Tag Name", action: #selector(copyContextRowValue(_:))))
        default:
            break
        }
    }

    private func item(title: String, action: Selector) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
        entry.target = self
        return entry
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard menuItem.action == #selector(revealContextRowInFinder(_:)) else { return true }
        return contextFolderURL() != nil
    }

    private func contextFolderURL() -> URL? {
        guard let row = contextRow, case .folder(let path) = row.kind,
              let root = projectRootProvider?() else { return nil }
        let url = root.appendingPathComponent(path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else { return nil }
        return url
    }

    @objc private func scopeToContextRow(_ sender: Any?) {
        guard let row = contextRow else { return }
        switch row.kind {
        case .all: onScopeChange?(.all)
        case .folder(let path): onScopeChange?(.folder(path))
        case .tag(let name): onScopeChange?(.tag(name))
        default: return
        }
        selectVisualRow(rowMatching: scope(for: row))
    }

    @objc private func scopeToAll(_ sender: Any?) {
        onScopeChange?(.all)
        selectVisualRow(rowMatching: .all)
    }

    private func scope(for row: Row) -> FilterScope {
        switch row.kind {
        case .folder(let path): return .folder(path)
        case .tag(let name): return .tag(name)
        default: return .all
        }
    }

    @objc private func copyContextRowValue(_ sender: Any?) {
        guard let row = contextRow else { return }
        let value: String
        switch row.kind {
        case .folder(let path): value = path
        case .tag(let name): value = name
        default: value = row.title
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    @objc private func revealContextRowInFinder(_ sender: Any?) {
        guard let url = contextFolderURL() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
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
