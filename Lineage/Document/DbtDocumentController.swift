import AppKit
import UniformTypeIdentifiers

@MainActor
final class DbtDocumentController: NSDocumentController {

    override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.message = "Choose a dbt project root (or its target/ folder)."
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
