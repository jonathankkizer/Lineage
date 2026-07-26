import AppKit
import UniformTypeIdentifiers

/// Shared Finder-drop plumbing for the surfaces that accept a project: the
/// graph canvas and the Welcome window. Mirrors what `DbtProjectDocument.read`
/// will accept, so a drop that highlights is a drop that opens.
@MainActor
enum ProjectDropSupport {

    static let acceptedTypes: [NSPasteboard.PasteboardType] = [.fileURL]

    /// URLs on the pasteboard that Lineage can actually open. Empty means the
    /// drag should be rejected outright rather than accepted and then failed.
    static func openableURLs(in pasteboard: NSPasteboard) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
        ]
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
        return urls.filter(isOpenable)
    }

    static func isOpenable(_ url: URL) -> Bool {
        if url.pathExtension.lowercased() == "lineagegh" { return true }

        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        // A project root (dbt_project.yml + target/manifest.json) or a bare
        // target/ directory — the same two shapes read(from:ofType:) resolves.
        let hasProjectManifest = fm.fileExists(atPath: url.appendingPathComponent("dbt_project.yml").path)
            && fm.fileExists(atPath: url.appendingPathComponent("target/manifest.json").path)
        let hasBareManifest = fm.fileExists(atPath: url.appendingPathComponent("manifest.json").path)
        return hasProjectManifest || hasBareManifest
    }

    /// Opens each dropped URL as its own document window, matching what
    /// dropping several folders on the Dock icon does.
    static func open(_ urls: [URL]) {
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                guard let error else { return }
                NSAlert(error: error).runModal()
            }
        }
    }

    static func operation(for pasteboard: NSPasteboard) -> NSDragOperation {
        openableURLs(in: pasteboard).isEmpty ? [] : .generic
    }
}
