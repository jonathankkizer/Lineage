import AppKit

enum NodeColoring: Int, Sendable {
    case kind
    case buildTime
}

enum RendererColors {

    static func fill(for kind: ResourceKind) -> NSColor {
        switch kind {
        case .model:         return NSColor.systemBlue.withAlphaComponent(0.85)
        case .source:        return NSColor.systemGreen.withAlphaComponent(0.85)
        case .seed:          return NSColor.systemBrown.withAlphaComponent(0.85)
        case .test:          return NSColor.systemPurple.withAlphaComponent(0.60)
        case .snapshot:      return NSColor.systemTeal.withAlphaComponent(0.85)
        case .exposure:      return NSColor.systemOrange.withAlphaComponent(0.85)
        case .metric:        return NSColor.systemPink.withAlphaComponent(0.85)
        case .semanticModel: return NSColor.systemIndigo.withAlphaComponent(0.85)
        case .savedQuery:    return NSColor.systemYellow.withAlphaComponent(0.85)
        case .unitTest:      return NSColor.systemPurple.withAlphaComponent(0.40)
        case .unknown:       return NSColor.systemGray.withAlphaComponent(0.70)
        }
    }

    static func border(for fill: NSColor) -> NSColor {
        fill.blended(withFraction: 0.4, of: .black) ?? .black
    }

    static func border(for kind: ResourceKind) -> NSColor {
        border(for: fill(for: kind))
    }

    static func buildTimeFill(score: Double) -> NSColor {
        let p = max(0, min(1, score))
        let stops: [(Double, NSColor)] = [
            (0.00, NSColor.systemGreen.withAlphaComponent(0.85)),
            (0.50, NSColor.systemYellow.withAlphaComponent(0.90)),
            (0.80, NSColor.systemOrange.withAlphaComponent(0.90)),
            (1.00, NSColor.systemRed.withAlphaComponent(0.90)),
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

    static func untimedFill(for kind: ResourceKind) -> NSColor {
        fill(for: kind).withAlphaComponent(0.18)
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

    static var labelText: NSColor { .labelColor }
    static var background: NSColor { NSColor.windowBackgroundColor }
}
