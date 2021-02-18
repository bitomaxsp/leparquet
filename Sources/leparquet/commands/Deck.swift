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
            print("Loading config \(configPath)")

            let decoder = YAMLDecoder()

            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            //            userInfo: [CodingUserInfoKey(rawValue: "showCalculations")!: Config.self
            let config = try decoder.decode(Config.self, from: data)
            print(config.floorChoices)

            let layout = DeckParquetLayout()
        }
    }
}
