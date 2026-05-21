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
            let downloadedRoot = try await client.downloadArtifact(
                repo: connection.repo,
                runID: run.databaseId,
                name: connection.artifactName,
                into: cacheRoot
            )
            guard let manifest = Self.findManifest(in: downloadedRoot) else {
                throw NSError(domain: "GitHubConnectionDocument", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Downloaded artifact \"\(connection.artifactName)\" did not contain a manifest.json.",
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
