import Foundation

enum Edge: String, Codable {
    case top
    case left
    case bottom
    case right
}

enum VerticalEdge: CaseIterable {
    case left
    case right
}

enum HorizontalEdge: CaseIterable {
    case top
    case bottom
}

struct Insets {
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
}

protocol Rect {
    var width: Double { get }
    var height: Double { get }
    var area: Double { get }
    func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge, cutWidth: Double) -> (LeftCut, RightCut)
    func cutAlongHeight(atDistance: Double, from fromEdge: HorizontalEdge, cutWidth: Double) -> (TopCut, BottomCut)
}

class ReusableBoard: Rect, Comparable {
    private var w: Double
    private var h: Double
    private var trash: Bool
    private let mark_: String

    // For top and bottom
    fileprivate convenience init() {
        self.init(width: 0, height: 0, reuse: false, mark: "trash")
    }

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

    func createLeft(width: Double, reuse: Bool) -> LeftCut {
        return LeftCut(width: width, height: self.height, reuse: reuse)
    }

    func createRight(width: Double, reuse: Bool) -> RightCut {
        return RightCut(width: width, height: self.height, reuse: reuse)
    }

    func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge, cutWidth: Double) -> (LeftCut, RightCut) {
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

    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is good
        // Right is trash

        let newWidth = self.width - atDistance - cutWidth
        precondition(newWidth > 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: false))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: false))
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

    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is trash
        // Right is good

        let newWidth = self.width - atDistance - cutWidth
        precondition(newWidth > 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: false), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: false), createRight(width: atDistance, reuse: true))
        }
    }
}

final class TopCut: ReusableBoard {}

final class BottomCut: ReusableBoard {}

final class FloorBoard: ReusableBoard {
    init(width: Double, height: Double) {
        super.init(width: width, height: height, reuse: true, mark: "")
    }

    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge, cutWidth: Double) -> (LeftCut, RightCut) {
        // Left is good
        // Right is good

        let newWidth = self.width - atDistance - cutWidth
        precondition(newWidth > 0.0, "newWidth must be > 0")
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: true))
        }
    }
}

extension Rect {
    func cutAlongHeight(atDistance: Double, from fromEdge: HorizontalEdge, cutWidth: Double) -> (TopCut, BottomCut) {
        assert(false, "NOT IMPLEMENTED")
        return (TopCut(), BottomCut())
    }
}

extension ReusableBoard {
    static func < (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w < rhs.w
    }

    static func > (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w > rhs.w
    }

    static func == (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w == rhs.w
    }
}
