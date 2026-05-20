import Foundation

nonisolated struct GitHubRelease: Sendable, Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case draft
        case prerelease
        case publishedAt = "published_at"
    }
}

nonisolated enum UpdateStatus: Sendable {
    case upToDate(current: SemanticVersion)
    case updateAvailable(latest: SemanticVersion, current: SemanticVersion, release: GitHubRelease)
}

nonisolated enum UpdateCheckError: Error, LocalizedError {
    case noCurrentVersion
    case malformedRemoteVersion(String)
    case http(Int)
    case transport(any Error)
    case decoding(any Error)

    var errorDescription: String? {
        switch self {
        case .noCurrentVersion:
            return "Could not determine the current app version."
        case .malformedRemoteVersion(let tag):
            return "The latest release tag (\"\(tag)\") isn't a recognizable version number."
        case .http(let code):
            return "GitHub returned HTTP \(code) while checking for updates."
        case .transport(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .decoding:
            return "GitHub's response couldn't be parsed."
        }
    }
}

nonisolated struct UpdateChecker: Sendable {

    let owner: String
    let repo: String
    let session: URLSession

    init(owner: String, repo: String, session: URLSession = .shared) {
        self.owner = owner
        self.repo = repo
        self.session = session
    }

    func checkForLatest(currentVersionString: String) async throws -> UpdateStatus {
        guard let current = SemanticVersion(currentVersionString) else {
            throw UpdateCheckError.noCurrentVersion
        }

        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Lineage-macOS/\(currentVersionString)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UpdateCheckError.transport(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw UpdateCheckError.http(http.statusCode)
        }

        let release: GitHubRelease
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            release = try decoder.decode(GitHubRelease.self, from: data)
        } catch {
            throw UpdateCheckError.decoding(error)
        }

        if release.draft || release.prerelease {
            return .upToDate(current: current)
        }

        guard let latest = SemanticVersion(release.tagName) else {
            throw UpdateCheckError.malformedRemoteVersion(release.tagName)
        }

        if latest > current {
            return .updateAvailable(latest: latest, current: current, release: release)
        } else {
            return .upToDate(current: current)
        }
    }
}
