import Foundation

class ReusableBoard: Rect {
    private var w: Double
    private var h: Double
    private let trash: Bool
    private let mark_: String

    fileprivate init(width: Double, height: Double, reuse: Bool, mark: String) {
        self.w = width
        self.h = height
        self.trash = !reuse
        self.mark_ = mark
    }

    var reusable: Bool { !self.trash }
    var width: Double { self.w }
    var height: Double { self.h }
    var area: Double { self.w * self.h }
    var mark: String { self.mark_ }

    // TODO: If board has one of the corners cut out
    var cornerCutOut: Bool = false

    fileprivate func createLeft(width: Double, reuse: Bool) -> LeftCut {
        return LeftCut(width: width, height: self.height, reuse: !width.isZero && reuse)
    }

    fileprivate func createRight(width: Double, reuse: Bool) -> RightCut {
        return RightCut(width: width, height: self.height, reuse: !width.isZero && reuse)
    }

    func cutAlongWidth(atDistance: Double, from fromEdge: Edge, cutWidth: Double) -> (LeftCut, RightCut) {
        assert(false, "IMPLEMENT IN SUBCLASS")
        return (LeftCut(), RightCut())
    }
}

final class LeftCut: ReusableBoard {
    private static var lCount = 0

    fileprivate init() {
        super.init(width: 0, height: 0, reuse: false, mark: "trash")
    }

    fileprivate init(width: Double, height: Double, reuse: Bool) {
        defer { Self.lCount += 1 }
        super.init(width: width, height: height, reuse: reuse, mark: "L\(Self.lCount)")
    }

    override func cutAlongWidth(atDistance: Double, from fromEdge: Edge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is good
        // Right is trash (has no original edges on sides)

        let diff = self.width - atDistance
        // Tool can remove amount of material and is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)
        precondition(newWidth >= 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: false))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: false))
        default:
            assert(false, "top and botoom does not supported")
        }
    }
}

final class RightCut: ReusableBoard {
    private static var rCount = 0

    fileprivate init() {
        super.init(width: 0, height: 0, reuse: false, mark: "trash")
    }

    fileprivate init(width: Double, height: Double, reuse: Bool) {
        defer { Self.rCount += 1 }
        super.init(width: width, height: height, reuse: reuse, mark: "R\(Self.rCount)")
    }

    override func cutAlongWidth(atDistance: Double, from fromEdge: Edge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is trash (has no original edges on sides)
        // Right is good

        let diff = self.width - atDistance
        // Tool can remove amount of material and is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)
        precondition(newWidth >= 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: false), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: false), createRight(width: atDistance, reuse: true))
        default:
            assert(false, "top and botoom does not supported")
        }
    }
}

final class TopCut: ReusableBoard {}

final class BottomCut: ReusableBoard {}

final class FloorBoard: ReusableBoard {
    init(width: Double, height: Double) {
        super.init(width: width, height: height, reuse: true, mark: "")
    }

    override func cutAlongWidth(atDistance: Double, from fromEdge: Edge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is good
        // Right is good
        let diff = self.width - atDistance
        // Tool can remove amount of material and is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)
        precondition(newWidth >= 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: true))
        default:
            assert(false, "top and botoom does not supported")
        }
    }
}

// We mostly intereted in boards width, so we overload for it
extension ReusableBoard: Comparable {
    static func < (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w < rhs.w
    }

    static func > (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w > rhs.w
    }

    static func == (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        // Use custom Double compare
        return lhs.w.eq(rhs.w)
    }
}

extension ReusableBoard: CustomStringConvertible {
    var description: String {
        return "(\(Self.self), [\(self.w.round(3)), \(self.h.round(3))] M:\(self.mark), T:\(self.reusable ? "use" : "trash"))"
    }
}
