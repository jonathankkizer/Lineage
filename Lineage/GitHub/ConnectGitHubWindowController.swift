import AppKit

/// "Connect to GitHub Actions" launcher. Walks the user through picking a
/// repo / workflow / branch / artifact, then writes a `.lineagegh` connection
/// file into Application Support and opens it as a regular document.
@MainActor
final class ConnectGitHubWindowController: NSWindowController, NSWindowDelegate {

    // MARK: - State

    private enum AuthDisplayState {
        case checking
        case ghMissing
        case notAuthed(reason: String)
        case authed(username: String, host: String)
        case error(String)
    }

    private var authState: AuthDisplayState = .checking
    private var repos: [GHClient.Repo] = []
    private var workflows: [GHClient.Workflow] = []
    private var branches: [GHClient.Branch] = []
    private var artifactSuggestions: [String] = ["target"]
    private var latestRun: GHClient.WorkflowRun?
    private var artifactsForLatestRun: [GHClient.Artifact] = []

    private var refreshInterval: GitHubConnection.RefreshInterval = .manual

    var onClose: (() -> Void)?

    private var authTask: Task<Void, Never>?
    private var reposTask: Task<Void, Never>?
    private var workflowsTask: Task<Void, Never>?
    private var branchesTask: Task<Void, Never>?
    private var runTask: Task<Void, Never>?

    // MARK: - Views

    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let statusHelpButton = NSButton(title: "", target: nil, action: nil)

    private let repoPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let workflowPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let branchPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let artifactCombo = NSComboBox()
    private let refreshPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let preflightLabel = NSTextField(labelWithString: " ")

    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    private let connectButton = NSButton(title: "Connect", target: nil, action: nil)

    // MARK: - Init

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Connect to GitHub Actions"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self

        configureContent()
        configureActions()

        applyAuthDisplayState()
        beginAuthCheck()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Layout

    private func configureContent() {
        guard let content = window?.contentView else { return }

        let statusRow = makeStatusRow()
        let pickerGrid = makePickerGrid()
        let preflightRow = makePreflightRow()
        let buttonRow = makeButtonRow()

        let stack = NSStackView(views: [statusRow, makeSeparator(), pickerGrid, preflightRow, NSView(), buttonRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 22, bottom: 18, right: 22)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -44),
            pickerGrid.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -44),
            preflightRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -44),
            buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -44),
        ])
    }

    private func makeStatusRow() -> NSView {
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.imageScaling = .scaleProportionallyDown
        statusIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        statusLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 3
        statusLabel.usesSingleLineMode = false
        statusLabel.preferredMaxLayoutWidth = 380

        statusHelpButton.target = self
        statusHelpButton.action = #selector(statusHelpClicked(_:))
        statusHelpButton.bezelStyle = .rounded
        statusHelpButton.controlSize = .small
        statusHelpButton.isHidden = true

        let stack = NSStackView(views: [statusIcon, statusLabel, NSView(), statusHelpButton])
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8

        NSLayoutConstraint.activate([
            statusIcon.widthAnchor.constraint(equalToConstant: 18),
            statusIcon.heightAnchor.constraint(equalToConstant: 18),
        ])
        return stack
    }

    private func makePickerGrid() -> NSView {
        let labels = ["Repository:", "Workflow:", "Branch:", "Artifact:", "Refresh:"]
        let controls: [NSView] = [repoPopup, workflowPopup, branchPopup, artifactCombo, refreshPopup]

        for popup in [repoPopup, workflowPopup, branchPopup, refreshPopup] {
            popup.translatesAutoresizingMaskIntoConstraints = false
            popup.target = self
        }
        artifactCombo.translatesAutoresizingMaskIntoConstraints = false
        artifactCombo.usesDataSource = false
        artifactCombo.completes = true
        artifactCombo.numberOfVisibleItems = 6
        artifactCombo.placeholderString = "target"
        artifactCombo.stringValue = "target"

        repoPopup.action = #selector(repoPopupChanged(_:))
        workflowPopup.action = #selector(workflowPopupChanged(_:))
        branchPopup.action = #selector(branchPopupChanged(_:))
        refreshPopup.action = #selector(refreshPopupChanged(_:))

        for value in GitHubConnection.RefreshInterval.allCases {
            refreshPopup.addItem(withTitle: value.displayName)
            refreshPopup.lastItem?.representedObject = value
        }

        var rows: [NSView] = []
        for (label, control) in zip(labels, controls) {
            let labelView = NSTextField(labelWithString: label)
            labelView.alignment = .right
            labelView.font = NSFont.systemFont(ofSize: 13, weight: .regular)
            labelView.translatesAutoresizingMaskIntoConstraints = false
            labelView.widthAnchor.constraint(equalToConstant: 100).isActive = true

            let row = NSStackView(views: [labelView, control])
            row.orientation = .horizontal
            row.alignment = .firstBaseline
            row.spacing = 10
            row.distribution = .fill
            rows.append(row)

            control.setContentHuggingPriority(.defaultLow, for: .horizontal)
            control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.distribution = .fill
        return stack
    }

    private func makePreflightRow() -> NSView {
        preflightLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        preflightLabel.textColor = .secondaryLabelColor
        preflightLabel.lineBreakMode = .byWordWrapping
        preflightLabel.maximumNumberOfLines = 2
        preflightLabel.usesSingleLineMode = false
        preflightLabel.preferredMaxLayoutWidth = 460
        let stack = NSStackView(views: [preflightLabel])
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        return stack
    }

    private func makeButtonRow() -> NSView {
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked(_:))
        cancelButton.keyEquivalent = "\u{1B}"

        connectButton.bezelStyle = .rounded
        connectButton.keyEquivalent = "\r"
        connectButton.target = self
        connectButton.action = #selector(connectClicked(_:))
        connectButton.isEnabled = false

        let stack = NSStackView(views: [NSView(), cancelButton, connectButton])
        stack.orientation = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 10
        return stack
    }

    private func makeSeparator() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return box
    }

    private func configureActions() {
        // already wired in makePickerGrid / makeButtonRow
    }

    // MARK: - Auth

    private func beginAuthCheck() {
        authState = .checking
        applyAuthDisplayState()

        authTask?.cancel()
        authTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await GHClient.shared.ghPath()
            } catch {
                self.authState = .ghMissing
                self.applyAuthDisplayState()
                return
            }
            do {
                let status = try await GHClient.shared.authStatus()
                if status.isAuthenticated {
                    self.authState = .authed(
                        username: status.username ?? "unknown",
                        host: status.host ?? "github.com"
                    )
                    self.applyAuthDisplayState()
                    self.beginReposLoad()
                } else {
                    self.authState = .notAuthed(reason: status.raw)
                    self.applyAuthDisplayState()
                }
            } catch {
                self.authState = .error((error as NSError).localizedDescription)
                self.applyAuthDisplayState()
            }
        }
    }

    private func applyAuthDisplayState() {
        switch authState {
        case .checking:
            statusIcon.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: nil)
            statusIcon.contentTintColor = .secondaryLabelColor
            statusLabel.stringValue = "Checking for the GitHub CLI…"
            statusHelpButton.isHidden = true
            setPickersEnabled(false)

        case .ghMissing:
            statusIcon.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
            statusIcon.contentTintColor = .systemOrange
            statusLabel.stringValue = "The GitHub CLI (gh) was not found. Install with Homebrew, then re-open this window."
            statusHelpButton.title = "Copy `brew install gh`"
            statusHelpButton.isHidden = false
            setPickersEnabled(false)

        case .notAuthed:
            statusIcon.image = NSImage(systemSymbolName: "person.crop.circle.badge.exclamationmark", accessibilityDescription: nil)
            statusIcon.contentTintColor = .systemOrange
            statusLabel.stringValue = "GitHub CLI is installed but not signed in. Run `gh auth login` in Terminal, then re-open this window."
            statusHelpButton.title = "Copy `gh auth login`"
            statusHelpButton.isHidden = false
            setPickersEnabled(false)

        case .authed(let username, let host):
            statusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            statusIcon.contentTintColor = .systemGreen
            statusLabel.stringValue = "Signed in as @\(username) on \(host)."
            statusHelpButton.isHidden = true
            setPickersEnabled(true)

        case .error(let message):
            statusIcon.image = NSImage(systemSymbolName: "xmark.octagon.fill", accessibilityDescription: nil)
            statusIcon.contentTintColor = .systemRed
            statusLabel.stringValue = message
            statusHelpButton.isHidden = true
            setPickersEnabled(false)
        }
        updateConnectEnabled()
    }

    @objc private func statusHelpClicked(_ sender: Any?) {
        switch authState {
        case .ghMissing:
            copyToPasteboard("brew install gh")
        case .notAuthed:
            copyToPasteboard("gh auth login")
        default:
            break
        }
    }

    private func copyToPasteboard(_ string: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
    }

    private func setPickersEnabled(_ enabled: Bool) {
        repoPopup.isEnabled = enabled
        workflowPopup.isEnabled = enabled && !workflows.isEmpty
        branchPopup.isEnabled = enabled && !branches.isEmpty
        artifactCombo.isEnabled = enabled
        refreshPopup.isEnabled = enabled
    }

    // MARK: - Data loading

    private func beginReposLoad() {
        repoPopup.removeAllItems()
        repoPopup.addItem(withTitle: "Loading…")
        repoPopup.isEnabled = false

        reposTask?.cancel()
        reposTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let repos = try await GHClient.shared.repositories()
                self.repos = repos
                self.populateRepoPopup()
            } catch {
                self.repoPopup.removeAllItems()
                self.repoPopup.addItem(withTitle: "Failed to load")
                self.preflightLabel.stringValue = (error as NSError).localizedDescription
            }
        }
    }

    private func populateRepoPopup() {
        repoPopup.removeAllItems()
        for repo in repos {
            repoPopup.addItem(withTitle: repo.nameWithOwner)
        }
        repoPopup.isEnabled = !repos.isEmpty
        if !repos.isEmpty {
            repoPopupChanged(repoPopup)
        }
    }

    @objc private func repoPopupChanged(_ sender: Any?) {
        guard let repo = currentRepo else { return }
        workflowPopup.removeAllItems()
        workflowPopup.addItem(withTitle: "Loading…")
        workflowPopup.isEnabled = false
        branchPopup.removeAllItems()
        branchPopup.addItem(withTitle: "Loading…")
        branchPopup.isEnabled = false
        latestRun = nil
        artifactsForLatestRun = []
        preflightLabel.stringValue = " "

        workflowsTask?.cancel()
        branchesTask?.cancel()
        runTask?.cancel()

        workflowsTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let list = try await GHClient.shared.workflows(repo: repo.nameWithOwner)
                self.workflows = list.filter { $0.state == "active" || $0.state == "enabled" }
                if self.workflows.isEmpty { self.workflows = list }
                self.populateWorkflowPopup()
            } catch {
                self.workflowPopup.removeAllItems()
                self.workflowPopup.addItem(withTitle: "None found")
            }
        }

        branchesTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let list = try await GHClient.shared.branches(repo: repo.nameWithOwner)
                self.branches = list
                self.populateBranchPopup()
            } catch {
                self.branchPopup.removeAllItems()
                self.branchPopup.addItem(withTitle: "None found")
            }
        }
        updateConnectEnabled()
    }

    private func populateWorkflowPopup() {
        workflowPopup.removeAllItems()
        for workflow in workflows {
            let title = "\(workflow.name)  —  \(workflow.fileName)"
            workflowPopup.addItem(withTitle: title)
            workflowPopup.lastItem?.representedObject = workflow
        }
        workflowPopup.isEnabled = !workflows.isEmpty
        if !workflows.isEmpty {
            workflowPopupChanged(workflowPopup)
        }
    }

    private func populateBranchPopup() {
        branchPopup.removeAllItems()
        let preferred = ["main", "master", "develop"]
        let names = branches.map(\.name)
        var ordered: [String] = []
        for name in preferred where names.contains(name) { ordered.append(name) }
        for name in names where !ordered.contains(name) { ordered.append(name) }
        for name in ordered {
            branchPopup.addItem(withTitle: name)
        }
        branchPopup.isEnabled = !ordered.isEmpty
        if !ordered.isEmpty {
            branchPopupChanged(branchPopup)
        }
    }

    @objc private func workflowPopupChanged(_ sender: Any?) {
        scheduleLatestRunLookup()
        updateConnectEnabled()
    }

    @objc private func branchPopupChanged(_ sender: Any?) {
        scheduleLatestRunLookup()
        updateConnectEnabled()
    }

    @objc private func refreshPopupChanged(_ sender: Any?) {
        if let selected = refreshPopup.selectedItem?.representedObject as? GitHubConnection.RefreshInterval {
            refreshInterval = selected
        }
    }

    private func scheduleLatestRunLookup() {
        guard let repo = currentRepo,
              let workflow = currentWorkflow,
              let branch = currentBranchName else { return }

        preflightLabel.stringValue = "Checking for the latest successful run…"
        runTask?.cancel()
        runTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let run = try await GHClient.shared.latestSuccessfulRun(
                    repo: repo.nameWithOwner,
                    workflowFileName: workflow.fileName,
                    branch: branch
                )
                self.latestRun = run
                if let run {
                    let artifacts = (try? await GHClient.shared.artifacts(repo: repo.nameWithOwner, runID: run.databaseId)) ?? []
                    self.artifactsForLatestRun = artifacts.filter { $0.expired != true }
                    self.populateArtifactSuggestions()
                    self.preflightLabel.stringValue = Self.preflightDescription(for: run, artifactCount: artifacts.count)
                } else {
                    self.preflightLabel.stringValue = "No successful runs yet for \(workflow.fileName) on \(branch)."
                }
                self.updateConnectEnabled()
            } catch {
                self.preflightLabel.stringValue = "Couldn't check runs: \((error as NSError).localizedDescription)"
            }
        }
    }

    private func populateArtifactSuggestions() {
        let names = artifactsForLatestRun.map(\.name)
        artifactCombo.removeAllItems()
        var inserted: Set<String> = []
        for name in names where !inserted.contains(name) {
            artifactCombo.addItem(withObjectValue: name)
            inserted.insert(name)
        }
        if !inserted.contains("target") {
            artifactCombo.addItem(withObjectValue: "target")
            inserted.insert("target")
        }
        if artifactCombo.stringValue.isEmpty {
            artifactCombo.stringValue = names.first ?? "target"
        }
    }

    private static func preflightDescription(for run: GHClient.WorkflowRun, artifactCount: Int) -> String {
        let title = run.displayTitle ?? "run \(run.databaseId)"
        let ago = relativeAgo(from: run.createdAt)
        let artifactPart: String
        switch artifactCount {
        case 0: artifactPart = "no artifacts"
        case 1: artifactPart = "1 artifact"
        default: artifactPart = "\(artifactCount) artifacts"
        }
        return "Last successful run: \(title)\(ago.map { " · \($0)" } ?? "") · \(artifactPart)."
    }

    private static func relativeAgo(from iso: String?) -> String? {
        guard let iso else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: iso) else { return nil }
        let interval = Date().timeIntervalSince(date)
        let formatterStyle = DateComponentsFormatter()
        formatterStyle.unitsStyle = .abbreviated
        formatterStyle.allowedUnits = [.year, .month, .day, .hour, .minute]
        formatterStyle.maximumUnitCount = 1
        return formatterStyle.string(from: interval).map { "\($0) ago" }
    }

    // MARK: - Selection helpers

    private var currentRepo: GHClient.Repo? {
        let index = repoPopup.indexOfSelectedItem
        guard index >= 0, index < repos.count else { return nil }
        return repos[index]
    }

    private var currentWorkflow: GHClient.Workflow? {
        workflowPopup.selectedItem?.representedObject as? GHClient.Workflow
    }

    private var currentBranchName: String? {
        let title = branchPopup.titleOfSelectedItem
        guard let title, !title.isEmpty, title != "Loading…", title != "None found" else { return nil }
        return title
    }

    private var currentArtifactName: String {
        let trimmed = artifactCombo.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "target" : trimmed
    }

    private func updateConnectEnabled() {
        let hasInputs = currentRepo != nil
            && currentWorkflow != nil
            && currentBranchName != nil
            && !currentArtifactName.isEmpty
        let authedAndReady: Bool
        switch authState {
        case .authed: authedAndReady = true
        default: authedAndReady = false
        }
        connectButton.isEnabled = hasInputs && authedAndReady
    }

    // MARK: - Connect / Cancel

    @objc private func connectClicked(_ sender: Any?) {
        guard let repo = currentRepo,
              let workflow = currentWorkflow,
              let branch = currentBranchName else { return }

        let connection = GitHubConnection(
            repo: repo.nameWithOwner,
            workflowFileName: workflow.fileName,
            branch: branch,
            artifactName: currentArtifactName,
            refreshInterval: refreshInterval,
            lastSyncedRunID: nil,
            lastSyncedAt: nil
        )

        let saveResult = writeConnectionFile(connection)
        switch saveResult {
        case .failure(let error):
            showError(error)
            return
        case .success(let url):
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { [weak self] _, _, error in
                if let error {
                    self?.showError(error)
                } else {
                    self?.close()
                }
            }
        }
    }

    @objc private func cancelClicked(_ sender: Any?) {
        close()
    }

    private func showError(_ error: Error) {
        guard let window else { return }
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window) { _ in }
    }

    private func writeConnectionFile(_ connection: GitHubConnection) -> Result<URL, Error> {
        do {
            let fm = FileManager.default
            let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dir = appSupport
                .appendingPathComponent("Lineage", isDirectory: true)
                .appendingPathComponent("Connections", isDirectory: true)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)

            let slug = (connection.repo + "-" + connection.branch)
                .replacingOccurrences(of: "/", with: "__")
                .replacingOccurrences(of: " ", with: "-")
            let url = dir.appendingPathComponent(slug).appendingPathExtension("lineagegh")

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(connection)
            try data.write(to: url, options: .atomic)
            return .success(url)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Window lifecycle

    func windowWillClose(_ notification: Notification) {
        authTask?.cancel()
        reposTask?.cancel()
        workflowsTask?.cancel()
        branchesTask?.cancel()
        runTask?.cancel()
        onClose?()
    }
}
