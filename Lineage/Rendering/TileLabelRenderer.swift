import AppKit

/// Renders a folder territory's header label — a folder SF Symbol + name +
/// count, like a Finder grouped-section header — to a CGImage. The font is
/// large because the label lives in content space and is only shown at the
/// lowest zoom tier. Mirrors NodeLabelCache's CGContext → makeImage pattern.
@MainActor
enum TileLabelRenderer {

    /// Width the header needs at a given font size (symbol + gap + name + count).
    static func contentWidth(label: String, count: Int?, fontSize: CGFloat) -> CGFloat {
        let nameW = (label as NSString).size(withAttributes: [.font: nameFont(fontSize)]).width
        let countW = count.map { ("  \($0)" as NSString).size(withAttributes: [.font: countFont(fontSize)]).width } ?? 0
        return iconSize(fontSize) + iconGap(fontSize) + nameW + countW
    }

    static func image(
        label: String,
        count: Int?,
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
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail

        let line = NSMutableAttributedString()
        if let folder = folderSymbol(fontSize: fontSize) {
            let attachment = NSTextAttachment()
            attachment.image = folder
            attachment.bounds = CGRect(x: 0, y: nameFont(fontSize).descender,
                                       width: folder.size.width, height: folder.size.height)
            line.append(NSAttributedString(attachment: attachment))
            line.append(NSAttributedString(string: "  ", attributes: [.font: nameFont(fontSize)]))
        }
        line.append(NSAttributedString(string: label, attributes: [
            .font: nameFont(fontSize),
            .foregroundColor: RendererColors.regionLabelName,
            .paragraphStyle: paragraph,
        ]))
        if let count {
            line.append(NSAttributedString(string: "  \(count)", attributes: [
                .font: countFont(fontSize),
                .foregroundColor: RendererColors.regionLabelCount,
                .paragraphStyle: paragraph,
            ]))
        }

        let inset = fontSize * 0.18
        line.draw(with: NSRect(x: inset, y: inset, width: canvas.width - inset * 2, height: canvas.height - inset * 2),
                  options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        return ctx.makeImage()
    }

    // MARK: - Fonts / symbol

    static func nameFont(_ fontSize: CGFloat) -> NSFont { .systemFont(ofSize: fontSize, weight: .semibold) }
    static func countFont(_ fontSize: CGFloat) -> NSFont { .systemFont(ofSize: fontSize * 0.9, weight: .regular) }
    static func iconSize(_ fontSize: CGFloat) -> CGFloat { fontSize * 1.05 }
    static func iconGap(_ fontSize: CGFloat) -> CGFloat { fontSize * 0.45 }

    private static func folderSymbol(fontSize: CGFloat) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: fontSize * 0.95, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [RendererColors.regionLabelCount]))
        return NSImage(systemSymbolName: "folder", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
    }
}
