import ArgumentParser
import Foundation

extension LeParquet {
    struct Version: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the current version of LeParquet")

//        static var value: String { SwiftLintFramework.Version.current.value }
        static var value: String { "0.1" }

        mutating func run() throws {
            print(Self.value)
        }
    }
}
