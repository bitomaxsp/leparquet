import Foundation

struct LayoutEngineConfig {
    typealias Size = Config.Size

    struct Material {
        init(_ floor: Config.FloorConfig) {
            let area = floor.boardSize.height * floor.boardSize.width
            self.board = Material.Board(size: floor.boardSize, area: Measurement(value: area, unit: UnitArea.squareMillimeters))
            let packArea = floor.packArea == nil ? nil : Measurement(value: floor.packArea!, unit: UnitAreaPerPack.squareMeters)
            let bpp = floor.boardsPerPack == nil ? nil : Measurement<UnitBoardsPerPack>(value: Double(floor.boardsPerPack!), unit: .boards)
            self.pack = Material.Pack(area: packArea, boardsCount: bpp)
            self.type = floor.type
            self.name = floor.name
            self.pricePerM2 = floor.pricePerM2
            if let m = floor.packWeight {
                self.packWeight = Measurement<UnitMass>(value: m, unit: .kilograms)
            } else {
                self.packWeight = nil
            }
        }

        struct Board {
            let size: Size
            let area: Measurement<UnitArea>
        }

        struct Pack {
            let area: Measurement<UnitAreaPerPack>?
            let boardsCount: Measurement<UnitBoardsPerPack>?
        }

        let board: Board
        let pack: Pack
        let type: String
        let name: String
        let pricePerM2: Double?
        let packWeight: Measurement<UnitMass>?
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
