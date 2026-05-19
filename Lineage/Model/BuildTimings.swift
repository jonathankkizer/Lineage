import Foundation

nonisolated struct BuildTimings: Sendable {
    let executionTime: [NodeID: TimeInterval]
    let percentile: [NodeID: Double]
    let colorScore: [NodeID: Double]
    let generatedAt: String?

    static let empty = BuildTimings(executionTime: [:], percentile: [:], colorScore: [:], generatedAt: nil)

    var isEmpty: Bool { executionTime.isEmpty }

    nonisolated static func build(from runResults: RunResults) -> BuildTimings {
        var times: [NodeID: TimeInterval] = [:]
        times.reserveCapacity(runResults.results.count)

        for r in runResults.results {
            guard let t = r.executionTime, t.isFinite, t >= 0 else { continue }
            let status = r.status?.lowercased() ?? ""
            if status == "skipped" { continue }
            times[NodeID(r.uniqueId)] = t
        }

        guard !times.isEmpty else {
            return BuildTimings(executionTime: [:], percentile: [:], colorScore: [:], generatedAt: runResults.generatedAt)
        }

        let sorted = times.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            return lhs.key.rawValue < rhs.key.rawValue
        }
        let denom = max(1, sorted.count - 1)
        var pct: [NodeID: Double] = [:]
        pct.reserveCapacity(sorted.count)
        for (i, entry) in sorted.enumerated() {
            pct[entry.key] = Double(i) / Double(denom)
        }

        let logs = times.mapValues { log1p($0) }
        let logMin = logs.values.min() ?? 0
        let logMax = logs.values.max() ?? 0
        let logSpan = logMax - logMin
        var score: [NodeID: Double] = [:]
        score.reserveCapacity(times.count)
        if logSpan > 0 {
            for (id, l) in logs {
                score[id] = (l - logMin) / logSpan
            }
        } else {
            for id in times.keys { score[id] = 0 }
        }

        return BuildTimings(executionTime: times, percentile: pct, colorScore: score, generatedAt: runResults.generatedAt)
    }
}
