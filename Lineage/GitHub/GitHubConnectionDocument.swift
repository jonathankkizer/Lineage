import AppKit
import UniformTypeIdentifiers

/// Document type backing a `.lineagegh` connection file. The file itself is a
/// small JSON descriptor; on load, we fetch the latest matching workflow run's
/// artifact via the `gh` CLI, unzip it into the app cache, and let the standard
/// `DbtProjectDocument` parse/layout pipeline take it from there.
final class GitHubConnectionDocument: DbtProjectDocument {

    nonisolated static let typeIdentifier = "com.kizersolutions.lineage.connection"

    nonisolated override class var readableTypes: [String] {
        [typeIdentifier]
    }

    nonisolated override class var writableTypes: [String] {
        [typeIdentifier]
    }

    nonisolated override class var autosavesInPlace: Bool { false }

    @MainActor private(set) var connection: GitHubConnection?
    @MainActor private(set) var lastRun: GHClient.WorkflowRun?

    @MainActor private var refreshTimer: Timer?

    // MARK: - Read / write

    nonisolated override func read(from url: URL, ofType typeName: String) throws {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(GitHubConnection.self, from: data)
        MainActor.assumeIsolated {
            self.connection = decoded
        }
    }

    nonisolated override func data(ofType typeName: String) throws -> Data {
        let snapshot = MainActor.assumeIsolated { self.connection }
        guard let snapshot else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [
                NSLocalizedDescriptionKey: "No connection to save.",
            ])
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    override var displayName: String! {
        get {
            if let connection { return connection.displayName }
            return super.displayName
        }
        set { super.displayName = newValue }
    }

    // MARK: - Load

    @MainActor
    override func prepareForLoad() async throws {
        guard let connection else {
            throw NSError(domain: "GitHubConnectionDocument", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Connection details are missing.",
            ])
        }

        let client = GHClient.shared

        guard let run = try await client.latestSuccessfulRun(
            repo: connection.repo,
            workflowFileName: connection.workflowFileName,
            branch: connection.branch
        ) else {
            throw NSError(domain: "GitHubConnectionDocument", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "No successful runs found for \(connection.workflowFileName) on \(connection.branch).",
            ])
        }
        self.lastRun = run

        let cacheRoot = try Self.cacheDirectory(for: connection, runID: run.databaseId)
        let manifestCandidate = Self.findManifest(in: cacheRoot)

        let resolvedManifest: URL
        if let manifestCandidate {
            resolvedManifest = manifestCandidate
        } else {
            // Some dbt-on-Actions workflows suffix the artifact name with a
            // per-run value (run id, run number, commit sha) to work around
            // upload-artifact@v4's duplicate-name rule. The literal name stored
            // at connect time won't match newer runs, so resolve against the
            // run's actual artifact list before downloading.
            let available = (try? await client.artifacts(
                repo: connection.repo,
                runID: run.databaseId
            ))?.filter { $0.expired != true } ?? []

            guard let resolvedName = Self.resolveArtifactName(
                desired: connection.artifactName,
                available: available
            ) else {
                let names = available.map(\.name).joined(separator: ", ")
                throw NSError(domain: "GitHubConnectionDocument", code: 4, userInfo: [
                    NSLocalizedDescriptionKey: "Couldn't find an artifact matching \"\(connection.artifactName)\" in run \(run.databaseId).",
                    NSLocalizedRecoverySuggestionErrorKey: names.isEmpty
                        ? "The run produced no artifacts."
                        : "Available artifacts: \(names).",
                ])
            }

            let downloadedRoot: URL
            do {
                downloadedRoot = try await client.downloadArtifact(
                    repo: connection.repo,
                    runID: run.databaseId,
                    name: resolvedName,
                    into: cacheRoot
                )
            } catch {
                // The REST list said this name existed but `gh run download`
                // disagreed — surface what we tried so the failure is
                // actionable rather than just "gh exited with code 1".
                let names = available.map(\.name).joined(separator: ", ")
                let suffix = names.isEmpty
                    ? "The run produced no artifacts via REST."
                    : "Resolved \"\(connection.artifactName)\" → \"\(resolvedName)\". Run \(run.databaseId) artifacts (REST): \(names)."
                let underlying = (error as NSError).localizedDescription
                throw NSError(domain: "GitHubConnectionDocument", code: 5, userInfo: [
                    NSLocalizedDescriptionKey: "Couldn't download artifact from run \(run.databaseId).",
                    NSLocalizedRecoverySuggestionErrorKey: "\(underlying)\n\n\(suffix)",
                ])
            }
            guard let manifest = Self.findManifest(in: downloadedRoot) else {
                throw NSError(domain: "GitHubConnectionDocument", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Downloaded artifact \"\(resolvedName)\" did not contain a manifest.json.",
                ])
            }
            resolvedManifest = manifest
        }

        self.manifestURL = resolvedManifest
        self.projectRootURL = resolvedManifest.deletingLastPathComponent().deletingLastPathComponent()

        var updated = connection
        updated.lastSyncedRunID = run.databaseId
        updated.lastSyncedAt = Date()
        self.connection = updated
        self.updateChangeCount(.changeDone)
    }

    // MARK: - Cache

    private static func cacheDirectory(for connection: GitHubConnection, runID: Int) throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appCache = base
            .appendingPathComponent("com.kizersolutions.lineage", isDirectory: true)
            .appendingPathComponent("github", isDirectory: true)
            .appendingPathComponent(connection.repo.replacingOccurrences(of: "/", with: "__"), isDirectory: true)
            .appendingPathComponent("run-\(runID)", isDirectory: true)
        try fm.createDirectory(at: appCache, withIntermediateDirectories: true)
        return appCache
    }

    /// Picks the right artifact from a run's list, given the name the user
    /// originally chose. Order of attempts:
    ///   1. Exact name match — the simple case.
    ///   2. Strip a trailing per-run suffix (digits of any length, or a hex
    ///      string of 7+ chars for commit SHAs) from both the stored name and
    ///      each candidate, then compare stems. Catches `${{ github.run_id }}`,
    ///      `${{ github.run_number }}`, and `${{ github.sha }}` patterns.
    ///   3. If the desired stem is a hyphen-prefix of some candidate, use it.
    ///      Handles the case where the stored name has no suffix at all but
    ///      the workflow has since been changed to add one (or vice versa).
    ///   4. If the run has exactly one artifact, use it.
    /// Returns `nil` if nothing reasonable matches.
    nonisolated static func resolveArtifactName(desired: String, available: [GHClient.Artifact]) -> String? {
        if available.contains(where: { $0.name == desired }) { return desired }

        let desiredStem = stripTrailingRunSuffix(desired)
        if let match = available.first(where: { stripTrailingRunSuffix($0.name) == desiredStem }) {
            return match.name
        }

        if let match = available.first(where: { $0.name.hasPrefix(desiredStem + "-") }) {
            return match.name
        }

        if available.count == 1 { return available[0].name }
        return nil
    }

    /// Strips ONE trailing per-run suffix. Two patterns covered:
    ///   - `-<digits>` of any length: `github.run_id` (10+), `github.run_number`
    ///     (small), `github.run_attempt`.
    ///   - `-<hex>` of length 7+: full or abbreviated commit SHA.
    /// Single-strip (not iterative) so date fragments like `-2025-12-01` only
    /// drop the last segment; they don't collapse all the way to the prefix.
    nonisolated static func stripTrailingRunSuffix(_ name: String) -> String {
        if let range = name.range(of: #"-[0-9]+$"#, options: .regularExpression) {
            return String(name[..<range.lowerBound])
        }
        if let range = name.range(of: #"-[0-9a-f]{7,}$"#, options: .regularExpression) {
            return String(name[..<range.lowerBound])
        }
        return name
    }

    /// `target/manifest.json` is the canonical location; some users name the
    /// artifact `target` (folder contents) so the manifest is directly in
    /// `root/manifest.json`. Probe both.
    private static func findManifest(in directory: URL) -> URL? {
        let fm = FileManager.default
        let direct = directory.appendingPathComponent("manifest.json")
        if fm.fileExists(atPath: direct.path) { return direct }
        let inTarget = directory.appendingPathComponent("target/manifest.json")
        if fm.fileExists(atPath: inTarget.path) { return inTarget }
        // Fall back: scan one level deep — gh sometimes wraps the contents in
        // an artifact-named subdirectory.
        if let children = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey]) {
            for child in children {
                if (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    let nested = child.appendingPathComponent("manifest.json")
                    if fm.fileExists(atPath: nested.path) { return nested }
                    let nestedTarget = child.appendingPathComponent("target/manifest.json")
                    if fm.fileExists(atPath: nestedTarget.path) { return nestedTarget }
                }
            }
        }
        return nil
    }
}
