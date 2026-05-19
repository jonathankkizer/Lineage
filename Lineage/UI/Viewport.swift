import CoreGraphics

nonisolated struct Viewport: Equatable {
    var translation: CGPoint
    var scale: CGFloat

    static let identity = Viewport(translation: .zero, scale: 1)

    var transform: CGAffineTransform {
        CGAffineTransform(translationX: translation.x, y: translation.y)
            .scaledBy(x: scale, y: scale)
    }

    func contentPoint(fromView viewPoint: CGPoint) -> CGPoint {
        transform.inverted().apply(to: viewPoint)
    }

    func contentRect(fromView viewRect: CGRect) -> CGRect {
        viewRect.applying(transform.inverted())
    }

    static func fitting(_ contentBounds: CGRect, in viewBounds: CGRect, padding: CGFloat = 24) -> Viewport {
        guard contentBounds.width > 0, contentBounds.height > 0,
              viewBounds.width > 0, viewBounds.height > 0 else {
            return .identity
        }
        let availableW = max(1, viewBounds.width - padding * 2)
        let availableH = max(1, viewBounds.height - padding * 2)
        let scale = min(availableW / contentBounds.width, availableH / contentBounds.height)
        let clampedScale = max(0.05, min(scale, 1.5))

        let centeredX = viewBounds.midX - contentBounds.midX * clampedScale
        let centeredY = viewBounds.midY - contentBounds.midY * clampedScale
        return Viewport(translation: CGPoint(x: centeredX, y: centeredY), scale: clampedScale)
    }
}

private extension CGAffineTransform {
    nonisolated func apply(to point: CGPoint) -> CGPoint {
        point.applying(self)
    }
}
