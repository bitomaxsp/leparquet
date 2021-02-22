//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public struct Report {
    func add(_ rawReport: RawReport, forRoom room: Config.RoomConfig, withChoice floor: Config.FloorConfig) {
        Swift.print("\nAdd report for \(room.name) room with floor \(floor.type)")

//        var f = FileHandle(forWritingAtPath: "./\(room.name)+\(floor.type)")
//        f?.write(<#T##data: Data##Data#>)
    }

    public func print() {}
}
