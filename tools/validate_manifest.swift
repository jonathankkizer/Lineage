import Foundation

// Mirrors Lineage/Model/Manifest.swift + ManifestParser.swift, verbatim.
// Standalone validator: compile and run against a manifest.json to confirm
// it decodes through Lineage's narrow Codable surface.

struct Manifest: Decodable {
    let metadata: Metadata
    let nodes: [String: ManifestNode]
    let sources: [String: ManifestSource]
    let exposures: [String: ManifestExposure]
    let parentMap: [String: [String]]
    let childMap: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case metadata, nodes, sources, exposures
        case parentMap = "parent_map"
        case childMap = "child_map"
    }
}

struct Metadata: Decodable {
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

struct ManifestNode: Decodable {
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
        case database, schema, alias
        case originalFilePath = "original_file_path"
        case path, description, tags, config
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

struct ManifestSource: Decodable {
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
        case database, schema, identifier
        case originalFilePath = "original_file_path"
        case description, tags, columns
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

struct ManifestExposure: Decodable {
    let uniqueId: String
    let name: String
    let type: String?
    let description: String?
    let originalFilePath: String?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case name, type, description
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

struct NodeConfig: Decodable {
    let materialized: String?
    let enabled: Bool?
}

struct DependsOn: Decodable {
    let nodes: [String]
    let macros: [String]?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nodes = (try? c.decode([String].self, forKey: .nodes)) ?? []
        macros = try? c.decode([String].self, forKey: .macros)
    }

    enum CodingKeys: String, CodingKey { case nodes, macros }
}

struct ManifestColumn: Decodable {
    let name: String
    let description: String?
    let dataType: String?

    enum CodingKeys: String, CodingKey {
        case name, description
        case dataType = "data_type"
    }
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("Usage: validate_manifest <manifest.json>\n".data(using: .utf8)!)
    exit(2)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
do {
    let data = try Data(contentsOf: url)
    let manifest = try JSONDecoder().decode(Manifest.self, from: data)
    let modelCount = manifest.nodes.values.filter { $0.resourceType == "model" }.count
    let seedCount = manifest.nodes.values.filter { $0.resourceType == "seed" }.count
    print("OK")
    print("  project:   \(manifest.metadata.projectName ?? "?")")
    print("  adapter:   \(manifest.metadata.adapterType ?? "?")")
    print("  models:    \(modelCount)")
    print("  seeds:     \(seedCount)")
    print("  sources:   \(manifest.sources.count)")
    print("  exposures: \(manifest.exposures.count)")
    let edges = manifest.parentMap.values.reduce(0) { $0 + $1.count }
    print("  edges:     \(edges)")

    let validIds = Set(manifest.nodes.keys)
        .union(manifest.sources.keys)
        .union(manifest.exposures.keys)
    var dangling: [(String, String)] = []
    for (child, parents) in manifest.parentMap {
        for p in parents where !validIds.contains(p) {
            dangling.append((child, p))
        }
    }
    if !dangling.isEmpty {
        print("DANGLING EDGES:")
        for (child, p) in dangling { print("  \(child) -> \(p)") }
        exit(1)
    }
    print("  no dangling edges")
} catch {
    FileHandle.standardError.write("DECODE FAILED: \(error)\n".data(using: .utf8)!)
    exit(1)
}
