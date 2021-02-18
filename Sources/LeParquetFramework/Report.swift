//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public struct Report {
    func add(_ rawReport: RawReport, forRoom room: Config.RoomConfig, withChoice floor: Config.FloorConfig) {
        Swift.print("Add report: room:\(room.name), Floor:\(floor.type)")
    }

    public func print() {}
}
