import Foundation

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

    public func calculate() throws -> Report {
        let report = Report()

        if let idx = self.config.floorIndex {
            let floor = self.config.floorChoices[idx]
            try self.calculateRoom(for: floor, to: report)
        } else {
            for floor in self.config.floorChoices {
                try self.calculateRoom(for: floor, to: report)
            }
        }

        return report
    }

    private func calculateRoom(for floor: Config.Floor, to report: Report) throws {
        for room in self.config.rooms {
            let input = try LayoutEngineConfig(self.config, floor, room)
            let engine = RowLayoutEngine(withConfig: input, debug: self.debug)
            let rawReport = try engine.layout()
            report.add(rawReport)
        }
    }
}
