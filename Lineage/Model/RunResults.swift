import Foundation

nonisolated struct RunResults: Decodable, Sendable {
    let results: [RunResult]
    let elapsedTime: Double?
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case results
        case elapsedTime = "elapsed_time"
        case metadata
    }

    enum MetadataKeys: String, CodingKey {
        case generatedAt = "generated_at"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        results = (try? c.decode([RunResult].self, forKey: .results)) ?? []
        elapsedTime = try? c.decode(Double.self, forKey: .elapsedTime)
        if let meta = try? c.nestedContainer(keyedBy: MetadataKeys.self, forKey: .metadata) {
            generatedAt = try? meta.decode(String.self, forKey: .generatedAt)
        } else {
            generatedAt = nil
        }
    }
}

nonisolated struct RunResult: Decodable, Sendable {
    let uniqueId: String
    let status: String?
    let executionTime: Double?

    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case status
        case executionTime = "execution_time"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try c.decode(String.self, forKey: .uniqueId)
        status = try? c.decode(String.self, forKey: .status)
        executionTime = try? c.decode(Double.self, forKey: .executionTime)
    }
}

enum RunResultsParser {

    nonisolated static func parse(data: Data) throws -> RunResults {
        try JSONDecoder().decode(RunResults.self, from: data)
    }
}
