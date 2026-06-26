import AppKit

nonisolated enum NodeLabelMetrics {
    static let fontSize: CGFloat = 13
    static let horizontalInset: CGFloat = 10
    static let verticalInset: CGFloat = 4
    static let cornerRadius: CGFloat = 6
    static let leadingBarWidth: CGFloat = 3
    static let barIconGap: CGFloat = 7
    static let iconSize: CGFloat = 14
    static let iconTextGap: CGFloat = 6
    static let minWidth: CGFloat = 92
    static let maxWidth: CGFloat = 240
    static let height: CGFloat = 30

    // Leading chrome: accent bar + gap + kind icon + gap, before the label starts.
    static var leadingContentInset: CGFloat {
        leadingBarWidth + barIconGap + iconSize + iconTextGap
    }

    static func font() -> NSFont {
        NSFont.systemFont(ofSize: fontSize, weight: .medium)
    }

    static func measuredTextWidth(_ text: String) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font()]
        let measured = (text as NSString).size(withAttributes: attrs).width
        return measured.rounded(.up)
    }

    static func nodeWidth(for text: String) -> CGFloat {
        let needed = leadingContentInset + measuredTextWidth(text) + horizontalInset
        return min(max(needed, minWidth), maxWidth)
    }

    static func isTruncated(_ text: String) -> Bool {
        leadingContentInset + measuredTextWidth(text) + horizontalInset > maxWidth
    }
}

@MainActor
final class NodeLabelCache {

    private struct Key: Hashable {
        let text: String
        let kind: ResourceKind
        let widthBucket: Int
        let selected: Bool
    }

    private var cache: [Key: CGImage] = [:]

    func image(text: String, kind: ResourceKind, size: CGSize, backingScale: CGFloat, selected: Bool = false) -> CGImage? {
        let key = Key(text: text, kind: kind, widthBucket: Int(size.width), selected: selected)
        if let hit = cache[key] { return hit }
        guard let img = renderLabel(text: text, kind: kind, size: size, backingScale: backingScale, selected: selected) else { return nil }
        cache[key] = img
        return img
    }

    func clear() {
        cache.removeAll(keepingCapacity: true)
    }

    private func drawIcon(kind: ResourceKind, color: NSColor, in box: NSRect) {
        let config = NSImage.SymbolConfiguration(pointSize: NodeLabelMetrics.iconSize, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
        guard let base = NSImage(systemSymbolName: kind.symbolName, accessibilityDescription: nil),
              let symbol = base.withSymbolConfiguration(config) else { return }
        let s = symbol.size
        guard s.width > 0, s.height > 0 else { return }
        let scale = min(box.width / s.width, box.height / s.height)
        let w = s.width * scale
        let h = s.height * scale
        let r = NSRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h)
        symbol.draw(in: r)
    }

    private func renderLabel(text: String, kind: ResourceKind, size: CGSize, backingScale: CGFloat, selected: Bool) -> CGImage? {
        let pixelWidth = Int((size.width * backingScale).rounded(.up))
        let pixelHeight = Int((size.height * backingScale).rounded(.up))
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.scaleBy(x: backingScale, y: backingScale)

        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx

        // Clip to the node's rounded body so the leading accent bar matches its corners.
        let bounds = NSRect(origin: .zero, size: size)
        NSBezierPath(roundedRect: bounds,
                     xRadius: NodeLabelMetrics.cornerRadius,
                     yRadius: NodeLabelMetrics.cornerRadius).addClip()

        // On selection the body fills with the accent color, so the bar, icon, and
        // label all flip to the high-contrast selected-text color — like a source-list row.
        let accent = selected ? RendererColors.nodeLabelTextSelected : RendererColors.kindColor(for: kind)
        let textColor = selected ? RendererColors.nodeLabelTextSelected : RendererColors.nodeLabelText

        accent.setFill()
        NSRect(x: 0, y: 0, width: NodeLabelMetrics.leadingBarWidth, height: size.height).fill()

        let iconX = NodeLabelMetrics.leadingBarWidth + NodeLabelMetrics.barIconGap
        let iconBox = NSRect(x: iconX,
                             y: (size.height - NodeLabelMetrics.iconSize) / 2,
                             width: NodeLabelMetrics.iconSize,
                             height: NodeLabelMetrics.iconSize)
        drawIcon(kind: kind, color: accent, in: iconBox)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NodeLabelMetrics.font(),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph,
        ]

        let attr = NSAttributedString(string: text, attributes: attrs)
        let textLeft = NodeLabelMetrics.leadingContentInset
        let drawRect = NSRect(
            x: textLeft,
            y: NodeLabelMetrics.verticalInset,
            width: max(0, size.width - textLeft - NodeLabelMetrics.horizontalInset),
            height: max(0, size.height - NodeLabelMetrics.verticalInset * 2)
        )
        attr.draw(with: drawRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()
    }
}
