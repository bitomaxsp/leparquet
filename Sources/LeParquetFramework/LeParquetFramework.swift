//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

// var debug = true

// TODO: rename to Factory
public final class LayoutProducer {
    let config: Config
    let debug: Bool

    public init(config: Config, verbose: Bool?) {
        self.config = config
        if let v = verbose {
            self.debug = v
        } else {
            self.debug = config.showCalculations
        }
    }

    public func calculate() -> Report {
        let report = Report()

        if let idx = self.config.floorIndex {
            let floor = self.config.floorChoices[idx]
            self.calculateRoom(for: floor, to: report)
        } else {
            for floor in self.config.floorChoices {
                self.calculateRoom(for: floor, to: report)
            }
        }

        return report
    }

    private func calculateRoom(for floor: Config.FloorConfig, to report: Report) {
        for room in self.config.rooms {
            let input = LayoutInput(self.config, floor, room)
            let engine = RowLayoutEngine(input, debug: self.debug)
            let rawReport = engine.layout()
            report.add(rawReport)
        }
    }
}
