import Foundation

nonisolated struct Manifest: Decodable, Sendable {
    let metadata: Metadata
    let nodes: [String: ManifestNode]
    let sources: [String: ManifestSource]
    let exposures: [String: ManifestExposure]
    let parentMap: [String: [String]]
    let childMap: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case metadata
        case nodes
        case sources
        case exposures
        case parentMap = "parent_map"
        case childMap = "child_map"
    }
}

nonisolated struct Metadata: Decodable, Sendable {
    let projectName: String?
    let adapterType: String?
    let dbtVersion: String?
    let generatedAt: String?
    let invocationId: String?

    enum CodingKeys: String, CodingKey {
        case projectName = "project_name"
        case adapterType = "adapter_type"
        case dbtVersion = "dbt_version"
        case generatedAt = "generated_at"
        case invocationId = "invocation_id"
    }
}

nonisolated struct ManifestNode: Decodable, Sendable {
    let uniqueId: String
    let name: String
    let resourceType: String
    let packageName: String?
    let database: String?
    let schema: String?
    let alias: String?
    let originalFilePath: String?
    let path: String?
    let description: String?
    let tags: [String]
    let config: NodeConfig?
    let dependsOn: DependsOn?
    let columns: [String: ManifestColumn]?

    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case name
        case resourceType = "resource_type"
        case packageName = "package_name"
        case database
        case schema
        case alias
        case originalFilePath = "original_file_path"
        case path
        case description
        case tags
        case config
        case dependsOn = "depends_on"
        case columns
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try c.decode(String.self, forKey: .uniqueId)
        name = try c.decode(String.self, forKey: .name)
        resourceType = try c.decode(String.self, forKey: .resourceType)
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName)
        database = try c.decodeIfPresent(String.self, forKey: .database)
        schema = try c.decodeIfPresent(String.self, forKey: .schema)
        alias = try c.decodeIfPresent(String.self, forKey: .alias)
        originalFilePath = try c.decodeIfPresent(String.self, forKey: .originalFilePath)
        path = try c.decodeIfPresent(String.self, forKey: .path)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        config = try c.decodeIfPresent(NodeConfig.self, forKey: .config)
        dependsOn = try c.decodeIfPresent(DependsOn.self, forKey: .dependsOn)
        columns = try c.decodeIfPresent([String: ManifestColumn].self, forKey: .columns)
    }
}

nonisolated struct ManifestSource: Decodable, Sendable {
    let uniqueId: String
    let name: String
    let sourceName: String
    let database: String?
    let schema: String?
    let identifier: String?
    let originalFilePath: String?
    let description: String?
    let tags: [String]
    let columns: [String: ManifestColumn]?

    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case name
        case sourceName = "source_name"
        case database
        case schema
        case identifier
        case originalFilePath = "original_file_path"
        case description
        case tags
        case columns
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try c.decode(String.self, forKey: .uniqueId)
        name = try c.decode(String.self, forKey: .name)
        sourceName = try c.decode(String.self, forKey: .sourceName)
        database = try c.decodeIfPresent(String.self, forKey: .database)
        schema = try c.decodeIfPresent(String.self, forKey: .schema)
        identifier = try c.decodeIfPresent(String.self, forKey: .identifier)
        originalFilePath = try c.decodeIfPresent(String.self, forKey: .originalFilePath)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        columns = try c.decodeIfPresent([String: ManifestColumn].self, forKey: .columns)
    }
}

nonisolated struct ManifestExposure: Decodable, Sendable {
    let uniqueId: String
    let name: String
    let type: String?
    let description: String?
    let originalFilePath: String?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case name
        case type
        case description
        case originalFilePath = "original_file_path"
        case tags
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uniqueId = try c.decode(String.self, forKey: .uniqueId)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        originalFilePath = try c.decodeIfPresent(String.self, forKey: .originalFilePath)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
    }
}

nonisolated struct NodeConfig: Decodable, Sendable {
    let materialized: String?
    let enabled: Bool?

    enum CodingKeys: String, CodingKey {
        case materialized
        case enabled
    }
}

nonisolated struct DependsOn: Decodable, Sendable {
    let nodes: [String]
    let macros: [String]?

    enum CodingKeys: String, CodingKey {
        case nodes
        case macros
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nodes = (try? c.decode([String].self, forKey: .nodes)) ?? []
        macros = try? c.decode([String].self, forKey: .macros)
    }
}

nonisolated struct ManifestColumn: Decodable, Sendable {
    let name: String
    let description: String?
    let dataType: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case dataType = "data_type"
    }
}
