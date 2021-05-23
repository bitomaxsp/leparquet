import Foundation

let maxToolCutWidth_mm = 5.0
let maxClearance_mm = 30.0

struct LayoutEngineConfig {
    typealias Size = Config.Size

    let roomName: String
    let floorName: String
    let floorType: String
    /// This size real room size, mm
    let actualRoomSize: Size
    /// This size is actualRoomSize - side clearance, mm
    let effectiveRoomSize: Size
    /// Positive values means that rectangle to which insets are applied is reduced by them
    let insets: Insets

    let minLastRowHeight: Double
    let desiredLastRowHeight: Double
    let coverMaterialMargin: Double
    let material: LayoutMaterial
    let normalizedLatToolCutWidth: Double
    // real sizes in mm
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
        self.floorName = floor.name
        self.floorType = floor.type
        self.actualRoomSize = room.size

        let topInset = room.heightClearance ?? config.heightClearance
        let sideInset = room.widthClearance ?? config.widthClearance
        self.insets = Insets(top: topInset, left: sideInset, bottom: topInset, right: sideInset)

        self.effectiveRoomSize = Size(width: self.actualRoomSize.width - 2.0 * sideInset, height: self.actualRoomSize.height - 2.0 * topInset)

        self.minLastRowHeight = room.minLastRowHeight ?? config.minLastRowHeight
        self.desiredLastRowHeight = { (_ minLast: Double) -> Double in
            var desired = room.desiredLastRowHeight ?? config.desiredLastRowHeight
            if desired > 0.0, desired < minLast {
                desired = minLast
            }
            return desired
        }(self.minLastRowHeight)

        let margin = room.coverMargin ?? config.coverMargin
        precondition(margin >= 0.0 && margin <= 0.5)
        self.coverMaterialMargin = margin
        self.material = LayoutMaterial(floor, room.layout ?? config.layout)

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

                if d.size.height > self.material.board.size.height {
                    throw Errors.validationFailed("Door rectangle height must be <= board height. Got: \(d.size.height) > \(self.material.board.size.height)")
                }

                if d.size.height.isZero || d.size.width.isZero {
                    throw Errors.validationFailed("Door \(d.name) size must not be zero")
                }

                // NOTE: For doors along horizontal edges we normalize displacement and width to board width, height to board height
                // NOTE: For doors along vertical edges we normalize displacement and width to board height, height to board width
                let widthNorm = (d.edge.isHorizontal) ? 1.0 / self.material.board.size.width : 1.0 / self.material.board.size.height
                let heightNorm = (d.edge.isHorizontal) ? 1.0 / self.material.board.size.height : 1.0 / self.material.board.size.width
                let widthInsetCompensation = (d.edge.isHorizontal) ? sideInset : topInset
                let heightInsetCompensation = (d.edge.isHorizontal) ? topInset : sideInset

                // NOTE: We need to account clearance as door rectangle is measured from the actual wall
                let height = (d.size.height + heightInsetCompensation)
                let width = d.size.width

                // NOTE: d.displacement is from real wall hense we REMOVE clearance
                let xStart = (d.displacement - widthInsetCompensation)
                let doorFrame = CGRect(x: xStart, y: 0.0, width: width, height: height)

                let newDoor = Door(name: d.name, edge: d.edge, frame: doorFrame, normalize: true, wn: widthNorm, hn: heightNorm)
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
        try self.validate(config, floor, room)
    }

    private func validate(_ config: Config, _: Config.Floor, _ room: Config.Room) throws {
        // tool cut with limit 5mm.
        if config.latToolCutWidth > maxToolCutWidth_mm {
            throw Errors.validationFailed("latToolCutWidth [\(config.latToolCutWidth)] <= \(maxToolCutWidth_mm)mm")
        }
        if config.lonToolCutWidth > maxToolCutWidth_mm {
            throw Errors.validationFailed("lonToolCutWidth [\(config.lonToolCutWidth)] <= \(maxToolCutWidth_mm)mm")
        }

        if let hc = room.heightClearance, hc > maxClearance_mm {
            throw Errors.validationFailed("Room height clearance [\(hc)] must be <= \(maxClearance_mm)mm")
        }
        if let lc = room.widthClearance, lc > maxClearance_mm {
            throw Errors.validationFailed("Room width clearance [\(lc)] must be <= \(maxClearance_mm)mm")
        }

        if config.heightClearance > maxClearance_mm {
            throw Errors.validationFailed("Global height clearance [\(config.heightClearance)] must be <= \(maxClearance_mm)mm")
        }
        if config.widthClearance > maxClearance_mm {
            throw Errors.validationFailed("Global width clearance [\(config.widthClearance)] must be <= \(maxClearance_mm)mm")
        }
    }
}
