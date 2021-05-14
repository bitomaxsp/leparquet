import Foundation

public class Report {
    var reports = [RawReport]()

    func add(_ rawReport: RawReport) {
        do {
            try rawReport.validate()
            print("Add report for \(rawReport.engineConfig.roomName) room with floor \(rawReport.engineConfig.floorType)")
            self.reports.append(rawReport)
        } catch {
            print("Report for \(rawReport.engineConfig.roomName) room with floor \(rawReport.engineConfig.floorType) ingnored. Validation failed with error \(error)")
        }
    }

    public func generateFiles() {
        for report in self.reports {
            let s = report.output()
            let filename = URL(fileURLWithPath: "./\(report.engineConfig.roomName)+\(report.engineConfig.floorType).txt")

            do {
                try s.write(to: filename, atomically: true, encoding: .utf8)
                print("Printed \(filename.lastPathComponent) report")
                let instructions = report.instructionList()
                let instructionsURL = URL(fileURLWithPath: "./intructions-\(report.engineConfig.roomName)+\(report.engineConfig.floorType).txt")
                try instructions.write(to: instructionsURL, atomically: true, encoding: .utf8)
            } catch {
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                print("Error writing file \(filename): \(error)")
            }
        }
    }
}
