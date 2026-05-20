import Foundation

nonisolated struct SemanticVersion: Sendable, Equatable, Comparable, CustomStringConvertible {

    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: [PrereleaseIdentifier]

    enum PrereleaseIdentifier: Sendable, Equatable, Comparable {
        case numeric(Int)
        case alphanumeric(String)

        static func < (lhs: PrereleaseIdentifier, rhs: PrereleaseIdentifier) -> Bool {
            switch (lhs, rhs) {
            case let (.numeric(a), .numeric(b)): return a < b
            case (.numeric, .alphanumeric): return true
            case (.alphanumeric, .numeric): return false
            case let (.alphanumeric(a), .alphanumeric(b)): return a < b
            }
        }
    }

    init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.first == "v" || text.first == "V" { text.removeFirst() }
        guard !text.isEmpty else { return nil }

        let coreAndPre = text.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let core = coreAndPre[0].split(separator: ".", omittingEmptySubsequences: false)
        guard core.count >= 1, core.count <= 3 else { return nil }

        let nums = core.map { Int($0) }
        guard nums.allSatisfy({ $0 != nil && $0! >= 0 }) else { return nil }
        self.major = nums[0]!
        self.minor = nums.count > 1 ? nums[1]! : 0
        self.patch = nums.count > 2 ? nums[2]! : 0

        if coreAndPre.count == 2 {
            let parts = coreAndPre[1].split(separator: ".", omittingEmptySubsequences: false)
            guard !parts.isEmpty, parts.allSatisfy({ !$0.isEmpty }) else { return nil }
            self.prerelease = parts.map { part in
                if let n = Int(part), n >= 0 {
                    return .numeric(n)
                } else {
                    return .alphanumeric(String(part))
                }
            }
        } else {
            self.prerelease = []
        }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        // Per SemVer 2.0.0: a pre-release version has lower precedence than a normal version.
        switch (lhs.prerelease.isEmpty, rhs.prerelease.isEmpty) {
        case (true, true): return false
        case (true, false): return false
        case (false, true): return true
        case (false, false):
            for (l, r) in zip(lhs.prerelease, rhs.prerelease) where l != r {
                return l < r
            }
            return lhs.prerelease.count < rhs.prerelease.count
        }
    }

    var description: String {
        let core = "\(major).\(minor).\(patch)"
        guard !prerelease.isEmpty else { return core }
        let pre = prerelease.map { id -> String in
            switch id {
            case .numeric(let n): return String(n)
            case .alphanumeric(let s): return s
            }
        }.joined(separator: ".")
        return "\(core)-\(pre)"
    }
}
