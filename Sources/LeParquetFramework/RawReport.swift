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
    typealias StashOfLefts = [LeftCut]
    typealias StashOfRights = [RightCut]

    init(_ input: LayoutInput) {
        self.first_row_height = Double(input.material.board.size.height)
        self.boardHeight = input.material.board.size.height
    }

    let boardHeight: Double
    var first_row_height: Double
    var last_row_height = 0.0

    private var rows = [Stash]()

    // NOTE: Reusable right cut can only be used on left side, and vise versa
    var reusable_left = StashOfRights()
    var reusable_right = StashOfLefts()
    // This is pure trash, middle cuts mostly
    var unusable_rest = Stash()

    private var used_boards = 0

    var unused_height_on_first_row: Double = 0.0
    var unused_height_on_last_row: Double = 0.0
    var total_rows = 0

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

    func collectRests() {
        self.unusable_rest.append(contentsOf: self.reusable_right)
        self.unusable_rest.append(contentsOf: self.reusable_left)
        self.reusable_left.removeAll()
        self.reusable_right.removeAll()
        self.unusable_rest.sort()
    }

    func printRows() {
        for r in self.rows {
            print(r.map { $0.width.round(4) })
        }
    }
}

// let mul = 1.0 * board_width

//        print("Unusable rests: {[round(x*self.board_width, 3) for x in self.unusable_rest]} mm")

//        let unused_area = sum(self.unusable_rest) * self.input.material.board.area
//        print("Unusable side trash area: {round(unused_area, 4)} m^2")

//        let side_cut_trash_area_m2 = (self.total_rows * self.board_height - self.roomW) * self.roomL * 1e-6
//        let total_trash = unused_area + side_cut_trash_area_m2

//        print("Unusable top/bottom trash area: {side_cut_trash_area_m2} m^2")
//        print("Total trash area: {round(total_trash, 4)} m^2")
//        print("Used boards: {self.used_boards}")

//        let total_board_area = self.state.used_boards * self.one_board_area_m2  // - side_cut_trash_area  // - 2 * self.roomL*
//        let packs_required = math.ceil(total_board_area / self.pack_area_m2)
//        print("Unsed boards left: {packs_required * int(round(self.pack_area_m2/self.one_board_area_m2, 0)) - self.used_boards}")
//        print("Packs required: {packs_required}")
//        print("Total buy area as [boards * board area]: {total_board_area} m^2")
//        print("Total buy area - total trash area: {round(total_board_area - total_trash, 4)} m^2")

//        print('\n----------- THEROY DATA: -----------")

//        print("Calculated area: {self.calc_covered_area} m^2")
//        print("Calculated area + margin: {self.calc_covered_area_with_margin} m^2")
//        self.int_board_num = math.ceil(self.calc_covered_area_with_margin / self.one_board_area_m2)
//        print("Calculated boards (using margin), float: {self.calc_covered_area_with_margin/self.one_board_area_m2}")
//        print("Calculated boards (using margin), int: {self.int_board_num}")

//        print("Total trash calc: {total_board_area - self.calc_covered_area} m^2")
//        print(self.summary)
