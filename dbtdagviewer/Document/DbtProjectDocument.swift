import AppKit
import UniformTypeIdentifiers

final class DbtProjectDocument: NSDocument {

    nonisolated override class var readableTypes: [String] {
        [UTType.folder.identifier]
    }

    nonisolated override class var autosavesInPlace: Bool { false }

    @MainActor private(set) var manifestURL: URL?
    @MainActor private(set) var projectRootURL: URL?
    @MainActor private(set) var fullGraph: Graph?
    @MainActor private(set) var graph: Graph?
    @MainActor private(set) var graphLayout: GraphLayout?
    @MainActor private(set) var loadError: Error?
    @MainActor private(set) var nodeFilter: NodeFilter = .default

    @MainActor private var loadingTask: Task<Void, Never>?
    @MainActor private var refilterTask: Task<Void, Never>?
    @MainActor private var pendingFilterWork: DispatchWorkItem?
    @MainActor private static let filterDebounce: TimeInterval = 0.25

    nonisolated override func read(from url: URL, ofType typeName: String) throws {
        let fm = FileManager.default
        let projectFile = url.appendingPathComponent("dbt_project.yml")
        let manifestInTarget = url.appendingPathComponent("target/manifest.json")
        let manifestDirect = url.appendingPathComponent("manifest.json")

        let resolved: (project: URL, manifest: URL)
        if fm.fileExists(atPath: projectFile.path), fm.fileExists(atPath: manifestInTarget.path) {
            resolved = (url, manifestInTarget)
        } else if fm.fileExists(atPath: manifestDirect.path) {
            resolved = (url.deletingLastPathComponent(), manifestDirect)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: "No dbt manifest found.",
                NSLocalizedRecoverySuggestionErrorKey: "Pick a dbt project root that contains dbt_project.yml + target/manifest.json, or the target/ folder directly.",
            ])
        }

        MainActor.assumeIsolated {
            self.projectRootURL = resolved.project
            self.manifestURL = resolved.manifest
        }
    }

    override func makeWindowControllers() {
        let controller = ProjectWindowController(document: self)
        addWindowController(controller)
        loadingTask?.cancel()
        loadingTask = Task { [weak self] in
            await self?.loadInBackground()
        }
    }

    override var displayName: String! {
        get {
            if let root = projectRootURL { return root.lastPathComponent }
            return super.displayName
        }
        set { super.displayName = newValue }
    }

    @MainActor
    func loadInBackground() async {
        guard let manifestURL else { return }
        guard let controller = windowControllers.first as? ProjectWindowController else { return }

        controller.showLoading()

        do {
            let manifest = try await Self.parse(url: manifestURL)
            let full = await Self.buildGraph(from: manifest)
            let filtered = await Self.applyFilter(graph: full, filter: nodeFilter)
            let layout = await Self.computeLayout(graph: filtered)
            self.fullGraph = full
            self.graph = filtered
            self.graphLayout = layout
            self.loadError = nil
            controller.documentDidFinishLoading()
        } catch {
            self.loadError = error
            controller.documentDidFailLoading(error)
        }
    }

    @MainActor
    func reload() {
        loadingTask?.cancel()
        refilterTask?.cancel()
        loadingTask = Task { [weak self] in
            await self?.loadInBackground()
        }
    }

    @MainActor
    func updateFilter(_ newFilter: NodeFilter) {
        guard newFilter != nodeFilter else { return }
        nodeFilter = newFilter

        pendingFilterWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.commitPendingFilter()
        }
        pendingFilterWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.filterDebounce, execute: work)
    }

    @MainActor
    private func commitPendingFilter() {
        pendingFilterWork = nil
        let appliedFilter = nodeFilter
        guard let full = fullGraph else { return }
        guard let controller = windowControllers.first as? ProjectWindowController else { return }

        refilterTask?.cancel()
        refilterTask = Task { [weak self] in
            guard let self else { return }
            await controller.willRefilter(filter: appliedFilter)
            let filtered = await Self.applyFilter(graph: full, filter: appliedFilter)
            let layout = await Self.computeLayout(graph: filtered)
            if Task.isCancelled { return }
            self.graph = filtered
            self.graphLayout = layout
            controller.didRefilter()
        }
    }

    private static func parse(url: URL) async throws -> Manifest {
        try await Task.detached(priority: .userInitiated) {
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer {
                if needsRelease { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            return try ManifestParser.parse(data: data)
        }.value
    }

    private static func buildGraph(from manifest: Manifest) async -> Graph {
        await Task.detached(priority: .userInitiated) {
            Graph.build(from: manifest)
        }.value
    }

    private static func applyFilter(graph: Graph, filter: NodeFilter) async -> Graph {
        await Task.detached(priority: .userInitiated) {
            graph.filtered(by: filter)
        }.value
    }

    private static func computeLayout(graph: Graph) async -> GraphLayout {
        await Task.detached(priority: .userInitiated) {
            LayeredLayout.compute(graph: graph)
        }.value
    }
}
