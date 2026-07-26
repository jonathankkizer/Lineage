import AppKit
import UniformTypeIdentifiers

@MainActor
final class DbtDocumentController: NSDocumentController {

    override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
        openPanel.canChooseDirectories = true
        // Connections are a registered document type we own, so ⌘O has to be
        // able to reach them — folders alone left them openable only from Finder
        // and Open Recent.
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [GitHubConnectionDocument.contentType]
        openPanel.allowsOtherFileTypes = false
        openPanel.allowsMultipleSelection = true
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.message = "Choose a dbt project root, its target/ folder, or a Lineage connection."
        openPanel.prompt = "Open"
        return super.runModalOpenPanel(openPanel, forTypes: types)
    }

    override func typeForContents(of url: URL) throws -> String {
        if url.pathExtension.lowercased() == "lineagegh" {
            return GitHubConnectionDocument.typeIdentifier
        }
        return UTType.folder.identifier
    }
}
