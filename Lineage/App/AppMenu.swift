import AppKit

@MainActor
enum AppMenu {

    static func build() -> NSMenu {
        let menu = NSMenu(title: "MainMenu")
        menu.addItem(applicationMenuItem())
        menu.addItem(fileMenuItem())
        menu.addItem(editMenuItem())
        menu.addItem(viewMenuItem())
        menu.addItem(navigateMenuItem())
        menu.addItem(windowMenuItem())
        menu.addItem(helpMenuItem())
        return menu
    }

    private static func navigateMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Navigate")
        let focus = menu.addItem(withTitle: "Focus on Selection", action: #selector(LineageActions.focusOnSelection(_:)), keyEquivalent: "\r")
        focus.keyEquivalentModifierMask = [.command]
        menu.addItem(withTitle: "Show Overview", action: #selector(LineageActions.clearFocus(_:)), keyEquivalent: "\u{1B}")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Back", action: #selector(LineageActions.focusBack(_:)), keyEquivalent: "[")
        menu.addItem(withTitle: "Forward", action: #selector(LineageActions.focusForward(_:)), keyEquivalent: "]")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Expand Focus", action: #selector(LineageActions.expandFocus(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Contract Focus", action: #selector(LineageActions.contractFocus(_:)), keyEquivalent: "")

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func applicationMenuItem() -> NSMenuItem {
        let appName = ProcessInfo.processInfo.processName
        let menu = NSMenu()
        menu.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        // Update checking lives here rather than in Help — the App menu is where
        // Mac users look for it.
        menu.addItem(withTitle: "Check for Updates\u{2026}", action: #selector(LineageActions.checkForUpdates(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings\u{2026}", action: #selector(LineageActions.showSettings(_:)), keyEquivalent: ",")
        menu.addItem(.separator())
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        NSApp.servicesMenu = servicesMenu
        services.submenu = servicesMenu
        menu.addItem(services)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(hideOthers)
        menu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func fileMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "Open\u{2026}", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        menu.addItem(withTitle: "Open Demo Project", action: #selector(LineageActions.openDemoProject(_:)), keyEquivalent: "")

        // No key equivalent: Shift-Cmd-G is Find Previous everywhere on the Mac,
        // and connecting a repo is a once-per-project action that doesn't need
        // to trap it.
        menu.addItem(withTitle: "Connect to GitHub Actions\u{2026}", action: #selector(LineageActions.connectToGitHub(_:)), keyEquivalent: "")

        let openRecent = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        let openRecentMenu = NSMenu(title: "Open Recent")
        openRecentMenu.addItem(withTitle: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
        openRecent.submenu = openRecentMenu
        menu.addItem(openRecent)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Reload Project", action: #selector(LineageActions.reloadProject(_:)), keyEquivalent: "r")
        menu.addItem(.separator())

        let exportItem = NSMenuItem(title: "Export", action: nil, keyEquivalent: "")
        let exportMenu = NSMenu(title: "Export")
        exportMenu.addItem(withTitle: "Graph as PDF\u{2026}", action: #selector(LineageActions.exportGraphAsPDF(_:)), keyEquivalent: "")
        exportMenu.addItem(withTitle: "Graph as PNG\u{2026}", action: #selector(LineageActions.exportGraphAsPNG(_:)), keyEquivalent: "")
        exportItem.submenu = exportMenu
        menu.addItem(exportItem)

        menu.addItem(.separator())
        // Page Setup conventionally takes Shift-Cmd-P, but Show Critical Path
        // already owns it and is a far more frequent action here. Page Setup is
        // rare enough to live without a key equivalent.
        menu.addItem(withTitle: "Page Setup\u{2026}", action: #selector(LineageActions.runPageLayout(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Print\u{2026}", action: #selector(LineageActions.printGraph(_:)), keyEquivalent: "p")

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func editMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Edit")
        // undo:/redo: are framework selectors dispatched through the responder chain
        // (NSDocument's undoManager picks them up). They have no Swift declaration,
        // so string-form Selector is correct here.
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(redo)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())

        let findItem = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
        let findMenu = NSMenu(title: "Find")
        findMenu.addItem(withTitle: "Find\u{2026}", action: #selector(LineageActions.focusFilterField(_:)), keyEquivalent: "f")
        findMenu.addItem(withTitle: "Find Next", action: #selector(LineageActions.findNext(_:)), keyEquivalent: "g")
        let findPrevious = NSMenuItem(title: "Find Previous", action: #selector(LineageActions.findPrevious(_:)), keyEquivalent: "g")
        findPrevious.keyEquivalentModifierMask = [.command, .shift]
        findMenu.addItem(findPrevious)
        findItem.submenu = findMenu
        menu.addItem(findItem)

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func viewMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "View")
        menu.addItem(withTitle: "Zoom In", action: #selector(LineageActions.zoomInGraph(_:)), keyEquivalent: "=")
        menu.addItem(withTitle: "Zoom Out", action: #selector(LineageActions.zoomOutGraph(_:)), keyEquivalent: "-")
        menu.addItem(withTitle: "Actual Size", action: #selector(LineageActions.resetZoomGraph(_:)), keyEquivalent: "0")
        let zoomFit = menu.addItem(withTitle: "Zoom to Fit", action: #selector(LineageActions.zoomToFitGraph(_:)), keyEquivalent: "0")
        zoomFit.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        let toggleInspector = NSMenuItem(title: "Toggle Inspector", action: #selector(LineageActions.toggleInspector(_:)), keyEquivalent: "i")
        toggleInspector.keyEquivalentModifierMask = [.command]
        menu.addItem(toggleInspector)

        menu.addItem(withTitle: "Hide Edges", action: #selector(LineageActions.toggleShowAllEdges(_:)), keyEquivalent: "")
        menu.addItem(.separator())

        let criticalPath = NSMenuItem(title: "Show Critical Path", action: #selector(LineageActions.toggleCriticalPath(_:)), keyEquivalent: "p")
        criticalPath.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(criticalPath)
        menu.addItem(.separator())

        let layoutItem = NSMenuItem(title: "Layout", action: nil, keyEquivalent: "")
        let layoutMenu = NSMenu(title: "Layout")
        for algorithm in GraphLayoutAlgorithm.allCases.sorted(by: { $0.segmentIndex < $1.segmentIndex }) {
            let entry = NSMenuItem(title: algorithm.displayName, action: #selector(LineageActions.selectLayout(_:)), keyEquivalent: "")
            entry.tag = algorithm.segmentIndex
            layoutMenu.addItem(entry)
        }
        layoutItem.submenu = layoutMenu
        menu.addItem(layoutItem)
        menu.addItem(.separator())

        let showItem = NSMenuItem(title: "Show", action: nil, keyEquivalent: "")
        let showMenu = NSMenu(title: "Show")
        showMenu.addItem(withTitle: "Tests", action: #selector(LineageActions.toggleShowTests(_:)), keyEquivalent: "")
        showMenu.addItem(withTitle: "Sources", action: #selector(LineageActions.toggleShowSources(_:)), keyEquivalent: "")
        showMenu.addItem(withTitle: "Orphan Sources", action: #selector(LineageActions.toggleShowOrphanSources(_:)), keyEquivalent: "")
        showMenu.addItem(withTitle: "Seeds", action: #selector(LineageActions.toggleShowSeeds(_:)), keyEquivalent: "")
        showMenu.addItem(withTitle: "Exposures", action: #selector(LineageActions.toggleShowExposures(_:)), keyEquivalent: "")
        showMenu.addItem(.separator())
        showMenu.addItem(withTitle: "Reset to Defaults", action: #selector(LineageActions.resetFilter(_:)), keyEquivalent: "")
        showItem.submenu = showMenu
        menu.addItem(showItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Customize Toolbar\u{2026}", action: #selector(LineageActions.customizeToolbar(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        let fullScreen = menu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.command, .control]

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func windowMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Welcome to Lineage", action: #selector(LineageActions.showWelcomeWindow(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = menu

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func helpMenuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Help")
        let help = menu.addItem(withTitle: "Lineage Help", action: #selector(LineageActions.openHelp(_:)), keyEquivalent: "?")
        help.keyEquivalentModifierMask = [.command]
        menu.addItem(withTitle: "Keyboard Shortcuts", action: #selector(LineageActions.openKeyboardShortcuts(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Release Notes", action: #selector(LineageActions.openReleasesPage(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Report an Issue\u{2026}", action: #selector(LineageActions.reportIssue(_:)), keyEquivalent: "")
        NSApp.helpMenu = menu

        let item = NSMenuItem()
        item.submenu = menu
        return item
    }
}
