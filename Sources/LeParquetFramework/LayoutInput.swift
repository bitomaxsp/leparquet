//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-18.
//

import Foundation

// TODO: rename
struct LayoutInput {
    typealias Size = Config.Size

    struct Material {
        init(_ floor: Config.FloorConfig) {
            self.board = Material.Board(size: floor.boardSize, area: floor.boardSize.height * floor.boardSize.width * 1e-6)
            self.pack = Material.Pack(area: floor.packArea, boardsCount: floor.boardsPerPack)
        }

        struct Board {
            let size: Size
            let area: Double // m2
        }

        struct Pack {
            let area: Double? // m2
            let boardsCount: Int?
        }

        let board: Board
        let pack: Pack
    }

    enum FirstBoard: String, CaseIterable, Codable {
        case full
        case one_3 = "1/3"
        case two_3 = "2/3"

        func lengthAsDouble() -> Double {
            switch self {
            case .full: return 1.0
            case .one_3: return 1.0 / 3.0
            case .two_3: return 2.0 / 3.0
            }
        }
    }

    let roomName: String
    let floorName: String
    let actualRoomSize: Size
    /// This size is actualRoomSize - side clearance
    let effectiveRoomSize: Size

    let firstBoard: FirstBoard
    let minLastRowHeight: Double
    let desiredLastRowHeight: Double
    let coverMaterialMargin: Double
    let material: Material
    let normalizedLatToolCutWidth: Double
    let lonToolCutWidth: Double

    // DO NO USE IN COMPUTATIONS
    let calc_covered_area: Double
    let calc_covered_area_with_margin: Double

    init(_ config: Config, _ floor: Config.FloorConfig, _ room: Config.RoomConfig) {
        self.roomName = room.name
        self.floorName = floor.type
        self.actualRoomSize = room.size
        // Fallback to 1/3 if user input is invalid
        self.firstBoard = FirstBoard(rawValue: room.firstBoard) ?? .one_3

        let topInset = room.heightClearance ?? config.heightClearance
        let sideInset = room.lengthClearance ?? config.lengthClearance
        self.effectiveRoomSize = Size(width: self.actualRoomSize.width - 2.0 * sideInset, height: self.actualRoomSize.height - 2.0 * topInset)

        self.minLastRowHeight = room.minLastRowHeight ?? config.minLastRowHeight
        self.desiredLastRowHeight = room.desiredLastRowHeight ?? config.desiredLastRowHeight
        let margin = room.coverMargin ?? config.coverMargin
        precondition(margin >= 0.0 && margin <= 0.5)
        self.coverMaterialMargin = margin
        self.material = Material(floor)

        self.normalizedLatToolCutWidth = config.latToolCutWidth / self.material.board.size.width
        self.lonToolCutWidth = config.lonToolCutWidth

        // DO NO USE IN COMPUTATION
        self.calc_covered_area = Double(self.actualRoomSize.width * self.actualRoomSize.height * 1e-6)
        self.calc_covered_area_with_margin = self.calc_covered_area * (1.0 + self.coverMaterialMargin)
    }
}
