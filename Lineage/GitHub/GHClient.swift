import Foundation

/// Typed wrapper around the `gh` CLI. Every call is a `Process` invocation that
/// returns parsed JSON. We intentionally shell out instead of talking to the
/// GitHub REST API directly so the user's existing `gh auth login` does all of
/// our auth + token storage. Trade-off: the gh binary must be installed and on
/// disk; we discover it by probing well-known install paths and then falling
/// back to a login-interactive shell `command -v gh`.
actor GHClient {

    static let shared = GHClient()

    private var cachedPath: String?

    // MARK: - Discovery

    enum DiscoveryError: Error, LocalizedError {
        case notFound

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "The GitHub CLI (gh) was not found. Install it with `brew install gh`, then try again."
            }
        }
    }

    enum AuthError: Error, LocalizedError {
        case notAuthenticated
        case ghFailed(stderr: String, code: Int32)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "GitHub CLI is installed but not signed in. Run `gh auth login` in Terminal, then try again."
            case .ghFailed(let stderr, let code):
                let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                return "gh exited with code \(code).\n\(trimmed)"
            }
        }
    }

    /// Resolves the absolute path to `gh`, caching the result. Tries well-known
    /// Homebrew locations first, then a login-interactive shell so users with
    /// custom PATH setups still work.
    func ghPath() async throws -> String {
        if let cachedPath { return cachedPath }

        let fm = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/gh",
            "/usr/local/bin/gh",
            "/usr/bin/gh",
            (NSHomeDirectory() as NSString).appendingPathComponent(".local/bin/gh"),
        ]
        for candidate in candidates where fm.isExecutableFile(atPath: candidate) {
            cachedPath = candidate
            return candidate
        }

        if let viaShell = await loginShellLookup(), fm.isExecutableFile(atPath: viaShell) {
            cachedPath = viaShell
            return viaShell
        }

        throw DiscoveryError.notFound
    }

    private func loginShellLookup() async -> String? {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let result = try? await runRaw(executable: shell, args: ["-ilc", "command -v gh"], envOverlay: [:])
        guard let result, result.exitCode == 0 else { return nil }
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }

    // MARK: - Status

    struct AuthStatus: Sendable {
        let isAuthenticated: Bool
        let username: String?
        let host: String?
        /// Raw stderr (gh prints status info to stderr) — useful for displaying
        /// the full account list when there's more than one host.
        let raw: String
    }

    func authStatus() async throws -> AuthStatus {
        let result = try await run(args: ["auth", "status"], allowNonZero: true)
        let combined = result.stdout + "\n" + result.stderr

        if result.exitCode != 0 {
            return AuthStatus(isAuthenticated: false, username: nil, host: nil, raw: combined)
        }

        let username = Self.parseUsername(from: combined)
        let host = Self.parseHost(from: combined)
        return AuthStatus(isAuthenticated: true, username: username, host: host, raw: combined)
    }

    private static func parseUsername(from text: String) -> String? {
        // gh prints lines like:
        //   "Logged in to github.com account jonathankkizer (keyring)"
        //   "✓ Logged in to github.com as jonathankkizer (...)"
        for line in text.split(whereSeparator: \.isNewline) {
            let s = String(line)
            if let r = s.range(of: " account ") {
                let rest = s[r.upperBound...]
                let token = rest.split(whereSeparator: { $0 == " " || $0 == "(" }).first
                if let token { return String(token) }
            }
            if let r = s.range(of: " as ") {
                let rest = s[r.upperBound...]
                let token = rest.split(whereSeparator: { $0 == " " || $0 == "(" }).first
                if let token { return String(token) }
            }
        }
        return nil
    }

    private static func parseHost(from text: String) -> String? {
        for line in text.split(whereSeparator: \.isNewline) {
            let s = String(line)
            if let r = s.range(of: "Logged in to ") {
                let rest = s[r.upperBound...]
                let token = rest.split(whereSeparator: { $0 == " " }).first
                if let token { return String(token) }
            }
        }
        return nil
    }

    // MARK: - Repos

    struct Repo: Decodable, Sendable, Hashable {
        let nameWithOwner: String
        let description: String?
        let isPrivate: Bool

        var owner: String {
            nameWithOwner.split(separator: "/", maxSplits: 1).first.map(String.init) ?? ""
        }
    }

    /// Returns every repo the authenticated user can access — their own plus
    /// any org they belong to and any repo they're a collaborator on. We
    /// deliberately use the REST API instead of `gh repo list`, which only
    /// surfaces the authenticated user's own repos. Repos are returned sorted
    /// by owner (user first, then orgs alphabetically), then by name.
    ///
    /// Note on SAML-protected orgs: if the user's gh token isn't authorized
    /// for SSO on a given org, that org's repos won't appear here even though
    /// the user is technically a member. They need to visit
    /// `https://github.com/orgs/<org>/sso` to grant authorization.
    func repositories() async throws -> [Repo] {
        let result = try await run(args: [
            "api",
            "--paginate",
            "/user/repos?per_page=100&affiliation=owner,collaborator,organization_member&sort=full_name",
            "--jq", "[.[] | {nameWithOwner: .full_name, description, isPrivate: .private}]",
        ])
        let chunks = splitJSONArrays(result.stdout)
        var all: [Repo] = []
        var seen: Set<String> = []
        for chunk in chunks {
            let part = try decode([Repo].self, from: chunk)
            for repo in part where !seen.contains(repo.nameWithOwner) {
                all.append(repo)
                seen.insert(repo.nameWithOwner)
            }
        }
        let user = try? await currentUsername()
        return all.sorted { lhs, rhs in
            // Authenticated user's own repos first, then orgs alphabetical.
            if lhs.owner == user, rhs.owner != user { return true }
            if rhs.owner == user, lhs.owner != user { return false }
            if lhs.owner != rhs.owner { return lhs.owner.localizedCaseInsensitiveCompare(rhs.owner) == .orderedAscending }
            return lhs.nameWithOwner.localizedCaseInsensitiveCompare(rhs.nameWithOwner) == .orderedAscending
        }
    }

    /// Cached "who am I" lookup so we can sort the user's own repos to the top.
    private var cachedUsername: String?
    private func currentUsername() async throws -> String {
        if let cachedUsername { return cachedUsername }
        let result = try await run(args: ["api", "user", "--jq", ".login"])
        let name = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        cachedUsername = name
        return name
    }

    // MARK: - Workflows

    struct Workflow: Decodable, Sendable, Hashable {
        let id: Int
        let name: String
        let path: String
        let state: String

        var fileName: String {
            (path as NSString).lastPathComponent
        }
    }

    func workflows(repo: String) async throws -> [Workflow] {
        let result = try await run(args: [
            "api",
            "repos/\(repo)/actions/workflows",
            "--jq", ".workflows",
        ])
        return try decode([Workflow].self, from: result.stdout)
    }

    // MARK: - Branches

    struct Branch: Decodable, Sendable, Hashable {
        let name: String
    }

    func branches(repo: String) async throws -> [Branch] {
        let result = try await run(args: [
            "api",
            "--paginate",
            "repos/\(repo)/branches",
            "--jq", "[.[] | {name: .name}]",
        ])
        // --paginate prints multiple JSON arrays concatenated; merge them.
        let chunks = splitJSONArrays(result.stdout)
        var all: [Branch] = []
        for chunk in chunks {
            let part = try decode([Branch].self, from: chunk)
            all.append(contentsOf: part)
        }
        return all
    }

    private func splitJSONArrays(_ raw: String) -> [String] {
        // Each --paginate page produces one top-level JSON array on its own
        // line(s). Walk the bracket depth to split.
        var chunks: [String] = []
        var current = ""
        var depth = 0
        for ch in raw {
            current.append(ch)
            if ch == "[" { depth += 1 }
            if ch == "]" {
                depth -= 1
                if depth == 0 {
                    chunks.append(current)
                    current = ""
                }
            }
        }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { chunks.append(trimmed) }
        return chunks
    }

    // MARK: - Runs

    struct WorkflowRun: Decodable, Sendable, Hashable {
        let databaseId: Int
        let displayTitle: String?
        let headBranch: String?
        let event: String?
        let status: String
        let conclusion: String?
        let createdAt: String?
        let number: Int?

        enum CodingKeys: String, CodingKey {
            case databaseId
            case displayTitle
            case headBranch
            case event
            case status
            case conclusion
            case createdAt
            case number
        }
    }

    func latestSuccessfulRun(repo: String, workflowFileName: String, branch: String) async throws -> WorkflowRun? {
        let result = try await run(args: [
            "run", "list",
            "--repo", repo,
            "--workflow", workflowFileName,
            "--branch", branch,
            "--status", "success",
            "--limit", "1",
            "--json", "databaseId,displayTitle,headBranch,event,status,conclusion,createdAt,number",
        ])
        let runs = try decode([WorkflowRun].self, from: result.stdout)
        return runs.first
    }

    // MARK: - Artifacts

    struct Artifact: Decodable, Sendable, Hashable {
        let id: Int
        let name: String
        let sizeInBytes: Int?
        let expired: Bool?
    }

    /// Lists artifacts for a given run via the REST API. `gh run view --json artifacts`
    /// is also possible but the REST shape is more reliable across gh versions.
    func artifacts(repo: String, runID: Int) async throws -> [Artifact] {
        let result = try await run(args: [
            "api",
            "repos/\(repo)/actions/runs/\(runID)/artifacts",
            "--jq", ".artifacts",
        ])
        return try decode([Artifact].self, from: result.stdout)
    }

    /// Downloads `name` from a run into `destination` (which is created if it
    /// doesn't exist). Returns the directory `gh` wrote into. `gh run download`
    /// unzips the artifact and places its contents inside `destination/<name>/`
    /// (one folder per artifact). We just return that subfolder.
    func downloadArtifact(repo: String, runID: Int, name: String, into destination: URL) async throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        _ = try await run(args: [
            "run", "download", String(runID),
            "--repo", repo,
            "--name", name,
            "--dir", destination.path,
        ])

        // gh extracts into destination/<artifact-name>/ — but in practice with a
        // single `--name`, it extracts the contents directly into destination.
        // Probe both layouts.
        let nested = destination.appendingPathComponent(name, isDirectory: true)
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: nested.path, isDirectory: &isDir), isDir.boolValue {
            return nested
        }
        return destination
    }

    // MARK: - Process plumbing

    struct ProcessResult: Sendable {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// Runs `gh <args>` and returns the combined result. Throws on non-zero
    /// unless `allowNonZero` is true. Translates auth failures into typed errors.
    private func run(args: [String], allowNonZero: Bool = false) async throws -> ProcessResult {
        let path = try await ghPath()
        let result = try await runRaw(executable: path, args: args, envOverlay: ghEnv())
        if !allowNonZero, result.exitCode != 0 {
            if Self.looksUnauthenticated(stderr: result.stderr) {
                throw AuthError.notAuthenticated
            }
            throw AuthError.ghFailed(stderr: result.stderr, code: result.exitCode)
        }
        return result
    }

    private static func looksUnauthenticated(stderr: String) -> Bool {
        let lower = stderr.lowercased()
        return lower.contains("not logged into")
            || lower.contains("authentication required")
            || lower.contains("could not determine if user is authenticated")
            || lower.contains("gh auth login")
    }

    /// Environment overlay that nudges `gh` to behave well as a subprocess:
    /// no color codes, no pager, no update notifications cluttering stderr.
    private func ghEnv() -> [String: String] {
        [
            "NO_COLOR": "1",
            "CLICOLOR": "0",
            "GH_NO_UPDATE_NOTIFIER": "1",
            "GH_PAGER": "cat",
            "PAGER": "cat",
        ]
    }

    private func runRaw(executable: String, args: [String], envOverlay: [String: String]) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ProcessResult, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = args

                var env = ProcessInfo.processInfo.environment
                for (k, v) in envOverlay { env[k] = v }
                process.environment = env

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let result = ProcessResult(
                    stdout: String(data: outData, encoding: .utf8) ?? "",
                    stderr: String(data: errData, encoding: .utf8) ?? "",
                    exitCode: process.terminationStatus
                )
                continuation.resume(returning: result)
            }
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "GHClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode gh output as UTF-8."])
        }
        return try JSONDecoder().decode(type, from: data)
    }
}
