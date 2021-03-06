import Foundation

// Door in the room need to be taken into account
struct Door {
    /// Name to identify the door uniquely
    let name: String
    /// Edge which door rect is in
    let edge: Edge
    /// door frame. y coord always 0 as door protrudes covering floor rectangle
    let frame: CGRect
    /// if frame values are normalized wrt board dimentions
    /// width (longest dimension) normalized to board width for top and bottom doors
    /// height (shortest dimension) normalized to board height for top and bottom doors
    /// and for left and right it's wice versa
    let nomalized: Bool
    /// Normalized range covered by board along longest dimention. See nomalized for normalization notes.
    let longRange: Range<Double>

    init(name: String, edge: Edge, frame: CGRect, normalize: Bool, wn: Double, hn: Double) {
        self.name = name
        self.edge = edge
        self.nomalized = normalize
        self.wNorm = wn
        self.hNorm = hn

        if (normalize) {
            // NOTE: For doors along horizontal edges we normalize displacement and width to board width, height to board height
            let height = frame.size.height.native * hn
            // NOTE: For doors along vertical edges we normalize displacement and width to board height, height to board width
            let width = frame.size.width.native * wn

            self.frame = CGRect(x: frame.origin.x.native * wn, y: 0.0, width: width, height: height)
            //        let range = rangeStart ..< (rangeStart + width).nextUp
        } else {
            self.frame = frame
        }
        // FIXME: if it needs to be closed range ???
        self.longRange = self.frame.origin.x.native ..< self.frame.origin.x.native + self.frame.size.width.native
    }

    /// Normalize height coef used to get normalized value (devide by it to get real)
    private let hNorm: Double
    /// Normalize width coef used to get normalized value (devide by it to get real)
    private let wNorm: Double
}

extension Door: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.

    public var debugDescription: String {
        return "(Name:\(self.name), E:\(self.edge), Frame:\(self.frame), Norm:\(self.nomalized), R:\(self.longRange))"
    }
}
