import AppKit

/// Renders a folder territory tile's label ("name · count") to a CGImage.
/// The font is large (sized to the tile) because the label lives in content
/// space and is only shown at the lowest zoom tier, where a 13pt label would be
/// sub-pixel. Mirrors NodeLabelCache's CGContext → makeImage pattern.
@MainActor
enum TileLabelRenderer {

    static func image(
        label: String,
        count: Int,
        fontSize: CGFloat,
        canvas: CGSize,
        backingScale: CGFloat
    ) -> CGImage? {
        let pixelWidth = Int((canvas.width * backingScale).rounded(.up))
        let pixelHeight = Int((canvas.height * backingScale).rounded(.up))
        guard pixelWidth > 0, pixelHeight > 0, fontSize > 0 else { return nil }

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
        defer { NSGraphicsContext.restoreGraphicsState() }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: RendererColors.regionLabel,
            .paragraphStyle: paragraph,
        ]
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: RendererColors.regionLabel.withAlphaComponent(0.6),
            .paragraphStyle: paragraph,
        ]

        let line = NSMutableAttributedString(string: label, attributes: nameAttrs)
        line.append(NSAttributedString(string: "  \(count)", attributes: countAttrs))
        line.draw(with: NSRect(origin: .zero, size: canvas),
                  options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        return ctx.makeImage()
    }
}
