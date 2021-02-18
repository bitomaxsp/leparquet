//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

let debug = true

public final class DeckParquetLayout: GenericRowLayout {

    public init(config: Config) {
        super.init(config)
    }

    public var report: Report {
        self.doReport()
    }

    
    func doReport() -> Report {
        return Report()
    }
    
}

