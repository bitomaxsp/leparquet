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

    private var boardsUsed = 0

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
            self.boardsUsed += 1
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

    func printHeight() {
        print("Total rows: \(self.total_rows)")
        print("First row height: \(self.first_row_height)mm")
        print("Middle height: \(self.boardHeight)mm")
        print("Last row height: \(self.last_row_height)mm")

        var total_height = self.first_row_height + self.boardHeight * Double(self.total_rows) + self.last_row_height
        var N = 0.0
        if self.first_row_height > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }
        if self.last_row_height > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }

        print("Total height: \(self.first_row_height) + \(self.boardHeight)*\(Double(self.total_rows) - N) + \(self.last_row_height) = \(total_height)mm")
        print("(Remember, you need to add both side clearance)")
        print("Unused height from first row: \(self.unused_height_on_first_row)mm")
        print("Unused height from last row: \(self.unused_height_on_last_row)mm")
    }

    func printWidth() {
        print("Unusable normalized rests: \(self.trashCuts.map { $0.width.round(4) }) [norm to board length]")
        self.printRows()
        self.printRows(self.input.material.board.size.width)

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
        print("Used boards: \(self.boardsUsed)")

        let totalBoardsArea = Double(self.boardsUsed) * self.boardArea

        if let packArea = self.input.material.pack.area {
            print("----------------------------------------------------")
            print("** Calculate using pack area: \(packArea)")
            let packsRequiredDbl = totalBoardsArea / packArea
            let boardsPerPack = ceil(packArea / self.boardArea)
            // fractionPart represents how much of last pack is used.
            // For example for pack of 6 boards: 1/6 is 0.1(6)
            // For example for pack of 8 boards: 1/8 is 0.125
            // For pack of 10 boards, it is 0.1 and etc.
            // Here we ASSUME, that it is possible to find pack of 10 boards hence if fraction is less than 0.1 we round down, otherwise up
            let fractionPart = packsRequiredDbl.remainder(dividingBy: floor(packsRequiredDbl))
            let limit = 0.1 // Max 10 board per pack
            let packsRequired = fractionPart < limit ? packsRequiredDbl.rounded() : packsRequiredDbl.rounded(.up)
            print("** Unused boards left: \((packsRequired * boardsPerPack - Double(self.boardsUsed)).rounded())")
            print("** Packs required: \(packsRequired.rounded())")
            print("** Estimated board/pack: \(boardsPerPack.round(1))")
        }
        print("----------------------------------------------------")
        if let boardsPerPack = self.input.material.pack.boardsCount {
            print("++ Calculate using boards per pack: \(boardsPerPack)")
            let packsRequired = self.boardsUsed / boardsPerPack + (self.boardsUsed % boardsPerPack == 0 ? 0 : 1)
            let rest = self.boardsUsed % boardsPerPack
            print("++ Unused boards left: \(rest == 0 ? rest : boardsPerPack - rest)")
            print("++ Packs required: \(packsRequired)")
            print("++ Estimated pack area: \(Double(boardsPerPack) * self.boardArea)")
            print("----------------------------------------------------")
        }

        print("Total buy area as [boards * boardArea]: \(totalBoardsArea) m^2")
        print("Total buy area - total trash area: \((totalBoardsArea - total_trash).round(4)) m^2")

        print("\n----------- THEORY DATA -----------")

        print("Calculated area: \(self.input.calc_covered_area.round(4)) m^2")
        print("Calculated area + margin: \(self.input.calc_covered_area_with_margin.round(4)) m^2")
        self.boardNumWithMargin = Int(ceil(self.input.calc_covered_area_with_margin / self.boardArea))
        print("Calculated boards (using margin), float: \((self.input.calc_covered_area_with_margin / self.boardArea).round(4))")
        print("Calculated boards (using margin), int: \(self.boardNumWithMargin)")
        print("Total trash calc: \((totalBoardsArea - self.input.calc_covered_area).round(4)) m^2")

//        print(self.summary)
    }

    func printRows(_ mul: Double = 1.0) {
        print("\nLayout [nomalized]:")

        for r in self.rows {
            print(r.map { ($0.width * mul).round(4) })
        }
        print("\n")
    }
}
