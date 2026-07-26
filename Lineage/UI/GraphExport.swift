import AppKit
import UniformTypeIdentifiers

/// PDF / PNG export and printing for the graph canvas.
///
/// Both go through `GraphRenderer.drawForExport`, so output always matches the
/// live layer tree. Contexts are flipped to match layer geometry: the canvas is
/// a flipped `NSView`, so its layers use y-down coordinates while a bitmap or
/// PDF context is y-up.
@MainActor
enum GraphExport {

    /// Cap on exported pixel dimensions. A large project at 2x can otherwise ask
    /// for a bitmap in the hundreds of megapixels.
    private static let maxPixelDimension: CGFloat = 12_000

    static func pdfData(renderer: GraphRenderer) -> Data? {
        let bounds = renderer.contentBounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { return nil }
        var mediaBox = CGRect(origin: .zero, size: bounds.size)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        context.beginPDFPage(nil)
        flip(context, height: bounds.height)
        renderer.drawForExport(in: context, scale: 1)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    static func pngData(renderer: GraphRenderer, scale: CGFloat) -> Data? {
        let bounds = renderer.contentBounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let clampedScale = min(scale, maxPixelDimension / max(bounds.width, bounds.height))
        let pixelWidth = Int((bounds.width * clampedScale).rounded())
        let pixelHeight = Int((bounds.height * clampedScale).rounded())
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        flip(context, height: CGFloat(pixelHeight))
        renderer.drawForExport(in: context, scale: clampedScale)

        guard let image = context.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = bounds.size
        return rep.representation(using: .png, properties: [:])
    }

    /// Layer geometry is y-down (the canvas view is flipped); bitmap and PDF
    /// contexts are y-up. Without this the export comes out mirrored vertically.
    private static func flip(_ context: CGContext, height: CGFloat) {
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1, y: -1)
    }

    // MARK: - Save panels

    static func runExportPanel(
        renderer: GraphRenderer,
        window: NSWindow?,
        suggestedName: String,
        type: UTType
    ) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = "\(suggestedName).\(type.preferredFilenameExtension ?? "pdf")"
        panel.canCreateDirectories = true
        panel.message = type == .pdf
            ? "Export the graph as a vector PDF."
            : "Export the graph as a PNG image."

        let complete: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            let data = type == .pdf
                ? pdfData(renderer: renderer)
                : pngData(renderer: renderer, scale: 2)
            guard let data else {
                presentFailure(window: window)
                return
            }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                NSAlert(error: error).beginSheetModal(for: window ?? NSApp.keyWindow ?? NSWindow())
            }
        }

        if let window {
            panel.beginSheetModal(for: window, completionHandler: complete)
        } else {
            complete(panel.runModal())
        }
    }

    private static func presentFailure(window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = "Couldn't export the graph"
        alert.informativeText = "There's nothing laid out to export yet."
        alert.alertStyle = .warning
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    // MARK: - Printing

    /// Prints the graph scaled to fit the page, in landscape by default — a
    /// lineage graph is almost always wider than it is tall.
    static func print(renderer: GraphRenderer, window: NSWindow?, jobTitle: String) {
        let bounds = renderer.contentBounds
        guard bounds.width > 0, bounds.height > 0, let pdf = pdfData(renderer: renderer) else {
            presentFailure(window: window)
            return
        }
        guard let rep = NSPDFImageRep(data: pdf) else {
            presentFailure(window: window)
            return
        }

        let imageView = NSImageView(frame: CGRect(origin: .zero, size: bounds.size))
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown

        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.orientation = bounds.width >= bounds.height ? .landscape : .portrait
        info.horizontalPagination = .fit
        info.verticalPagination = .fit
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = true

        let operation = NSPrintOperation(view: imageView, printInfo: info)
        operation.jobTitle = jobTitle
        if let window {
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            operation.run()
        }
    }
}
