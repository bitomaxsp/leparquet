import Foundation

class Board {
    private(set) var width: Double
    private(set) var height: Double
    let mark: String
    let flavor: Flavor
    var area: Double { self.width * self.height }
    /// Stores original edges. When board is cut edges are removed because they no longer belong new cuts
    /// When empty it is considered as trash
    let originalEdges: [Edge]

    private static var rCount = 0
    private static var lCount = 0

    enum Flavor: String, CaseIterable, Codable {
        /// Some piece that can't be used anymore
        case trash
        /// When board cut in half this denotes right side from prev cut
        case right
        /// When board cut in half this denotes left side from prev cut
        case left
        /// Denotes whole board
        case whole
    }

    init(width: Double, height: Double, mark: String, flavor: Flavor, edges: [Edge] = [.top, .left, .bottom, .right]) {
        self.width = width
        self.height = height
        self.mark = mark
        self.flavor = flavor
        // TODO: set them properly when cut
        self.originalEdges = edges // [.top, .left, .bottom, .right]
    }

    /// Device board in 2 halfs: left and right. Distance is measured from left or right edge. Distance is preserved after cut is done.
    func devideVertically(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(self.flavor != .trash, "Trash can't be devided. Doesn't make sense.")
        precondition(edge.isVertical, "Edge should be a vertical edge")

        switch self.flavor {
        case .whole: return self.devideVertivallyWhole(atDistance: distance, measuredFrom: edge, cutWidth: cutWidth)
        case .left: return self.devideVertivallyLeft(atDistance: distance, measuredFrom: edge, cutWidth: cutWidth)
        case .right: return self.devideVertivallyRight(atDistance: distance, measuredFrom: edge, cutWidth: cutWidth)
        default:
            precondition(false, "Unsupported vertical board division")
        }
    }

    /// Device board in 2 halfs horizontally. They still will be left and right but in different heights.
    /// Distance is measured from top or bottom edge. Distance is preserved after cut is done.
    func devideHorizontally(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(self.flavor != .trash, "Trash can't be devided. Doesn't make sense.")
        precondition(edge.isHorizontal, "Edge should be a horizontal edge")

        switch self.flavor {
        case .whole, .left, .right: return self.devideBoardHorizontally(atDistance: distance, measuredFrom: edge, cutWidth: cutWidth)
        default:
            precondition(false, "Unsupported horizontal board division")
        }
    }

    // MARK: Implementation

    private func createTrash(width: Double) -> Board {
        Board(width: width, height: self.height, mark: "Trash", flavor: .trash)
    }
}

/// Vertical division
private extension Board {
    private func devideVertivallyWhole(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(edge.isVertical, "Edge should be a vertical edge")
        precondition(distance <= self.width, "Distance must be in board width range")
        precondition(cutWidth <= self.width, "Tool cut width must be in board width range")
        // Left is good
        // Right is good

        let diff = self.width - distance
        // Tool can remove amount of material and which is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)

        precondition(newWidth >= 0.0, "newWidth must be > 0")

        return (self.createVLeft(width: (edge == .left ? distance : newWidth)), self.createVRight(width: (edge == .right ? distance : newWidth)))
    }

    private func devideVertivallyLeft(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(edge.isVertical, "Edge should be a vertical edge")
        precondition(distance <= self.width, "Distance should be in board range")
        precondition(cutWidth <= self.width, "Tool cut width must be in board width range")
        // Left is good
        // Right is trash (has no original edges on sides)

        let diff = self.width - distance
        // Tool can remove amount of material and which is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)

        precondition(newWidth >= 0.0, "newWidth must be > 0")

        return (self.createVLeft(width: (edge == .left ? distance : newWidth)), self.createTrash(width: (edge == .right ? distance : newWidth)))
    }

    private func devideVertivallyRight(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(edge.isVertical, "Edge should be a vertical edge")
        precondition(distance <= self.width, "Distance should be in board range")
        precondition(cutWidth <= self.width, "Tool cut width must be in board width range")
        // Left is trash (has no original edges on sides)
        // Right is good

        let diff = self.width - distance
        // Tool can remove amount of material and which is less then tool cut width hense min()
        let newWidth = diff - min(cutWidth, diff)
        precondition(newWidth >= 0.0, "newWidth must be > 0")

        return (self.createTrash(width: (edge == .left ? distance : newWidth)), self.createVRight(width: (edge == .right ? distance : newWidth)))
    }

    private func createVLeft(width: Double) -> Board {
        defer { Self.lCount += 1 }
        let flavor: Flavor = !width.isZero ? .left : .trash
        return Board(width: width, height: self.height, mark: "L\(Self.lCount)", flavor: flavor)
    }

    private func createVRight(width: Double) -> Board {
        defer { Self.rCount += 1 }
        let flavor: Flavor = !width.isZero ? .right : .trash
        return Board(width: width, height: self.height, mark: "R\(Self.rCount)", flavor: flavor)
    }
}

/// Horizontal division
private extension Board {
    private func devideBoardHorizontally(atDistance distance: Double, measuredFrom edge: Edge, cutWidth: Double) -> (Board, Board) {
        precondition(edge.isHorizontal, "Edge should be a horizontal edge")
        precondition(distance <= self.height, "Distance must be in board height range")
        precondition(cutWidth <= self.height, "Tool cut width must be in board height range")
        // Top is good
        // Botton is good

        let diff = self.height - distance
        // Tool can remove amount of material and which is less then tool cut height hense min()
        let newHeight = diff - min(cutWidth, diff)

        precondition(newHeight >= 0.0, "newHeight must be > 0")
        let topHeight = (edge == .top ? distance : newHeight)
        let bottomHeight = (edge == .bottom ? distance : newHeight)

        let top = Board(width: self.width, height: topHeight, mark: self.mark, flavor: topHeight.isZero ? .trash : self.flavor)
        let bottom = Board(width: self.width, height: bottomHeight, mark: self.mark, flavor: bottomHeight.isZero ? .trash : self.flavor)
        return (top, bottom)
    }
}

// We mostly interested in boards width, so we overload for it
extension Board: Comparable {
    static func < (lhs: Board, rhs: Board) -> Bool {
        return lhs.width < rhs.width
    }

    static func > (lhs: Board, rhs: Board) -> Bool {
        return lhs.width > rhs.width
    }

    static func == (lhs: Board, rhs: Board) -> Bool {
        // Use custom Double compare
        return lhs.width.eq(rhs.width)
    }
}

extension Board: CustomStringConvertible {
    var description: String {
        return "(B:\(self.flavor)), [\(self.width.round(3)), \(self.height.round(3))] M:\(self.mark)"
    }
}
