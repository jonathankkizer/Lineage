import AppKit

/// Classic Mac preferences window: an NSToolbar pane switcher over a stack of
/// simple views, resizing to whichever pane is showing. Deliberately not a
/// SwiftUI `Settings` scene — see the AppKit-only rule in CLAUDE.md.
@MainActor
final class SettingsWindowController: NSWindowController, NSToolbarDelegate, NSWindowDelegate {

    // Pure data — kept off the MainActor so the nonisolated NSToolbarDelegate
    // methods below can build key paths to `itemIdentifier`.
    private nonisolated enum Pane: String, CaseIterable {
        case general
        case appearance
        case updates

        var title: String {
            switch self {
            case .general: return "General"
            case .appearance: return "Appearance"
            case .updates: return "Updates"
            }
        }

        var symbolName: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintpalette"
            case .updates: return "arrow.down.circle"
            }
        }

        var itemIdentifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier("settings.\(rawValue)")
        }
    }

    private static let selectedPaneDefaultsKey = "SettingsWindow.selectedPane"

    private var paneViews: [Pane: NSView] = [:]
    private var currentPane: Pane = .general
    private let container = NSView()
    private var containerHeight: NSLayoutConstraint!

    /// Wired by the app delegate so the Updates pane can drive the real
    /// coordinator rather than poking UserDefaults behind its back.
    var updateCoordinator: UpdateCoordinator?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("SettingsWindow")

        super.init(window: nil)
        self.window = window
        window.delegate = self

        configureContainer()
        configureToolbar()

        let saved = UserDefaults.standard.string(forKey: Self.selectedPaneDefaultsKey)
        select(Pane(rawValue: saved ?? "") ?? .general, animated: false)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Layout

    private func configureContainer() {
        guard let contentView = window?.contentView else { return }
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        containerHeight = container.heightAnchor.constraint(equalToConstant: 200)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    private func configureToolbar() {
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
        window?.toolbar = toolbar
        if #available(macOS 11.0, *) {
            window?.toolbarStyle = .preference
        }
    }

    nonisolated func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.itemIdentifier)
    }

    nonisolated func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.itemIdentifier)
    }

    nonisolated func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Pane.allCases.map(\.itemIdentifier)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let pane = Pane.allCases.first(where: { $0.itemIdentifier == itemIdentifier }) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = pane.title
        item.paletteLabel = pane.title
        item.image = NSImage(systemSymbolName: pane.symbolName, accessibilityDescription: pane.title)
        item.target = self
        item.action = #selector(toolbarPaneClicked(_:))
        return item
    }

    @objc private func toolbarPaneClicked(_ sender: NSToolbarItem) {
        guard let pane = Pane.allCases.first(where: { $0.itemIdentifier == sender.itemIdentifier }) else { return }
        select(pane, animated: true)
    }

    private func select(_ pane: Pane, animated: Bool) {
        currentPane = pane
        UserDefaults.standard.set(pane.rawValue, forKey: Self.selectedPaneDefaultsKey)
        window?.toolbar?.selectedItemIdentifier = pane.itemIdentifier
        window?.title = pane.title

        let view = paneView(for: pane)
        container.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            view.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
        ])

        resizeWindow(to: view, animated: animated)
    }

    /// Preference windows resize to their content as you switch panes, keeping
    /// the title bar anchored rather than the bottom-left origin.
    private func resizeWindow(to view: NSView, animated: Bool) {
        guard let window else { return }
        view.layoutSubtreeIfNeeded()
        let fitting = view.fittingSize
        let contentSize = NSSize(width: max(480, fitting.width + 40), height: fitting.height + 40)
        let newFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))

        var frame = window.frame
        frame.origin.y += frame.height - newFrame.height
        frame.size = newFrame.size
        window.setFrame(frame, display: true, animate: animated && window.isVisible)
    }

    private func paneView(for pane: Pane) -> NSView {
        if let existing = paneViews[pane] { return existing }
        let view: NSView
        switch pane {
        case .general: view = makeGeneralPane()
        case .appearance: view = makeAppearancePane()
        case .updates: view = makeUpdatesPane()
        }
        paneViews[pane] = view
        return view
    }

    // MARK: - Panes

    private func makeGeneralPane() -> NSView {
        let welcome = checkbox(
            title: "Show the Welcome window when Lineage launches",
            isOn: UserDefaults.standard.bool(forKey: WelcomeWindowController.showOnLaunchDefaultsKey),
            action: #selector(toggleShowWelcome(_:))
        )
        let restore = checkbox(
            title: "Restore graph position and selection on relaunch",
            isOn: ViewPreferences.restoresWindowState,
            action: #selector(toggleRestoreState(_:))
        )
        let beep = checkbox(
            title: "Play a sound when arrow navigation hits the end of a chain",
            isOn: NavigationSoundPreference.isEnabled,
            action: #selector(toggleNavigationBeep(_:))
        )
        return form(rows: [
            labelled("Launch:", welcome),
            labelled("", restore),
            labelled("Navigation:", beep),
        ])
    }

    private func makeAppearancePane() -> NSView {
        let layoutPopUp = NSPopUpButton()
        for algorithm in GraphLayoutAlgorithm.allCases.sorted(by: { $0.segmentIndex < $1.segmentIndex }) {
            layoutPopUp.addItem(withTitle: algorithm.displayName)
            layoutPopUp.lastItem?.tag = algorithm.segmentIndex
        }
        layoutPopUp.selectItem(withTag: LayoutPreference.algorithm.segmentIndex)
        layoutPopUp.target = self
        layoutPopUp.action = #selector(changeDefaultLayout(_:))

        let coloringPopUp = NSPopUpButton()
        coloringPopUp.addItem(withTitle: "Resource kind")
        coloringPopUp.lastItem?.tag = NodeColoring.kind.rawValue
        coloringPopUp.addItem(withTitle: "Build time")
        coloringPopUp.lastItem?.tag = NodeColoring.buildTime.rawValue
        coloringPopUp.selectItem(withTag: ViewPreferences.coloringMode.rawValue)
        coloringPopUp.target = self
        coloringPopUp.action = #selector(changeDefaultColoring(_:))

        let inspector = checkbox(
            title: "Show the inspector in new windows",
            isOn: ViewPreferences.inspectorVisible,
            action: #selector(toggleInspectorDefault(_:))
        )

        return form(rows: [
            labelled("Layout:", layoutPopUp),
            labelled("Color nodes by:", coloringPopUp),
            labelled("Inspector:", inspector),
        ])
    }

    private func makeUpdatesPane() -> NSView {
        let auto = checkbox(
            title: "Automatically check for updates",
            isOn: updateCoordinator?.isAutoCheckEnabled ?? false,
            action: #selector(toggleAutoUpdates(_:))
        )

        let checkNow = NSButton(title: "Check Now", target: self, action: #selector(checkForUpdatesNow(_:)))
        checkNow.bezelStyle = .rounded

        let version = UpdateCoordinator.currentVersionString() ?? "unknown"
        let versionLabel = NSTextField(labelWithString: "Lineage \(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.isSelectable = true

        return form(rows: [
            labelled("Updates:", auto),
            labelled("", checkNow),
            labelled("", versionLabel),
        ])
    }

    // MARK: - Pane building blocks

    private func checkbox(title: String, isOn: Bool, action: Selector) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: action)
        button.state = isOn ? .on : .off
        return button
    }

    private func labelled(_ label: String, _ control: NSView) -> (NSTextField, NSView) {
        let field = NSTextField(labelWithString: label)
        field.alignment = .right
        field.font = NSFont.systemFont(ofSize: 13)
        field.textColor = .labelColor
        return (field, control)
    }

    /// Right-aligned label column + left-aligned control column, the standard
    /// macOS settings form shape.
    private func form(rows: [(NSTextField, NSView)]) -> NSView {
        let grid = NSGridView(views: rows.map { [$0.0, $0.1] })
        grid.rowSpacing = 10
        grid.columnSpacing = 10
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .leading
        grid.rowAlignment = .firstBaseline
        grid.translatesAutoresizingMaskIntoConstraints = false
        return grid
    }

    // MARK: - Actions

    @objc private func toggleShowWelcome(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: WelcomeWindowController.showOnLaunchDefaultsKey)
    }

    @objc private func toggleRestoreState(_ sender: NSButton) {
        ViewPreferences.restoresWindowState = sender.state == .on
    }

    @objc private func toggleNavigationBeep(_ sender: NSButton) {
        NavigationSoundPreference.isEnabled = sender.state == .on
    }

    @objc private func changeDefaultLayout(_ sender: NSPopUpButton) {
        LayoutPreference.algorithm = GraphLayoutAlgorithm(segmentIndex: sender.selectedTag())
    }

    @objc private func changeDefaultColoring(_ sender: NSPopUpButton) {
        ViewPreferences.coloringMode = NodeColoring(rawValue: sender.selectedTag()) ?? .kind
    }

    @objc private func toggleInspectorDefault(_ sender: NSButton) {
        ViewPreferences.inspectorVisible = sender.state == .on
    }

    @objc private func toggleAutoUpdates(_ sender: NSButton) {
        updateCoordinator?.setAutoCheckEnabled(sender.state == .on)
    }

    @objc private func checkForUpdatesNow(_ sender: Any?) {
        updateCoordinator?.checkManually()
    }
}
