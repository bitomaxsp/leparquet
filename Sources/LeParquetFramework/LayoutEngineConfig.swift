import Foundation

struct LayoutEngineConfig {
    typealias Size = Config.Size

    struct Material {
        init(_ floor: Config.Floor) {
            let area = floor.boardSize.height * floor.boardSize.width
            self.board = Material.Board(size: floor.boardSize, area: Measurement(value: area, unit: UnitArea.squareMillimeters))
            let packArea = floor.packArea == nil ? nil : Measurement(value: floor.packArea!, unit: UnitAreaPerPack.squareMeters)
            let bpp = floor.boardsPerPack == nil ? nil : Measurement<UnitBoardsPerPack>(value: Double(floor.boardsPerPack!), unit: .boards)

            var weight: Measurement<UnitMass>?
            if let m = floor.packWeight {
                weight = Measurement<UnitMass>(value: m, unit: .kilograms)
            }

            self.pack = Material.Pack(area: packArea, boardsCount: bpp, pricePerM2: floor.pricePerM2, weight: weight)

            self.type = floor.type
            self.name = floor.name
            self.notes = nil
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

        let board: Board
        let pack: Pack
        let type: String
        let name: String
        let notes: String?
    }

    // Door in the room need to be taken into account
    struct Door {
        /// Edge which door rect is in
        let edge: Edge
        /// door frame. y coord always 0 as door protrudes covering floor rectangle
        let frame: CGRect
        /// if frame values are normalized wrt board dimentions
        /// width (longest dimension) normalized to board width for top and bottom doors
        /// height (shortest dimension) normalized to board height for top and bottom doors
        /// and for left and right it's wice versa
        let nomalized: Bool
        /// Normalized range covered by board along longest dimention. See nomalized for normalization notes.
        let longRange: Range<Double>
    }

    let roomName: String
    let floorName: String
    let actualRoomSize: Size
    /// This size is actualRoomSize - side clearance
    let effectiveRoomSize: Size
    /// Positive values mens that rectangle to which insets are applied is reduced by them
    let insets: Insets

    let firstBoard: Config.Room.FirstBoard
    let minLastRowHeight: Double
    let desiredLastRowHeight: Double
    let coverMaterialMargin: Double
    let material: Material
    let normalizedLatToolCutWidth: Double
    let lonToolCutWidth: Double
    var doors: [Edge: [Door]]?
    /*
     NOTE: Maximum amount of protrussion to the left.
     This is the amount by which we shift whole floor left so that door passages on the left are covered.
     Boards that doesn't protrude are cut left by the amount of protrusion.
     This protrusion includes side clearance
     */
    let maxNormalizedLeftProtrusion: Double

    // DO NO USE IN COMPUTATIONS
    let calc_covered_area: Double
    let calc_covered_area_with_margin: Double

    init(_ config: Config, _ floor: Config.Floor, _ room: Config.Room) throws {
        self.roomName = room.name
        self.floorName = floor.type
        self.actualRoomSize = room.size
        // Fallback to 1/3 if user input is invalid
        self.firstBoard = room.firstBoard

        let topInset = room.heightClearance ?? config.heightClearance
        let sideInset = room.lengthClearance ?? config.lengthClearance
        self.insets = Insets(top: topInset, left: sideInset, bottom: topInset, right: sideInset)

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

        var maxLeft = 0.0
        if let doors = room.doors {
            self.doors = [Edge: [Door]]()
            for d in doors {
                if self.doors![d.edge] == nil {
                    self.doors?.updateValue([Door](), forKey: d.edge)
                }
                // NOTE: For doors along horizontal edges we normalize displacement and width to board width, height to board height
                // NOTE: For doors along vertical edges we normalize displacement and width to board height, height to board width
                let kPositionNorm = (d.edge == .top || d.edge == .bottom) ? 1.0 / self.material.board.size.width : 1.0 / self.material.board.size.height
                let widthNorm = (d.edge == .top || d.edge == .bottom) ? 1.0 / self.material.board.size.width : 1.0 / self.material.board.size.height
                let heightNorm = (d.edge == .top || d.edge == .bottom) ? 1.0 / self.material.board.size.height : 1.0 / self.material.board.size.width
                let widthInsetCompensation = (d.edge == .top || d.edge == .bottom) ? sideInset : topInset
                let heightInsetCompensation = (d.edge == .top || d.edge == .bottom) ? topInset : sideInset

                // NOTE: We need to account clearance as door rectangle is measured from the actual wall
                let height = (d.size.height + heightInsetCompensation) * heightNorm
                let width = d.size.width * widthNorm
                // NOTE: d.displacement is from real wall hense we REMOVE clearance
                let rangeStart = (d.displacement - widthInsetCompensation) * kPositionNorm
                let doorFrame = CGRect(x: rangeStart, y: 0.0, width: width, height: height)
                // Range must contain last door point hense use nextUp
                let range = rangeStart ..< (rangeStart + width).nextUp
                let newDoor = Door(edge: d.edge, frame: doorFrame, nomalized: true, longRange: range)
                self.doors![d.edge]?.append(newDoor)
                self.doors![d.edge]?.sort(by: { (lhs, rhs) -> Bool in
                    return lhs.frame.origin.x < rhs.frame.origin.x
                })

                // Find max left protrusion
                if d.edge == .left, maxLeft < ((d.size.height + heightInsetCompensation) * heightNorm) {
                    maxLeft = (d.size.height + heightInsetCompensation) * heightNorm
                }
            }
        }

        self.maxNormalizedLeftProtrusion = maxLeft

        try self.validate()
    }

    private func validate() throws {
        // TODO: tool cut with limit 5mm.
        // cleareance 30mm
        // TODO: check doors for intersections
        if let ddoors = self.doors {
            for (_, v) in ddoors {
                // We check that hight of the door rect is <= board height
                for d in v {
                    if d.frame.size.height > self.material.board.size.height {
                        throw Errors.validationFailed("Dorr rectangle height must be <= board height. Got: \(d.frame.size.height) > \(self.material.board.size.height)")
                    }
                }
            }
        }
    }
}
