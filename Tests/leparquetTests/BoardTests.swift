@testable import LeParquetFramework
import XCTest

final class BoardTests: XCTestCase {
    var board = Board(width: Double.random(in: 2 ..< 100.0), height: Double.random(in: 0.1 ..< 100.0), mark: "z", flavor: .whole)

    override func setUp() {
        self.board = Board(width: Double.random(in: 2 ..< 100.0), height: Double.random(in: 0.1 ..< 100.0), mark: "z", flavor: .whole)
    }

    func testBoardIsValid() {
        let b = Board(width: 10, height: 20, mark: "z", flavor: .whole)
        XCTAssertEqual(b.width, 10, "Unexpected board width")
        XCTAssertEqual(b.height, 20, "Unexpected board height")
        XCTAssertEqual(b.mark, "z", "Unexpected board mark")
        XCTAssertEqual(b.flavor, .whole, "Unexpected board flavor")
        XCTAssertEqual(b.area, 200, "Unexpected board area")
    }

    static func vDevideBoardInHalf(board: Board, from edge: Edge, toolWidth: Double) -> (Board, Board) {
        board.devideVertically(atDistance: board.width / 2, measuredFrom: edge, cutWidth: toolWidth)
    }

    static func hDevideBoardInHalf(board: Board, from edge: Edge, toolWidth: Double) -> (Board, Board) {
        board.devideHorizontally(atDistance: board.height / 2, measuredFrom: edge, cutWidth: toolWidth)
    }

    func test_WholeVDivision_BoardsAreValid() {
        var (left, right) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: self.board, from: .right, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 1.0)
        XCTAssertEqual(right.width + 1.0, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: self.board, from: .right, toolWidth: 1.0)
        XCTAssertEqual(right.width, left.width + 1.0)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")
    }

    func test_RightVDivision_BoardsAreValid() {
        let (_, r) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 0.0)

        // Devide right part, expect good right, trash left
        var (left, right) = Self.vDevideBoardInHalf(board: r, from: .left, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .trash, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: r, from: .right, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .trash, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: r, from: .left, toolWidth: 1.0)
        XCTAssertEqual(right.width + 1.0, left.width)
        XCTAssertEqual(left.flavor, .trash, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: r, from: .right, toolWidth: 1.0)
        XCTAssertEqual(right.width, left.width + 1.0)
        XCTAssertEqual(left.flavor, .trash, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")
    }

    func test_LeftVDivision_BoardsAreValid() {
        let (l, _) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 0.0)

        // Devide right part, expect good right, trash left
        var (left, right) = Self.vDevideBoardInHalf(board: l, from: .left, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .trash, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: l, from: .right, toolWidth: 0.0)
        XCTAssertEqual(right.width, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .trash, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: l, from: .left, toolWidth: 1.0)
        XCTAssertEqual(right.width + 1.0, left.width)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .trash, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: l, from: .right, toolWidth: 1.0)
        XCTAssertEqual(right.width, left.width + 1.0)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .trash, "Unexpected board flavor")
    }

    func test_RestIsLessThanToolWidth_WhenCutWhole_RestIsTrash() {
        let bbb = Board(width: 1, height: 10, mark: "B", flavor: .whole)

        var (left, right) = Self.vDevideBoardInHalf(board: bbb, from: .left, toolWidth: 1.0)
        XCTAssertEqual(left.width, bbb.width / 2)
        XCTAssertEqual(right.width, 0.0)
        XCTAssertEqual(left.flavor, .left, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .trash, "Unexpected board flavor")

        (left, right) = Self.vDevideBoardInHalf(board: bbb, from: .right, toolWidth: 1.0)
        XCTAssertEqual(left.width, 0.0)
        XCTAssertEqual(right.width, bbb.width / 2)
        XCTAssertEqual(left.flavor, .trash, "Unexpected board flavor")
        XCTAssertEqual(right.flavor, .right, "Unexpected board flavor")
    }

    func test_HorizontalDivision_Whole_Valid() {
        var (top, bottom) = Self.hDevideBoardInHalf(board: self.board, from: .top, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, .whole)

        (top, bottom) = Self.hDevideBoardInHalf(board: self.board, from: .bottom, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, .whole)

        (top, bottom) = Self.hDevideBoardInHalf(board: self.board, from: .top, toolWidth: 1.0)
        XCTAssertEqual(top.height, bottom.height + 1.0)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, .whole)

        (top, bottom) = Self.hDevideBoardInHalf(board: self.board, from: .bottom, toolWidth: 1.0)
        XCTAssertEqual(top.height + 1.0, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, .whole)
    }

    func test_HorizontalDivision_Right_Valid() {
        // First devide board verticaly in halfs
        let (_, r) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 0.0)

        var (top, bottom) = Self.hDevideBoardInHalf(board: r, from: .top, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, r.flavor)
        XCTAssertEqual(bottom.flavor, r.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: r, from: .bottom, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, r.flavor)
        XCTAssertEqual(bottom.flavor, r.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: r, from: .top, toolWidth: 1.0)
        XCTAssertEqual(top.height, bottom.height + 1.0)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, r.flavor)
        XCTAssertEqual(bottom.flavor, r.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: r, from: .bottom, toolWidth: 1.0)
        XCTAssertEqual(top.height + 1.0, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, r.flavor)
        XCTAssertEqual(bottom.flavor, r.flavor)
    }

    func test_HorizontalDivision_Left_Valid() {
        // First devide board verticaly in halfs
        let (l, _) = Self.vDevideBoardInHalf(board: self.board, from: .left, toolWidth: 0.0)

        var (top, bottom) = Self.hDevideBoardInHalf(board: l, from: .top, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, l.flavor)
        XCTAssertEqual(bottom.flavor, l.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: l, from: .bottom, toolWidth: 0.0)
        XCTAssertEqual(top.height, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, l.flavor)
        XCTAssertEqual(bottom.flavor, l.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: l, from: .top, toolWidth: 1.0)
        XCTAssertEqual(top.height, bottom.height + 1.0)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, l.flavor)
        XCTAssertEqual(bottom.flavor, l.flavor)

        (top, bottom) = Self.hDevideBoardInHalf(board: l, from: .bottom, toolWidth: 1.0)
        XCTAssertEqual(top.height + 1.0, bottom.height)
        XCTAssertEqual(top.flavor, bottom.flavor)
        XCTAssertEqual(top.flavor, l.flavor)
        XCTAssertEqual(bottom.flavor, l.flavor)
    }

    func test_RestIsLessThanToolWidth_WhenCutWholeH_RestIsTrash() {}
}
