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
        
        var reusable_left = [Fraction]()
        var reusable_right = [Fraction]()
        var unusable_rest = [Fraction]()
        
        var used_boards = 0
        
        var unused_height_on_first_row: Double = 0.0
        var unused_height_on_last_row: Double = 0.0
        var total_rows = 0 //self.calculate_rows()
    }
    
    init(_ config: Config) {
        self.config = config
    }
    
    let config: Config
    var state: LayoutState!
    var layoutData: LayoutData!

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
        
        return RawReport()
    }

    // TODO: Rename to nextRowFirstBoardLength()
    func next_deck_step(_ start: Fraction, _ rowCount: Int) -> Fraction {
        let step = Fraction(1, 3)
        let r = rowCount % 3
        
        var nexts = start + step + step * Double(r)
        if nexts > 1.0 {
            nexts -= Fraction(1, 1)
        }
        
        return nexts
    }
    
    func use_whole_board_on_the_right_side(_ step: Fraction) {
        // Whole board was used as last one on the right
        let rest_to_left_side = 1.0 - step
        self.state.used_boards += 1
        // Save usable rest from right which can be used on left side
        
        assert(rest_to_left_side != 0.0)
        
        // Collect usable only if it grater than smallest step for the last which 1/3 for the deck layout
        if rest_to_left_side >= Fraction(1, 3) {
            if debug {
                print("Collect reusable left: {round(rest_to_left_side, 4)}")
            }
            self.state.reusable_left.append(Fraction(rest_to_left_side))
        } else {
            self.collect_trash(rest_to_left_side)
        }
    }
    
    func use_whole_board_on_the_left_side(_ step: Fraction) {
        // Determine rest from lest to right side
        if step == Fraction(1, 3) || step == Fraction(2, 3) {
            let carry = 1.0 - step
            self.state.used_boards += 1
            self.state.reusable_right.append(carry)
            if debug {
                print("Collect reusable right: {round(carry, 4)}")
            }
        }
    }
    
    enum Side {
        case left
        case right
    }
    
    func use_from_stash(_ side: Side, _ step: Fraction) -> Bool {
        var found = false
//        if side == .left {
//            stash = self.state.reusable_left
//        } else {
//            stash = self.state.reusable_right
//        }
//        
//        if len(stash) > 0 {
//            stash.sort()
//            if debug {
//                print("Checking stash of reusable {side} part: {[round(x*1.0, 4) for x in stash]}")
//            }
//            
//            has_it = [x for x in stash if x >= step]
//            if len(has_it) > 0
//                stash.remove(has_it[0])
//                found = True
//            
//            assert (has_it[0] - step) >= 0.0
//            
//            if debug {
//                print("Found reusable {side} part: {round(has_it[0]*1.0, 4)}, using {round(step*1.0, 4)}")
//            }
//            self.collect_trash(has_it[0] - step)
//        }
        
        return found
    }
    
    func collect_trash(_ trash: Double) {
        // return rounded trash
        if trash > 0.0 {
            self.state.unusable_rest.append(trash)
            if debug {
                print("Collect trash {round(frtr*1.0, 6)}")
            }
        } else {
            if debug {
                print("Trash is 0")
            }
        }
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
            print("Preliminary last row height: {self.last_row_height}")
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
        }
        
        self.state.unused_height_on_first_row = board_height - self.state.first_row_height
        self.state.unused_height_on_last_row = board_height - self.state.last_row_height
        
//        self.print(f'Total rows: {total_rows}')
//        self.print(f'First row height: {self.first_row_height}mm')
//        self.print(f'Middle height: {self.board_height}mm')
//        self.print(f'Last row height: {self.last_row_height}mm')
        
        var total_height = self.state.first_row_height + board_height * total_rows + self.state.last_row_height
        
        var N = 0
        if self.state.first_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
        if self.state.last_row_height > 0.0 {
            total_height -= board_height
            N += 1
        }
//        self.print(f'Total height: {self.first_row_height} + {self.board_height}*{total_rows-N} + {self.last_row_height} = {total_height}mm')
//        self.print(f'(You need to add both side clearance: {self.side_clearance}mm)')
//        self.print(f'Unused height from first row: {self.unused_height_on_first_row}mm')
//        self.print(f'Unused height from last row: {self.unused_height_on_last_row}mm')
        return Int(total_rows)
    }
}

extension Double {
    init(_ nom: Int, _ denom: Int) {
        self = Double(nom)/Double(denom)
    }
    
    init(_ nom: Double, _ denom: Double) {
        self = nom/denom
    }
}
