//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

public struct Config: Codable {
    enum CodingKeys: String, CodingKey {
        case showCalculations = "show_calculations"
        case heightClearance = "height_clearance"
        case lengthClearance = "length_clearance"
        case minLastRowHeight = "min_last_row_height"
        case desiredLastRowHeight = "desired_last_row_height"
        case coverMargin = "cover_margin"
        case rooms
        case floorChoices = "floor_choices"
    }

    var showCalculations: Bool = false

    /// One side value
    var heightClearance = 0.0
    /// One side value
    var lengthClearance = 0.0

    // Could be override per room
    var minLastRowHeight = 60.0
    // Could be override per room
    var desiredLastRowHeight = 100.0
    // Could be override per room, in %/100
    var coverMargin = 0.05

    struct Size: Codable {
        var height = 0.0
        var width = 0.0
        var cgsize: CGSize {
            CGSize(width: self.width, height: self.height)
        }
    }

    struct RoomConfig: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case size
            case firstBoard = "first_board"
            case coverMargin = "cover_margin"
            case minLastRowHeight = "min_last_row_height"
            case desiredLastRowHeight = "desired_last_row_height"
        }

        enum FirstBoard: String, CaseIterable, Codable {
            case full
            case one_3 = "1/3"
            case two_3 = "2/3"
        }

        var name: String = ""
        var size: Size
        // TODO: add enum decode
        //        var first_board: FirstBoard = .one_3 // 1, 1/3, 2/3
        var firstBoard = ""
        var coverMargin: Double?
        var minLastRowHeight: Double?
        var desiredLastRowHeight: Double?
    }

    var rooms = [RoomConfig]()

    struct FloorConfig: Codable {
        enum CodingKeys: String, CodingKey {
            case type
            case boardSize = "board_size"
            case packArea = "pack_area"
            case boardsPerPack = "boards_per_pack"
        }

        var type = ""
        var boardSize: Size
        // One of the following must be set
        // If both set, verification is done using all values
        var packArea: Double?
        var boardsPerPack: Double?
    }

    var floorChoices = [FloorConfig]()
}
