import AppKit

@main
enum AppMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var documentController: DbtDocumentController?
    private var welcomeWindowController: WelcomeWindowController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        documentController = DbtDocumentController()
        NSApp.mainMenu = AppMenu.build()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // State restoration runs asynchronously during launch; documents that
        // come back via restoration aren't necessarily present in
        // `NSDocumentController.shared.documents` by the time this method
        // fires. Wait a beat, then show the welcome window if still empty.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            if NSDocumentController.shared.documents.isEmpty {
                showWelcomeIfAppropriate()
            }
        }
    }

    // We don't have an "untitled document" concept — every Lineage document is
    // a user-picked folder. Returning false here lets us drive the no-doc
    // launch path from applicationDidFinishLaunching above, without AppKit
    // also trying to create an untitled doc.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, NSDocumentController.shared.documents.isEmpty {
            // No visible windows, no open documents: show the welcome window
            // regardless of the "show on launch" preference — the user has
            // explicitly poked the Dock icon expecting something to happen.
            presentWelcomeWindow()
        }
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Welcome window

    private func showWelcomeIfAppropriate() {
        guard UserDefaults.standard.bool(forKey: WelcomeWindowController.showOnLaunchDefaultsKey) else { return }
        presentWelcomeWindow()
    }

    func presentWelcomeWindow() {
        if welcomeWindowController == nil {
            welcomeWindowController = WelcomeWindowController()
        }
        welcomeWindowController?.reloadRecents()
        welcomeWindowController?.showWindow(nil)
        welcomeWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc func openDemoProject(_ sender: Any?) {
        DemoProjectLocator.openDemo()
    }

    @objc func showWelcomeWindow(_ sender: Any?) {
        presentWelcomeWindow()
    }

    @objc func openReleasesPage(_ sender: Any?) {
        guard let url = URL(string: "https://github.com/jonathankkizer/Lineage/releases") else { return }
        NSWorkspace.shared.open(url)
    }
}
