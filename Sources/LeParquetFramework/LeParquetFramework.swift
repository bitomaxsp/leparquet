//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

var debug = true

public final class DeckParquetLayout: GenericRowLayout {
    public init(config: Config) {
        super.init(config)
        debug = config.showCalculations
    }

    public var report: Report {
        self.doReport()
    }

    func doReport() -> Report {
        return Report()
    }
}
