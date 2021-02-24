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
        case latToolCutWidth = "lateral_tool_cut_width"
        case lonToolCutWidth = "longitudinal_tool_cut_width"
        case floorIndex = "floor_index"
    }

    var showCalculations: Bool = false

    /// One side value
    // Could be override per room
    var heightClearance = 0.0
    /// One side value
    // Could be override per room
    var lengthClearance = 0.0
    // Could be override per room
    var minLastRowHeight = 60.0
    // Could be override per room
    var desiredLastRowHeight = 100.0
    // Could be override per room, in %/100
    var coverMargin = 0.05
    // Tool cut width in mm
    var latToolCutWidth = 2.0
    // Tool cut width in mm
    var lonToolCutWidth = 3.0
    // Seleced floor index for particular calculation
    var floorIndex: Int?

    struct Size: Codable {
        /// Length, from left to right
        var width = 0.0
        /// Count from top to bottom
        var height = 0.0
    }

    struct RoomConfig: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case size
            case heightClearance = "height_clearance"
            case lengthClearance = "length_clearance"
            case firstBoard = "first_board"
            case coverMargin = "cover_margin"
            case minLastRowHeight = "min_last_row_height"
            case desiredLastRowHeight = "desired_last_row_height"
        }

        var name: String = ""
        var size: Size
        // TODO: add enum decode
        //        var first_board: FirstBoard = .one_3 // 1, 1/3, 2/3
        // free joints
        // regular joints
        var firstBoard = ""

        var heightClearance: Double?
        var lengthClearance: Double?
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
            case pricePerM2 = "price_per_msq"
            case packWeight = "pack_weight"
        }

        var type = ""
        var name = ""
        var pricePerM2: Double?
        var packWeight: Double?
        var boardSize: Size
        // One of the following must be set
        // If both set, verification is done using all values
        var packArea: Double?
        var boardsPerPack: Int?
    }

    var floorChoices = [FloorConfig]()

    @frozen enum ValidationError: Error {
        case badFloorIndex(String)
    }

    public func validate() throws {
        if let idx = self.floorIndex {
            if idx >= self.floorChoices.count {
                throw ValidationError.badFloorIndex("Zero based floor_index (\(idx)) must be less than nuber of floor choices (\(self.floorChoices.count)")
            }
        }
    }
}
