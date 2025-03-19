import ArgumentParser
import Foundation
import LeParquetFramework
import Yams

extension LeParquet {
    struct Layout: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Calculate deck layout",
                                                        shouldDisplay: true)

        enum Verbose: EnumerableFlag {
            case verbose
        }

        @Flag(help: "Output verbose calculations. Overrides config value")
        var verbose: Verbose?

        @Argument(help: "YAML configuration file with rooms and materials")
        var configPath: String

        mutating func run() throws {
            print("Loading config \(self.configPath)")

            let decoder = YAMLDecoder()
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let config = try decoder.decode(Config.self, from: data)
            try config.validate()

            let layout = LeParquetFramework(config: config, verbose: self.verbose == nil ? nil : true)
            let report = try layout.calculate()
            report.generateFiles()
            report.generateGraphics()
        }
    }
}
