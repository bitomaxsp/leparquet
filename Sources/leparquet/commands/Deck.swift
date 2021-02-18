//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import ArgumentParser
import Foundation
import LeParquetFramework
import Yams

extension LeParquet {
    struct Deck: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Calculate deck layout",
                                                        shouldDisplay: true)

        @Argument(help: "YAML configuration file with rooms and materials")
        var configPath: String

        mutating func run() throws {
            print("Loading config \(self.configPath)")

            let decoder = YAMLDecoder()

            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let config = try decoder.decode(Config.self, from: data)

            let layout = DeckParquetLayout(config: config)
            layout.calculate()
            let report = layout.report
            report.print()
        }
    }
}
