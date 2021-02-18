//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public class DeckParquetLayout {
    let config: Config

    public init(config: Config) {
        self.config = config

//        self.side_clearance = 10.0
//        self.roomW = roomW - 2.0 * self.side_clearance
//        self.roomL = roomL - 2.0 * self.side_clearance
//
//        self.min_last_height = 60.0
//        self.desired_last_height = 100.0
//
//        self.cover_margin = 0.050  # %
//
//        self.one_board_area_m2 = self.board_length * self.board_height / 1e6
//        print(f'One board area: {self.one_board_area_m2}, brd/pack:{self.pack_area_m2/self.one_board_area_m2}')
//
//        self.last_row_height = 0
//        self.first_row_height = self.board_height
//
//        self.rows: List[List[Fraction]] = list()
//
//        self.reusable_left: List[Fraction] = list()
//        self.reusable_right: List[Fraction] = list()
//        self.unusable_rest: List[Fraction] = list()
//        self.used_boards = 0
//
//        self.unused_height_on_first_row = 0.0
//        self.unused_height_on_last_row = 0.0
//
//        self.total_rows = self.calculate_rows()
//
//        // DO NO USE IN COMPUTATION
//        self.calc_covered_area = roomW * roomL * 1e-6
//        self.calc_covered_area_with_margin = self.calc_covered_area * (1.0 + self.cover_margin)
    }

    public var report: Report {
        self.doReport()
    }

    public func calculate() {
        let report = Report()

        for choice in self.config.floorChoices {
            for room in self.config.rooms {
                let rawReport = self.calculateDeck(DeckData(choice, room))
                report.add(rawReport, forRoom: room, withChoice: choice)
            }
        }
    }

    func calculateDeck(_: DeckData) -> RawReport {
        return RawReport()
    }

    func doReport() -> Report {
        return Report()
    }
}
