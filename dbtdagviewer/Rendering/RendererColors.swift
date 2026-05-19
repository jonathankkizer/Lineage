import AppKit

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

    static func border(for kind: ResourceKind) -> NSColor {
        fill(for: kind).blended(withFraction: 0.4, of: .black) ?? .black
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
