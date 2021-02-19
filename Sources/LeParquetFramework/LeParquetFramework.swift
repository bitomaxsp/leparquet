//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

var debug = true

// TODO: rename to Factory
public final class DeckParquetLayout {
    let config: Config

    public init(config: Config) {
        self.config = config
        debug = config.showCalculations
    }

    public func calculate() {
        let report = Report()

        for choice in self.config.floorChoices {
            for room in self.config.rooms {
                let input = LayoutInput(self.config, choice, room)
                let engine = RowLayoutEngine(input)
                let rawReport = engine.layout()
                report.add(rawReport, forRoom: room, withChoice: choice)
            }
        }
    }

    public var report: Report {
        self.doReport()
    }

    func doReport() -> Report {
        return Report()
    }
}
