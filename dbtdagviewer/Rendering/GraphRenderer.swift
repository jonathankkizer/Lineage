import AppKit

@MainActor
protocol GraphRenderer: AnyObject {
    var rootLayer: CALayer { get }
    var contentBounds: CGRect { get }

    func install(graph: Graph, layout: GraphLayout)
    func setViewport(_ transform: CGAffineTransform, animationDuration: CFTimeInterval)
    func setLevelOfDetail(zoomScale: CGFloat)

    func setSelection(_ ids: Set<NodeID>, primary: NodeID?)
    func setHover(_ id: NodeID?)
    func setMarquee(_ rect: CGRect?)

    func setFocus(_ ids: Set<NodeID>?, animationDuration: CFTimeInterval)
    func focusBounds() -> CGRect

    func refreshColors()

    func nodeID(atContentPoint point: CGPoint) -> NodeID?
    func nodeIDs(inContentRect rect: CGRect) -> [NodeID]
}
