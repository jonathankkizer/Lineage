import AppKit

enum NodeColoring: Int, Sendable {
    case kind
    case buildTime
}

enum RendererColors {

    static func kindColor(for kind: ResourceKind) -> NSColor {
        switch kind {
        case .model:         return .systemBlue
        case .source:        return .systemGreen
        case .seed:          return .systemBrown
        case .test:          return .systemPurple
        case .snapshot:      return .systemTeal
        case .exposure:      return .systemOrange
        case .metric:        return .systemPink
        case .semanticModel: return .systemIndigo
        case .savedQuery:    return .systemYellow
        case .unitTest:      return .systemPurple
        case .unknown:       return .systemGray
        }
    }

    // Inspector and other surfaces still use the saturated "marker" fill API.
    static func fill(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(0.85)
    }

    static func border(for fill: NSColor) -> NSColor {
        fill.blended(withFraction: 0.4, of: .black) ?? .black
    }

    static func border(for kind: ResourceKind) -> NSColor {
        border(for: fill(for: kind))
    }

    // Node chip styling (used by the graph renderer).
    private static let chipFillAlpha: CGFloat = 0.14
    private static let chipBorderAlpha: CGFloat = 0.70
    private static let untimedFillAlpha: CGFloat = 0.06
    private static let untimedBorderAlpha: CGFloat = 0.25

    static func nodeChipFill(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(chipFillAlpha)
    }

    static func nodeChipBorder(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(chipBorderAlpha)
    }

    static func nodeChipText(for kind: ResourceKind) -> NSColor {
        // Slightly darkened version of the kind color for legible text on the light fill.
        kindColor(for: kind).blended(withFraction: 0.30, of: .black) ?? .labelColor
    }

    static func buildTimeColor(score: Double) -> NSColor {
        let p = max(0, min(1, score))
        let stops: [(Double, NSColor)] = [
            (0.00, .systemGreen),
            (0.50, .systemYellow),
            (0.80, .systemOrange),
            (1.00, .systemRed),
        ]
        for i in 0..<(stops.count - 1) {
            let (p0, c0) = stops[i]
            let (p1, c1) = stops[i + 1]
            if p <= p1 {
                let span = p1 - p0
                let t = span > 0 ? CGFloat((p - p0) / span) : 0
                return c0.blended(withFraction: t, of: c1) ?? c1
            }
        }
        return stops.last!.1
    }

    static func buildTimeChipFill(score: Double) -> NSColor {
        buildTimeColor(score: score).withAlphaComponent(0.22)
    }

    static func buildTimeChipBorder(score: Double) -> NSColor {
        buildTimeColor(score: score).withAlphaComponent(0.85)
    }

    static func untimedChipFill(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(untimedFillAlpha)
    }

    static func untimedChipBorder(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(untimedBorderAlpha)
    }

    // Kept for compatibility with prior call sites; resolved via the new chip API.
    static func buildTimeFill(score: Double) -> NSColor {
        buildTimeChipFill(score: score)
    }

    static func untimedFill(for kind: ResourceKind) -> NSColor {
        untimedChipFill(for: kind)
    }

    static var selection: NSColor { .controlAccentColor }
    static var hover: NSColor { NSColor.controlAccentColor.withAlphaComponent(0.5) }

    static var edge: NSColor {
        NSColor.labelColor.withAlphaComponent(0.12)
    }

    static var edgeFaded: NSColor {
        NSColor.labelColor.withAlphaComponent(0.04)
    }

    static var edgeHighlighted: NSColor {
        NSColor.controlAccentColor.withAlphaComponent(0.95)
    }

    static var edgeUpstream: NSColor {
        NSColor.systemBlue.withAlphaComponent(0.85)
    }

    static var edgeDownstream: NSColor {
        NSColor.systemOrange.withAlphaComponent(0.85)
    }

    static func labelText(for kind: ResourceKind) -> NSColor {
        nodeChipText(for: kind)
    }

    static var labelText: NSColor { .labelColor }
    static var background: NSColor { NSColor.windowBackgroundColor }
}
