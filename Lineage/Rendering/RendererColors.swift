import AppKit

enum NodeColoring: Int, Sendable {
    case kind
    case buildTime
}

enum RendererColors {

    // MARK: - Accessibility display settings
    //
    // At the detail zoom tier a node already carries an SF Symbol for its kind,
    // so kind is not color-only there. Three channels genuinely are: build-time
    // coloring, upstream/downstream edge highlighting, and the solid blocks at
    // low zoom. Those get a second, non-color channel when the user has asked
    // for one.

    static var increaseContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    static var differentiateWithoutColor: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
    }

    static var chipBorderWidth: CGFloat { increaseContrast ? 2 : 1 }

    /// Build time as line weight as well as hue: the slowest models read as the
    /// heaviest outlines when Differentiate Without Color is on.
    static func buildTimeBorderWidth(score: Double) -> CGFloat {
        guard differentiateWithoutColor else { return chipBorderWidth }
        switch score {
        case ..<0.50: return chipBorderWidth
        case ..<0.80: return chipBorderWidth + 1
        case ..<0.95: return chipBorderWidth + 2
        default:      return chipBorderWidth + 3
        }
    }

    /// Downstream edges dash while upstream stays solid, so direction survives
    /// without the blue/orange distinction.
    static var downstreamEdgeDash: [NSNumber]? {
        differentiateWithoutColor ? [5, 3] : nil
    }

    static var downstreamNeighborBorderWidth: CGFloat {
        differentiateWithoutColor ? 3 : 1.5
    }

    static var upstreamNeighborBorderWidth: CGFloat { 1.5 }

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

    // Native node body: neutral card with kind color carried by the icon + leading bar.
    static var nodeBodyFill: NSColor { .controlBackgroundColor }
    static var nodeBodyBorder: NSColor { .separatorColor }
    static var nodeBodyFillSelected: NSColor { .selectedContentBackgroundColor }
    static var nodeLabelText: NSColor { .labelColor }
    static var nodeLabelTextSelected: NSColor { .alternateSelectedControlTextColor }

    // Node chip styling (used by the graph renderer). Alphas firm up under
    // Increase Contrast.
    private static var chipFillAlpha: CGFloat { increaseContrast ? 0.24 : 0.14 }
    private static var chipBorderAlpha: CGFloat { increaseContrast ? 1.0 : 0.70 }
    private static var untimedFillAlpha: CGFloat { increaseContrast ? 0.12 : 0.06 }
    private static var untimedBorderAlpha: CGFloat { increaseContrast ? 0.55 : 0.25 }

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
        buildTimeColor(score: score).withAlphaComponent(increaseContrast ? 1.0 : 0.85)
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

    // Semantic-zoom overview: solid color blocks (mid zoom) and folder
    // territory tiles (lowest zoom).
    static func blockFill(for kind: ResourceKind) -> NSColor {
        kindColor(for: kind).withAlphaComponent(0.90)
    }

    static var untimedBlock: NSColor {
        NSColor.tertiaryLabelColor
    }

    // Territories are neutral "group boxes" (NSBox / Finder-section idiom) — a
    // whisper of fill + a hairline border. The kind-colored nodes carry the
    // color; the territory defers. No per-folder rainbow.
    static var regionFill: NSColor {
        NSColor.labelColor.withAlphaComponent(0.035)
    }

    static var regionBorder: NSColor {
        .separatorColor
    }

    static var regionLabelName: NSColor {
        .labelColor
    }

    static var regionLabelCount: NSColor {
        .tertiaryLabelColor
    }

    // Subtle material chip behind a territory's top-left header label.
    static var regionLabelPlate: NSColor {
        NSColor.windowBackgroundColor.withAlphaComponent(0.82)
    }

    static var regionLabelPlateBorder: NSColor {
        NSColor.separatorColor.withAlphaComponent(0.6)
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
