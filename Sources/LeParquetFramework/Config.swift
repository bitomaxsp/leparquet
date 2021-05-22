import Foundation

public struct Config: Codable {
    enum CodingKeys: String, CodingKey {
        case showCalculations = "show_calculations"
        case heightClearance = "height_clearance"
        case widthClearance = "width_clearance"
        case minLastRowHeight = "min_last_row_height"
        case desiredLastRowHeight = "desired_last_row_height"
        case coverMargin = "cover_margin"
        case rooms
        case floorChoices = "floor_choices"
        case latToolCutWidth = "lateral_tool_cut_width"
        case lonToolCutWidth = "longitudinal_tool_cut_width"
        case floorIndex = "floor_index"
        case layout
    }

    var showCalculations: Bool = false

    /// One side value
    // Could be override per room
    var heightClearance = 0.0
    /// One side value
    // Could be override per room
    var widthClearance = 0.0
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
    // Global layout for all rooms, override per room is possible.
    var layout: Layout

    struct Size: Codable, Equatable {
        /// Length, from left to right
        var width = 0.0
        /// Count from top to bottom
        var height = 0.0
    }

    enum Joints: String, CaseIterable, Codable {
        case brick
        case deck
        case freeJoints = "free joints"
        case fixedJoints = "fixed joints"
        case aligned

        func validFirst() -> [FirstBoard] {
            switch self {
            case .brick: return [.full, .half]
            case .deck: return [.one_3, .two_3, .full]
            default: return [.full]
            }
        }
    }

    enum FirstBoard: String, CaseIterable, Codable {
        case full
        case half = "1/2"
        case one_3 = "1/3"
        case two_3 = "2/3"

        func lengthAsDouble() -> Double {
            switch self {
            case .full: return 1.0
            case .half: return 1.0 / 2.0
            case .one_3: return 1.0 / 3.0
            case .two_3: return 2.0 / 3.0
            }
        }
    }

    struct Layout: Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case joints = "type"
            case firstBoard = "first_board"
            case angle
        }

        var joints: Joints
        var firstBoard: FirstBoard
        /// Degrees. 0˚ is 3 o'clock, 90˚ is 12 o'clock, etc.
        let angle = 0.0

        func validate() throws {
            let first = self.joints.validFirst().first { $0 == self.firstBoard }
            guard let _ = first else {
                throw ValidationError.invalidLayout("Invalid first baord (\(self.firstBoard)), must be one of (\(self.joints.validFirst())")
            }
            let r = 0.0 ..< 360.0
            if !r.contains(self.angle) {
                throw ValidationError.invalidLayout("Andgle must be in range: \(r)")
            }
        }
    }

    struct Room: Codable {
        enum CodingKeys: String, CodingKey {
            case name
            case size
            case doors
            case layout
            case heightClearance = "height_clearance"
            case widthClearance = "width_clearance"
            case coverMargin = "cover_margin"
            case minLastRowHeight = "min_last_row_height"
            case desiredLastRowHeight = "desired_last_row_height"
        }

        // Describe door position and size for the room
        struct Door: Codable {
            enum CodingKeys: String, CodingKey {
                case name
                case edge
                case size
                case displacement
            }

            var name: String
            /// NOTE: Protrusion must be measured from the wall
            var size: Size
            var edge: Edge

            /// NOTE: Must be measured from the wall
            var displacement: Double
        }

        var name: String = ""
        var size: Size

        // Layout override
        var layout: Layout?

        // This might be optional
        var doors: [Door]?

        var heightClearance: Double?
        var widthClearance: Double?
        var coverMargin: Double?
        var minLastRowHeight: Double?
        var desiredLastRowHeight: Double?
    }

    var rooms = [Room]()

    struct Floor: Codable {
        enum CodingKeys: String, CodingKey {
            case type
            case notes
            case boardSize = "board_size"
            case packArea = "pack_area"
            case boardsPerPack = "boards_per_pack"
            case pricePerM2 = "price_per_msq"
            case packWeight = "pack_weight"
        }

        var type = ""
        var name = ""
        var notes: String?
        var pricePerM2: Double?
        var packWeight: Double?
        var boardSize: Size
        // One of the following must be set
        // If both set, verification is done using all values
        var packArea: Double?
        var boardsPerPack: Int?
    }

    var floorChoices = [Floor]()

    public func validate() throws {
        if let idx = self.floorIndex {
            if idx >= self.floorChoices.count {
                throw ValidationError.badFloorIndex("Zero based floor_index (\(idx)) must be less than nuber of floor choices (\(self.floorChoices.count)")
            }
        }

        try self.layout.validate()
    }
}
