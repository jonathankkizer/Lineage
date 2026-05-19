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

    func setFocus(_ scope: SelectionScope?, animationDuration: CFTimeInterval)
    func focusBounds() -> CGRect

    func setColoring(_ mode: NodeColoring)
    func setBuildTimings(_ timings: BuildTimings)

    func setBulkEdgesEnabled(_ enabled: Bool)
    func areBulkEdgesEnabled() -> Bool
    func resetBulkEdgesToAuto()

    func refreshColors()

    func nodeID(atContentPoint point: CGPoint) -> NodeID?
    func nodeIDs(inContentRect rect: CGRect) -> [NodeID]
}
