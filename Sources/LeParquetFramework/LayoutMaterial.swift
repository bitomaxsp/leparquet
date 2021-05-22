import Foundation

struct LayoutMaterial {
    typealias Size = Config.Size
    typealias Layout = Config.Layout

    static var MinFreeJointsBoardWidth = 300.0 // mm

    init(_ floor: Config.Floor, _ layout: Layout) {
        self.layout = layout
        let area = floor.boardSize.height * floor.boardSize.width
        self.board = LayoutMaterial.Board(size: floor.boardSize, area: Measurement(value: area, unit: UnitArea.squareMillimeters))
        let packArea = floor.packArea == nil ? nil : Measurement(value: floor.packArea!, unit: UnitAreaPerPack.squareMeters)
        let bpp = floor.boardsPerPack == nil ? nil : Measurement<UnitBoardsPerPack>(value: Double(floor.boardsPerPack!), unit: .boards)

        var weight: Measurement<UnitMass>?
        if let m = floor.packWeight {
            weight = Measurement<UnitMass>(value: m, unit: .kilograms)
        }

        self.pack = LayoutMaterial.Pack(area: packArea, boardsCount: bpp, pricePerM2: floor.pricePerM2, weight: weight)

        self.type = floor.type
        self.name = floor.name
        self.notes = floor.notes
    }

    struct Board {
        let size: Size
        let area: Measurement<UnitArea>
    }

    struct Pack {
        let area: Measurement<UnitAreaPerPack>?
        let boardsCount: Measurement<UnitBoardsPerPack>?
        let pricePerM2: Double?
        let weight: Measurement<UnitMass>?
    }

    let layout: Layout
    let board: Board
    let pack: Pack
    let type: String
    let name: String
    let notes: String?

    /// Amount of normalized distance between joints of adjacent rows
    var adjacentRowsShift: Double {
        switch self.layout.joints {
        case .brick: return 1.0 / 2.0
        case .deck: return 1.0 / 3.0
        case .freeJoints: return Self.MinFreeJointsBoardWidth / self.board.size.width // rest from prev row, if > 300mm .
        case .fixedJoints: return self.board.size.height / self.board.size.width // fixed, set by user
        case .aligned: return 0.0
        }
    }
}
