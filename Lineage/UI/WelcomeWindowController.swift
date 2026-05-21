import AppKit

/// "Welcome to Lineage" launcher window, shown when the app starts with no
/// open documents (Xcode / Tower style). Left column: app identity and
/// primary actions. Right column: Recent Projects list backed by
/// `NSDocumentController.shared.recentDocumentURLs`. Bottom: a single
/// preference for whether to show this window on launch.
@MainActor
final class WelcomeWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate {

    static let showOnLaunchDefaultsKey = "WelcomeWindow.showOnLaunch"

    private let recentsTable = NSTableView()
    private let scrollView = NSScrollView()
    private let emptyStateLabel = NSTextField(labelWithString: "No Recent Projects")
    private let showOnLaunchCheckbox = NSButton(checkboxWithTitle: "Show this window when Lineage launches", target: nil, action: nil)

    private var recentURLs: [URL] = []

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: nil)
        self.window = window
        window.delegate = self

        configureContent()
        configureCheckbox()
        reloadRecents()

        // Auto-dismiss when any document window becomes main — Mac convention
        // for launcher/welcome windows (Xcode, Tower). Covers all open paths:
        // the in-window buttons, File > Open, File > Open Recent menu, drag
        // onto Dock, etc. If the user cancels the Open panel, no document
        // window appears and we stay put.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(anyWindowBecameMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Content

    private func configureContent() {
        guard let contentView = window?.contentView else { return }

        let left = makeLeftColumn()
        let right = makeRightColumn()

        let columns = NSStackView(views: [left, right])
        columns.orientation = .horizontal
        columns.alignment = .top
        columns.distribution = .fill
        columns.spacing = 0
        columns.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(columns)

        NSLayoutConstraint.activate([
            columns.topAnchor.constraint(equalTo: contentView.topAnchor),
            columns.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            columns.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Leave room for the checkbox row at the bottom.
            columns.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -44),
            left.widthAnchor.constraint(equalToConstant: 340),
        ])
    }

    private func makeLeftColumn() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(named: NSImage.applicationIconName) ?? NSImage(named: "AppIcon")
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 128),
            icon.heightAnchor.constraint(equalToConstant: 128),
        ])

        let title = NSTextField(labelWithString: "Welcome to Lineage")
        title.font = NSFont.systemFont(ofSize: 28, weight: .bold)
        title.textColor = .labelColor

        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development"
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        versionLabel.textColor = .secondaryLabelColor

        let openButton = makeActionButton(
            title: "Open dbt Project…",
            symbolName: "folder",
            action: #selector(openDocumentClicked(_:))
        )
        openButton.keyEquivalent = "\r"  // primary / default action

        let demoButton = makeActionButton(
            title: "Explore Demo Project",
            symbolName: "sparkles",
            action: #selector(openDemoClicked(_:))
        )

        let connectButton = makeActionButton(
            title: "Connect to GitHub Actions…",
            symbolName: "arrow.triangle.2.circlepath",
            action: #selector(connectToGitHubClicked(_:))
        )

        let identity = NSStackView(views: [title, versionLabel])
        identity.orientation = .vertical
        identity.alignment = .leading
        identity.spacing = 2

        let actions = NSStackView(views: [openButton, demoButton, connectButton])
        actions.orientation = .vertical
        actions.alignment = .leading
        actions.spacing = 10

        let stack = NSStackView(views: [icon, identity, NSView(), actions])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.edgeInsets = NSEdgeInsets(top: 36, left: 36, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }

    private func makeActionButton(title: String, symbolName: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .regularSquare
        button.controlSize = .large
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 240),
            button.heightAnchor.constraint(equalToConstant: 36),
        ])
        return button
    }

    private func makeRightColumn() -> NSView {
        let heading = NSTextField(labelWithString: "Recent Projects")
        heading.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        heading.textColor = .secondaryLabelColor

        recentsTable.headerView = nil
        recentsTable.backgroundColor = .clear
        recentsTable.rowSizeStyle = .custom
        recentsTable.rowHeight = 44
        recentsTable.intercellSpacing = NSSize(width: 0, height: 2)
        recentsTable.gridStyleMask = []
        recentsTable.usesAlternatingRowBackgroundColors = false
        recentsTable.style = .inset
        recentsTable.target = self
        recentsTable.doubleAction = #selector(openSelectedRecent(_:))
        recentsTable.action = #selector(noop(_:))  // single click should just select, not open
        recentsTable.allowsEmptySelection = true
        recentsTable.allowsMultipleSelection = false
        recentsTable.dataSource = self
        recentsTable.delegate = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("recent"))
        column.resizingMask = .autoresizingMask
        recentsTable.addTableColumn(column)

        scrollView.documentView = recentsTable
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        emptyStateLabel.textColor = .tertiaryLabelColor
        emptyStateLabel.alignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)
        container.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            emptyStateLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let stack = NSStackView(views: [heading, container])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 48, left: 12, bottom: 24, right: 28)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        return stack
    }

    private func configureCheckbox() {
        guard let contentView = window?.contentView else { return }

        showOnLaunchCheckbox.target = self
        showOnLaunchCheckbox.action = #selector(toggleShowOnLaunch(_:))
        showOnLaunchCheckbox.state = UserDefaults.standard.bool(forKey: Self.showOnLaunchDefaultsKey) ? .on : .off
        showOnLaunchCheckbox.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        showOnLaunchCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(showOnLaunchCheckbox)

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: showOnLaunchCheckbox.topAnchor, constant: -10),

            showOnLaunchCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            showOnLaunchCheckbox.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Recent documents

    func reloadRecents() {
        recentURLs = NSDocumentController.shared.recentDocumentURLs
        recentsTable.reloadData()
        emptyStateLabel.isHidden = !recentURLs.isEmpty
        scrollView.isHidden = recentURLs.isEmpty
    }

    func numberOfRows(in tableView: NSTableView) -> Int { recentURLs.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let url = recentURLs[row]

        let title = NSTextField(labelWithString: url.lastPathComponent)
        title.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .labelColor
        title.lineBreakMode = .byTruncatingTail
        title.cell?.usesSingleLineMode = true

        let subtitle = NSTextField(labelWithString: abbreviatedPath(for: url))
        subtitle.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byTruncatingMiddle
        subtitle.cell?.usesSingleLineMode = true

        let stack = NSStackView(views: [title, subtitle])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 1
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let cell = NSTableCellView()
        cell.identifier = NSUserInterfaceItemIdentifier("recent-row")
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.topAnchor),
            stack.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
        ])
        return cell
    }

    private func abbreviatedPath(for url: URL) -> String {
        let path = url.path
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    // MARK: - Actions

    @objc private func openDocumentClicked(_ sender: Any?) {
        NSDocumentController.shared.openDocument(sender)
    }

    @objc private func openDemoClicked(_ sender: Any?) {
        DemoProjectLocator.openDemo()
    }

    @objc private func connectToGitHubClicked(_ sender: Any?) {
        NSApp.sendAction(#selector(LineageActions.connectToGitHub(_:)), to: nil, from: sender)
    }

    @objc private func openSelectedRecent(_ sender: Any?) {
        let row = recentsTable.clickedRow >= 0 ? recentsTable.clickedRow : recentsTable.selectedRow
        guard row >= 0, row < recentURLs.count else { return }
        let url = recentURLs[row]
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
    }

    @objc private func noop(_ sender: Any?) {}

    @objc private func toggleShowOnLaunch(_ sender: Any?) {
        let on = showOnLaunchCheckbox.state == .on
        UserDefaults.standard.set(on, forKey: Self.showOnLaunchDefaultsKey)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // No state to persist beyond the checkbox, which writes through immediately.
    }

    @objc private func anyWindowBecameMain(_ notification: Notification) {
        guard let window, window.isVisible else { return }
        guard let other = notification.object as? NSWindow, other !== window else { return }
        // Dismiss only when a document window appears, so transient UI like
        // the Open panel doesn't trigger it.
        let isDocumentWindow = NSDocumentController.shared.documents
            .flatMap(\.windowControllers)
            .contains { $0.window === other }
        guard isDocumentWindow else { return }
        window.performClose(nil)
    }
}
