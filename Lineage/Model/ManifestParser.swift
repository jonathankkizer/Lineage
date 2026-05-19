import Foundation

enum ManifestParser {

    nonisolated static func parse(data: Data) throws -> Manifest {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Manifest.self, from: data)
        } catch let error as DecodingError {
            throw ManifestParserError(underlying: error)
        }
    }
}

struct ManifestParserError: LocalizedError {
    let underlying: DecodingError

    var errorDescription: String? {
        switch underlying {
        case .typeMismatch(_, let ctx),
             .valueNotFound(_, let ctx),
             .keyNotFound(_, let ctx),
             .dataCorrupted(let ctx):
            let path = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return "Failed to parse manifest at \(path): \(ctx.debugDescription)"
        @unknown default:
            return "Failed to parse manifest: \(underlying.localizedDescription)"
        }
    }
}
