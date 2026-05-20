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

        // State restoration runs asynchronously during launch; documents that
        // come back via restoration aren't necessarily present in
        // `NSDocumentController.shared.documents` by the time this method
        // fires. Wait a beat, then show the Open panel if still empty.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            if NSDocumentController.shared.documents.isEmpty {
                NSDocumentController.shared.openDocument(nil)
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
