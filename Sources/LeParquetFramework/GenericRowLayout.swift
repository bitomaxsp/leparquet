//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public class GenericRowLayout {
    struct LayoutState {
        init(_ data: LayoutData) {
            self.first_row_height = Double(data.material.board.size.height)
        }

        var last_row_height = 0.0
        var first_row_height: Double

        var rows = [[Double]]()

        typealias Stash = [Fraction]
        var reusable_left = Stash()
        var reusable_right = Stash()
        var unusable_rest = Stash()

        var used_boards = 0

        var unused_height_on_first_row: Double = 0.0
        var unused_height_on_last_row: Double = 0.0
        var total_rows = 0

        mutating func collectRests() {
            self.unusable_rest.append(contentsOf: self.reusable_right)
            self.unusable_rest.append(contentsOf: self.reusable_left)
            self.reusable_left.removeAll()
            self.reusable_right.removeAll()
            self.unusable_rest.sort()
        }
    }

    init(_ config: Config) {
        self.config = config
    }

    let config: Config
    var state: LayoutState!
    var layoutData: LayoutData!
    let normalizedWholeStep = 1.0

    // MARK: Implementation

    typealias Fraction = Double

    public func calculate() {
        let report = Report()

        for choice in self.config.floorChoices {
            for room in self.config.rooms {
                let rawReport = self.calculateLayout(LayoutData(self.config, choice, room))
                report.add(rawReport, forRoom: room, withChoice: choice)
            }
        }
    }

    func calculateLayout(_ data: LayoutData) -> RawReport {
        self.state = LayoutState(data)
        self.layoutData = data
        self.state.total_rows = self.calculate_rows()

        let board_width = self.layoutData.material.board.size.width

        // 1 - Normalized to one board length
        let normalizedRowWidth = self.layoutData.effectiveRoomSize.width / board_width

        print("\n")
        print("Norm row width: \(normalizedRowWidth), Effective covering lenth in each row: \(normalizedRowWidth * board_width)mm")

        self.normalizedCalculations(normalizedRowWidth)

        self.state.collectRests()

        print("Unusable rests: \(self.state.unusable_rest) [relative board length]")

        print("\nLayout:")
        let mul = 1.0 * board_width

        for r in self.state.rows {
            print(r)
        }

        print("\n")

//        print("Unusable rests: {[round(x*self.board_width, 3) for x in self.unusable_rest]} mm")

//        let unused_area = sum(self.unusable_rest) * self.layoutData.material.board.area
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

        return RawReport()
    }

    func calculate_rows() -> Int {
        let board_height = self.layoutData.material.board.size.height
        let borad_num_frac = self.layoutData.effectiveRoomSize.height / board_height
        let total_rows = ceil(borad_num_frac)

        // TODO: FIXME: Cover using whole boards (account spike that is cut off)
        // spike_mm = 0  # 15  # [mm]

        self.state.unused_height_on_last_row = total_rows * board_height - self.layoutData.effectiveRoomSize.height

        // TODO: if self.unused_height_on_last_row < spike_mm:

        precondition(self.state.unused_height_on_last_row <= board_height)

        self.state.last_row_height = board_height - self.state.unused_height_on_last_row

        if debug {
            print("Preliminary last row height: \(self.state.last_row_height)")
        }

        // whole cover using whole boards
        if self.state.last_row_height == 0.0 {
            self.state.last_row_height = board_height
        }

        // we need to shif to get at least min_last_height mm on last row
        let min_combined_height_limit = max(self.layoutData.minLastRowHeight, self.layoutData.desiredLastRowHeight)

        while self.state.last_row_height < min_combined_height_limit {
            let shift = min_combined_height_limit - self.state.last_row_height
            self.state.first_row_height -= shift
            self.state.last_row_height += shift
            if debug {
                print("Last row is lesst than needed, adjusting it by \(shift)")
            }
        }

        self.state.unused_height_on_first_row = board_height - self.state.first_row_height
        self.state.unused_height_on_last_row = board_height - self.state.last_row_height

        if debug {
            print("Total rows: \(total_rows)")
            print("First row height: \(self.state.first_row_height)mm")
            print("Middle height: \(board_height)mm")
            print("Last row height: \(self.state.last_row_height)mm")
        }

        var total_height = self.state.first_row_height + board_height * total_rows + self.state.last_row_height

        var N = 0.0
        if self.state.first_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
        if self.state.last_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
        if debug {
            print("Total height: \(self.state.first_row_height) + \(board_height)*\(total_rows - N) + \(self.state.last_row_height) = \(total_height)mm")
            print("(Remember, you need to add both side clearance)")
            print("Unused height from first row: \(self.state.unused_height_on_first_row)mm")
            print("Unused height from last row: \(self.state.unused_height_on_last_row)mm")
        }
        return Int(total_rows)
    }

    func normalizedCalculations(_ normalizedRowWidth: Double) {
        let start = self.layoutData.firstBoard.lengthAsDouble()

        var row_count = 0
        var step = start

        while row_count < self.state.total_rows {
            if debug {
                print("Row ======================== \(row_count)")
            }

            self.state.rows.append(LayoutState.Stash())
            var covered = 0.0

            // First board used from LEFT stash
            if !self.use_from_left_stash(step) {
                // Use new first board and save the rest
                self.use_whole_board_on_the_left_side(step)
            }

            while covered < normalizedRowWidth {
                step = min(step, min(self.normalizedWholeStep, Fraction(normalizedRowWidth - covered)))

                if debug {
                    print("Row:\(row_count) Step: \(step)")
                }

                self.state.rows[row_count].append(step)

                covered += step

                if step == 1 {
                    // TODO: take_whole_board
                    self.state.used_boards += 1
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
    func next_deck_step(_ start: Fraction, _ rowCount: Int) -> Fraction {
        let step = Fraction(1, 3)
        let r = rowCount % 3

        var nexts = start + step + step * Double(r)
        if nexts > self.normalizedWholeStep {
            nexts -= self.normalizedWholeStep
        }

        return nexts
    }

    func use_whole_board_on_the_right_side(_ step: Fraction) {
        // Whole board was used as last one on the right
        let rest_to_left_side = self.normalizedWholeStep - step
        self.state.used_boards += 1
        // Save usable rest from right which can be used on left side

        assert(rest_to_left_side != 0.0)

        // Collect usable only if it grater than smallest step for the last which 1/3 for the deck layout
        if rest_to_left_side >= Fraction(1, 3) {
            if debug {
                print("Save reusable left: \(rest_to_left_side)")
            }
            self.state.reusable_left.append(Fraction(rest_to_left_side))
        } else {
            self.collect_trash(rest_to_left_side)
        }
    }

    func use_whole_board_on_the_left_side(_ step: Fraction) {
//        precondition(step < self.normalizedWholeStep, "First step in row")

        // Determine rest from lest to right side
        if step == Fraction(1, 3) || step == Fraction(2, 3) {
            let carry = self.normalizedWholeStep - step
            self.state.used_boards += 1
            self.state.reusable_right.append(carry)
            if debug {
                print("Save reusable right: \(carry)")
            }
        }
    }

//    enum Side {
//        case left
//        case right
//    }

    func use_from_left_stash(_ step: Fraction) -> Bool {
        // FIXME: stash update self.state.reusable_left
        let used = self.use_from_stash(self.state.reusable_left, step)
        return used
    }

    func use_from_right_stash(_ step: Fraction) -> Bool {
        // FIXME: stash update self.state.reusable_left
        let used = self.use_from_stash(self.state.reusable_right, step)
        return used
    }

    func use_from_stash(_ stash: LayoutState.Stash, _ step: Fraction) -> Bool {
        var found = false

        if stash.count > 0 {
            let sorted_stash = stash.sorted()
            if debug {
                print("Checking stash of reusable {side} part: \(sorted_stash)")
            }

            if let cut = sorted_stash.first(where: { $0 > step }) {
//                has_it = [x for x in sorted_stash if x >= step]
//                if len(has_it) > 0
                // FIXME:
//                sorted_stash.remove(cut))
                found = true
                precondition(cut - step >= 0.0)

                if debug {
                    print("Found reusable {side} part: \(cut), using \(step * 1) of it")
                }
                self.collect_trash(cut - step)
            }
        }

        return found
    }

    func collect_trash(_ trash: Double) {
        // return rounded trash
        if trash > 0.0 {
            self.state.unusable_rest.append(trash)
            if debug {
                print("Collect trash \(trash))")
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
}
