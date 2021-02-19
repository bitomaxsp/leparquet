//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public class RowLayoutEngine {
    typealias Fraction = Double
    typealias Stash = [Fraction]

    // ###################################

    let input: LayoutInput
    let report: RawReport
    let normalizedWholeStep = 1.0

    init(_ input: LayoutInput) {
        self.input = input
        self.report = RawReport(self.input)
    }

    func layout() -> RawReport {
        self.calculate_rows()

        let board_width = self.input.material.board.size.width

        // 1 - Normalized to one board length
        let normalizedRowWidth = self.input.effectiveRoomSize.width / board_width

        print("\n")
        print("Norm row width: \(normalizedRowWidth.round(4)), Effective covering lenth in each row: \(normalizedRowWidth * board_width)mm")

        self.normalizedLayoutCalculation(normalizedRowWidth)

        self.report.collectRests()

        print("Unusable normalized rests: \(self.report.unusable_rest.map { $0.round(4) }) [norm to board length]")

        print("\nLayout [nomalized]:")

        for r in self.report.rows {
            print(r.map { $0.round(4) })
        }

        print("\n")

        return self.report
    }

    // MARK: Implementation

    private func calculate_rows() {
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
        var step = start

        while row_count < self.report.total_rows {
            if debug {
                print("Row ======================== \(row_count)")
            }

            self.report.rows.append(Stash())
            var covered = 0.0

            // First board used from LEFT stash
            if !self.use_from_left_stash(step) {
                // Use new first board and save the rest
                self.use_whole_board_on_the_left_side(step)
            }

            while covered < normalizedRowWidth {
                step = min(step, min(self.normalizedWholeStep, Fraction(normalizedRowWidth - covered)))

                if debug {
                    print("Row:\(row_count) Step: \(step.round(4))")
                }

                self.report.rows[row_count].append(step)

                covered += step

                if step == 1 {
                    // TODO: take_whole_board
                    self.report.used_boards += 1
                }

                if covered >= normalizedRowWidth {
                    // Right reused from stash if we have it with required length
                    if !self.use_from_right_stash(step) {
                        // Or new one and save the rest
                        self.use_whole_board_on_the_right_side(step)
                    }
                    break
                }

                // Use whole board if we in the middle
                // TODO: MOVE out of cycle upward
                step = self.normalizedWholeStep
            }
            // Update step before new row
            step = self.next_deck_step(start, row_count)
            row_count += 1
        }

        if debug {
            print("============================ DONE")
        }
    }

    // TODO: Rename to nextRowFirstBoardLength()
    private func next_deck_step(_ start: Fraction, _ rowCount: Int) -> Fraction {
        let step = Fraction(1, 3)
        let r = rowCount % 3

        var nexts = start + step + step * Double(r)
        if nexts > self.normalizedWholeStep {
            nexts -= self.normalizedWholeStep
        }

        return nexts
    }

    private func use_whole_board_on_the_right_side(_ step: Fraction) {
        // Whole board was used as last one on the right
        let rest_to_left_side = self.normalizedWholeStep - step
        self.report.used_boards += 1
        // Save usable rest from right which can be used on left side

        assert(rest_to_left_side != 0.0)

        // Collect usable only if it grater than smallest step for the last which 1/3 for the deck layout
        if rest_to_left_side >= Fraction(1, 3) {
            if debug {
                print("Save reusable left: \(rest_to_left_side.round(4))")
            }
            self.report.reusable_left.append(Fraction(rest_to_left_side))
        } else {
            self.collect_trash(rest_to_left_side)
        }
    }

    private func use_whole_board_on_the_left_side(_ step: Fraction) {
//        precondition(step < self.normalizedWholeStep, "First step in row")

        // Determine rest from lest to right side
        if step == Fraction(1, 3) || step == Fraction(2, 3) {
            let carry = self.normalizedWholeStep - step
            self.report.used_boards += 1
            self.report.reusable_right.append(carry)
            if debug {
                print("Save reusable right: \(carry.round(4))")
            }
        }
    }

//    enum Side {
//        case left
//        case right
//    }

    private func use_from_left_stash(_ step: Fraction) -> Bool {
        let used = self.use_from_stash(&self.report.reusable_left, step)
        return used
    }

    private func use_from_right_stash(_ step: Fraction) -> Bool {
        let used = self.use_from_stash(&self.report.reusable_right, step)
        return used
    }

    private func use_from_stash(_ stash: inout Stash, _ step: Fraction) -> Bool {
        var found = false

        if stash.count > 0 {
            stash.sort()
            if debug {
                print("Checking stash of reusable {side} part: \(stash.map { $0.round(4) })")
            }

            if let cut = stash.first(where: { $0 > step }) {
                if let i = stash.firstIndex(of: cut) {
                    stash.remove(at: i)
                }
                found = true
                precondition(cut - step >= 0.0)

                if debug {
                    print("Found reusable {side} part: \(cut.round(4)), using \(step.round(4)) of it")
                }
                self.collect_trash(cut - step)
            }
        }

        return found
    }

    private func collect_trash(_ trash: Double) {
        // return rounded trash
        if trash > 0.0 {
            self.report.unusable_rest.append(trash)
            if debug {
                print("Collect trash \(trash.round(6))")
            }
        } else {
            if debug {
                print("Trash is 0")
            }
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
