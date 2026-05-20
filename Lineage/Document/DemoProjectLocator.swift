import AppKit

/// Resolves the URL of the bundled demo dbt project and hands it to
/// NSDocumentController. The demo lives at
/// `Lineage.app/Contents/Resources/DemoProject/`, copied in by a Run Script
/// build phase from `fixtures/demo-coffee-shop/` in the repo.
@MainActor
enum DemoProjectLocator {

    static var bundledURL: URL? {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let candidate = resources.appendingPathComponent("DemoProject", isDirectory: true)
        let manifest = candidate.appendingPathComponent("target/manifest.json")
        return FileManager.default.fileExists(atPath: manifest.path) ? candidate : nil
    }

    static func openDemo() {
        guard let url = bundledURL else {
            presentMissingAlert()
            return
        }
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
    }

    private static func presentMissingAlert() {
        let alert = NSAlert()
        alert.messageText = "Demo project not found"
        alert.informativeText = """
            Lineage couldn't find the bundled demo project inside the app's resources. \
            If you're running a development build, make sure the "Copy Demo Project" \
            build phase ran successfully.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
