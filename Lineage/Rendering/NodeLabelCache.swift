import AppKit

@MainActor
final class NodeLabelCache {

    private struct Key: Hashable {
        let text: String
        let kind: ResourceKind
        let widthBucket: Int
    }

    private var cache: [Key: CGImage] = [:]

    func image(text: String, kind: ResourceKind, size: CGSize, backingScale: CGFloat) -> CGImage? {
        let key = Key(text: text, kind: kind, widthBucket: Int(size.width))
        if let hit = cache[key] { return hit }
        guard let img = renderLabel(text: text, kind: kind, size: size, backingScale: backingScale) else { return nil }
        cache[key] = img
        return img
    }

    func clear() {
        cache.removeAll(keepingCapacity: true)
    }

    private func renderLabel(text: String, kind: ResourceKind, size: CGSize, backingScale: CGFloat) -> CGImage? {
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

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingMiddle

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: RendererColors.labelText,
            .paragraphStyle: paragraph,
        ]

        let attr = NSAttributedString(string: text, attributes: attrs)
        let insets = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        let drawRect = NSRect(
            x: insets.left,
            y: insets.top,
            width: max(0, size.width - insets.left - insets.right),
            height: max(0, size.height - insets.top - insets.bottom)
        )
        attr.draw(with: drawRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()
    }
}
