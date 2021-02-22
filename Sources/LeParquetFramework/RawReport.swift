//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

class RawReport {
    // TODO: rename
    typealias Stash = [ReusableBoard]

    init(_ input: LayoutInput) {
        self.input = input
        self.first_row_height = Double(input.material.board.size.height)
    }

    let input: LayoutInput
    var boardHeight: Double { return self.input.material.board.size.height }
    var boardArea: Double { return self.input.material.board.area }
    var roomSize: Config.Size { return self.input.effectiveRoomSize }

    var first_row_height: Double
    var last_row_height = 0.0

    private var rows = [Stash]()

    // This is pure trash, middle cuts mostly
    private var trashCuts = Stash()

    private var used_boards = 0

    var unused_height_on_first_row: Double = 0.0
    var unused_height_on_last_row: Double = 0.0
    var total_rows = 0
    var boardNumWithMargin = 0

    // MARK: Implementation

    func newRow() {
        self.rows.append(Stash())
    }

    func addBoard(_ board: ReusableBoard) {
        self.rows[self.rows.count - 1].append(board)
    }

    // TODO: use 1.0 width board
    func newBoard(width: Double) -> FloorBoard {
        defer {
            self.used_boards += 1
        }
        return FloorBoard(width: width, height: self.boardHeight)
    }

    func stash(trash: ReusableBoard) {
        precondition(trash.width > 0.0, "Zero width trash. Weird!")
        self.trashCuts.append(trash)
    }

    func collectRests<T>(from: [T]) where T: ReusableBoard {
        self.trashCuts.append(contentsOf: from)
        self.trashCuts.sort()
    }

    func printAll() {
        print("Unusable normalized rests: \(self.trashCuts.map { $0.width.round(4) }) [norm to board length]")
        self.printRows()

        print("Unusable rests: \(self.trashCuts.map { ($0.width * self.input.material.board.size.width).round(4) }) mm")

        let rest_width_sum = self.trashCuts.reduce(0.0) { (next, b) in
            return next + b.width
        }

        let unused_area = rest_width_sum * self.boardArea
        print("Unusable side trash area: \(unused_area.round(4)) m^2")

        let side_cut_trash_area_m2 = (Double(self.total_rows) * self.boardHeight - self.roomSize.height) * self.roomSize.width * 1e-6
        let total_trash = unused_area + side_cut_trash_area_m2

        print("Unusable top/bottom trash area: \(side_cut_trash_area_m2) m^2")
        print("Total trash area: \(total_trash.round(4)) m^2")
        print("Used boards: \(self.used_boards)")

        let total_board_area = Double(self.used_boards) * self.boardArea

        // TODO: self.input.material.pack.area
//        let packs_required = ceil(total_board_area / self.input.material.pack.area)
//        print("Unsed boards left: {packs_required * int(round(self.pack_area_m2/self.one_board_area_m2, 0)) - self.used_boards}")
//        print("Packs required: {packs_required}")
        print("Total buy area as [boards * board area]: \(total_board_area) m^2")
        print("Total buy area - total trash area: \((total_board_area - total_trash).round(4)) m^2")

        print("\n----------- THEROY DATA: -----------")

        print("Calculated area: \(self.input.calc_covered_area.round(4)) m^2")
        print("Calculated area + margin: \(self.input.calc_covered_area_with_margin.round(4)) m^2")
        self.boardNumWithMargin = Int(ceil(self.input.calc_covered_area_with_margin / self.boardArea))
        print("Calculated boards (using margin), float: \((self.input.calc_covered_area_with_margin / self.boardArea).round(4))")
        print("Calculated boards (using margin), int: \(self.boardNumWithMargin)")

        print("Total trash calc: \((total_board_area - self.input.calc_covered_area).round(4)) m^2")
//        print(self.summary)
    }

    func printRows() {
        print("\nLayout [nomalized]:")

        for r in self.rows {
            print(r.map { $0.width.round(4) })
        }
        print("\n")
    }
}

// let mul = 1.0 * board_width
