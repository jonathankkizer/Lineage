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

    func applicationWillFinishLaunching(_ notification: Notification) {
        documentController = DbtDocumentController()
        NSApp.mainMenu = AppMenu.build()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    // No-document launch path: AppKit calls this only after restoration and any
    // Finder-supplied open events have run, so there's no race with the 0.4s
    // delay we used to need.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSDocumentController.shared.openDocument(nil)
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, NSDocumentController.shared.documents.isEmpty {
            NSDocumentController.shared.openDocument(nil)
        }
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @objc func openReleasesPage(_ sender: Any?) {
        guard let url = URL(string: "https://github.com/jonathankkizer/Lineage/releases") else { return }
        NSWorkspace.shared.open(url)
    }
}
