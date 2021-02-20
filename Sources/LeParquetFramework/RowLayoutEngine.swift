//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public class RowLayoutEngine {
    typealias Stash = RawReport.Stash

    // ###################################

    let input: LayoutInput
    let report: RawReport
    let normalizedWholeStep = 1.0

    init(_ input: LayoutInput) {
        self.input = input
        self.report = RawReport(self.input)
    }

    func layout() -> RawReport {
        self.calculateRows()

        let board_width = self.input.material.board.size.width

        // 1 - Normalized to one board length
        let normalizedRowWidth = self.input.effectiveRoomSize.width / board_width

        print("\n")
        print("Norm row width: \(normalizedRowWidth.round(4)), Effective covering lenth in each row: \(normalizedRowWidth * board_width)mm")

        self.normalizedLayoutCalculation(normalizedRowWidth)

        self.report.collectRests()

        print("Unusable normalized rests: \(self.report.unusable_rest.map { $0.width.round(4) }) [norm to board length]")

        print("\nLayout [nomalized]:")

        self.report.printRows()

        print("\n")

        return self.report
    }

    // MARK: Implementation

    private func calculateRows() {
        let board_height = self.input.material.board.size.height
        let borad_num_frac = self.input.effectiveRoomSize.height / board_height
        let total_rows = ceil(borad_num_frac)
        self.report.total_rows = Int(total_rows)

        // TODO: FIXME: Cover using whole boards (account spike that is cut off)
        // spike_mm = 0  # 15  # [mm]

        self.report.unused_height_on_last_row = total_rows * board_height - self.input.effectiveRoomSize.height

        // TODO: if self.unused_height_on_last_row < spike_mm:

        precondition(self.report.unused_height_on_last_row <= board_height, "Ununsed last board height must be less then 1 board height")

        self.report.last_row_height = board_height - self.report.unused_height_on_last_row

        if debug {
            print("Preliminary last row height: \(self.report.last_row_height)")
        }

        // whole room covered using whole boards in hieght
        if self.report.last_row_height == 0.0 {
            self.report.last_row_height = board_height
        }

        // we need to shif to get at least min_last_height mm on last row
        let min_combined_height_limit = max(self.input.minLastRowHeight, self.input.desiredLastRowHeight)

        while self.report.last_row_height < min_combined_height_limit {
            let shift = min_combined_height_limit - self.report.last_row_height
            self.report.first_row_height -= shift
            self.report.last_row_height += shift
            if debug {
                print("Last row is less than needed, adjusting it by \(shift)")
            }
        }

        self.report.unused_height_on_first_row = board_height - self.report.first_row_height
        self.report.unused_height_on_last_row = board_height - self.report.last_row_height

        if debug {
            print("Total rows: \(total_rows)")
            print("First row height: \(self.report.first_row_height)mm")
            print("Middle height: \(board_height)mm")
            print("Last row height: \(self.report.last_row_height)mm")
        }

        var total_height = self.report.first_row_height + board_height * total_rows + self.report.last_row_height

        var N = 0.0
        if self.report.first_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
        if self.report.last_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
        if debug {
            print("Total height: \(self.report.first_row_height) + \(board_height)*\(total_rows - N) + \(self.report.last_row_height) = \(total_height)mm")
            print("(Remember, you need to add both side clearance)")
            print("Unused height from first row: \(self.report.unused_height_on_first_row)mm")
            print("Unused height from last row: \(self.report.unused_height_on_last_row)mm")
        }
    }

    private func normalizedLayoutCalculation(_ normalizedRowWidth: Double) {
        let start = self.input.firstBoard.lengthAsDouble()

        var row_count = 0
        var cutLength: Double = start
        // ReusableBoard(width: start, height: self.input.material.board.size.height)

        while row_count < self.report.total_rows {
            if debug {
                print("Row ======================== \(row_count)")
            }

            self.report.newRow()
            var rowCovered = 0.0

            // First board used from LEFT stash
            var board: ReusableBoard? = self.useBoradFromLeftStash(cutLength)
            if board == nil {
                // Use new first board and save the rest if stash is empty
                board = self.useWholeBoardOnTheLeftSide(cutLength)
            }

            precondition(board != nil, "Board must be valid here")
            self.report.addBoard(board!)
            rowCovered += board!.width

            if debug {
                print("Row:\(row_count) Step: \(cutLength.round(4))")
            }

            // Use whole board if we in the middle
            cutLength = self.normalizedWholeStep

            while rowCovered < normalizedRowWidth {
                cutLength = min(self.normalizedWholeStep, Double(normalizedRowWidth - rowCovered))

                if debug {
                    print("Row:\(row_count) Step: \(cutLength.round(4))")
                }

                if cutLength == self.normalizedWholeStep {
                    self.report.addBoard(self.report.newBoard(width: cutLength))
                    rowCovered += cutLength
                
                } else if cutLength < self.normalizedWholeStep {
                    board = self.useBoardFromRightStash(cutLength)
                    // Right reused from stash if we have it with required length
                    if board == nil {
                        // Or new one and save the rest
                        board = self.useWholeBoardOnTheRightSide(cutLength)
                    }

                    precondition(board != nil, "Board must be valid here")
                    self.report.addBoard(board!)
                    break
                }

                // Use whole board if we in the middle
                cutLength = self.normalizedWholeStep
            }
            // Update step before new row
            cutLength = self.next_deck_step(start, row_count)
            row_count += 1
        }

        if debug {
            print("============================ DONE")
        }
    }

    // TODO: Rename to nextRowFirstBoardLength()
    private func next_deck_step(_ start: Double, _ rowCount: Int) -> Double {
        let step = Double(1, 3)
        let r = rowCount % 3

        var nexts = start + step + step * Double(r)
        if nexts > self.normalizedWholeStep {
            nexts -= self.normalizedWholeStep
        }

        return nexts
    }

    // return used cut
    private func useWholeBoardOnTheRightSide(_ cutLength: Double) -> ReusableBoard {
        precondition(cutLength > 0.0, "Cut must be greater than 0")

        let board = self.report.newBoard(width: self.normalizedWholeStep)
        if cutLength < self.normalizedWholeStep {
            let (left, right) = board.cutAlongWidth(atDistance: cutLength, from: .left)

            precondition(left.width == cutLength, "left.width must be cutLength")

            // Collect usable only if it grater than smallest cutLength for the last which 1/3 for the deck layout
            if right.width >= Double(1, 3) { // TODO: min row step
                if debug {
                    print("Save reusable \(right) for the left side: \(right.width.round(4))")
                }
                // Save usable rest from right which can be used on left side
                self.report.reusable_left.append(right)
            } else {
                self.collect(trash: right)
            }
            return left
        }
        return board
    }

    // return used cut
    private func useWholeBoardOnTheLeftSide(_ cutLength: Double) -> ReusableBoard {
        precondition(cutLength > 0.0, "Cut must be greater than 0")

        // Take new board
        let board = self.report.newBoard(width: self.normalizedWholeStep)

        // Determine rest from lest to right side
//        if cutLength == Double(1, 3) || cutLength == Double(2, 3) {
        if cutLength < self.normalizedWholeStep {
            let (left, right) = board.cutAlongWidth(atDistance: cutLength, from: .right)

            precondition(right.width == cutLength, "right.width must be cutLength")

            self.report.reusable_right.append(left)
            if debug {
                print("Save reusable \(left) for the right side: \(left.width.round(4))")
            }
            return right
        }
        return board
    }

    private func useBoradFromLeftStash(_ requiredLength: Double) -> RightCut? {
        return self.useFrom(&self.report.reusable_left, requiredLength)
    }

    private func useBoardFromRightStash(_ requiredLength: Double) -> LeftCut? {
        return self.useFrom(&self.report.reusable_right, requiredLength)
    }

    private func useFrom<T>(_ stash: inout [T], _ requiredLength: Double) -> T? where T: ReusableBoard {
        if stash.count > 0 {
            stash.sort()
            if debug {
                print("Checking stash of reusable \(T.self) part: \(stash.map { $0.width.round(4) })")
            }

            if let idx = stash.firstIndex(where: { $0.width > requiredLength }) {
                let board = stash.remove(at: idx)

                precondition(board.width - requiredLength >= 0.0)

                if debug {
                    print("Found reusable \(T.self) part: \(board.width.round(4)), using \(requiredLength.round(4)) of it")
                }

                let edge: VerticalEdge = T.self == LeftCut.self ? .left : .right

                let (left, right) = board.cutAlongWidth(atDistance: requiredLength, from: edge)

                if T.self == LeftCut.self {
                    self.collect(trash: right)
                    return left as? T
                } else {
                    self.collect(trash: left)
                    return right as? T
                }
            }
        }

        return nil
    }

    private func collect(trash: ReusableBoard) {
        // return rounded trash
        self.report.unusable_rest.append(trash)
        if debug {
            print("Collect trash \(trash.width.round(6)), reuse: \(trash.reusable)")
        }
    }
}

extension Double {
    init(_ nom: Int, _ denom: Int) {
        self = Double(nom) / Double(denom)
    }

    init(_ nom: Double, _ denom: Double) {
        self = nom / denom
    }

    func round(_ signs: Int) -> String {
        return String(format: "%.\(signs)g", self)
    }
}
