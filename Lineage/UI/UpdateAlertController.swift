import AppKit

@MainActor
enum UpdateUserChoice {
    case viewRelease
    case skipVersion
    case later
}

@MainActor
enum UpdateConsentChoice {
    case enable
    case decline
}

@MainActor
struct UpdateAlertController {

    func presentConsentPrompt() -> UpdateConsentChoice {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Check for Updates Automatically?"
        alert.informativeText = "Lineage can check GitHub once a week and let you know when a new version is available. No data leaves your Mac apart from the request to the public GitHub Releases API.\n\nYou can change this any time under the Help menu."
        alert.addButton(withTitle: "Check Automatically")
        alert.addButton(withTitle: "Not Now")

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .enable
        default: return .decline
        }
    }

    func presentUpdateAvailable(
        latest: SemanticVersion,
        current: SemanticVersion,
        release: GitHubRelease,
        offerSkip: Bool
    ) -> UpdateUserChoice {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "A new version of Lineage is available."
        alert.informativeText = "Lineage \(latest) is available — you have \(current). Release notes are shown below."

        if let body = release.body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alert.accessoryView = Self.releaseNotesView(body: body)
        }

        alert.addButton(withTitle: "View Release on GitHub\u{2026}")
        alert.addButton(withTitle: "Later")
        if offerSkip {
            alert.addButton(withTitle: "Skip This Version")
        }

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .viewRelease
        case .alertThirdButtonReturn where offerSkip: return .skipVersion
        default: return .later
        }
    }

    func presentUpToDate(current: SemanticVersion) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "You're up to date."
        alert.informativeText = "Lineage \(current) is the latest version available."
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
    }

    func presentError(_ error: any Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn't check for updates."
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
    }

    private static func releaseNotesView(body: String) -> NSView {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 460, height: 220))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.autohidesScrollers = true

        let textView = NSTextView(frame: scroll.contentView.bounds)
        textView.autoresizingMask = [.width]
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 6, height: 6)

        let attributed = renderedReleaseNotes(body: body)
        textView.textStorage?.setAttributedString(attributed)

        scroll.documentView = textView
        return scroll
    }

    private static func renderedReleaseNotes(body: String) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let parsed = try? AttributedString(markdown: body, options: options) {
            let ns = NSMutableAttributedString(parsed)
            ns.addAttributes(
                [
                    .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                    .foregroundColor: NSColor.textColor,
                ],
                range: NSRange(location: 0, length: ns.length)
            )
            return ns
        }
        return NSAttributedString(
            string: body,
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.textColor,
            ]
        )
    }
}
