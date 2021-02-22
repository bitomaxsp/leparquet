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
            let choice = self.config.floorChoices[idx]
            for room in self.config.rooms {
                let input = LayoutInput(self.config, choice, room)
                let engine = RowLayoutEngine(input, debug: self.debug)
                let rawReport = engine.layout()
                report.add(rawReport, forRoom: room, withChoice: choice)
            }
        } else {
            for choice in self.config.floorChoices {
                for room in self.config.rooms {
                    let input = LayoutInput(self.config, choice, room)
                    let engine = RowLayoutEngine(input, debug: self.debug)
                    let rawReport = engine.layout()
                    report.add(rawReport, forRoom: room, withChoice: choice)
                }
            }
        }

        return report
    }
}
