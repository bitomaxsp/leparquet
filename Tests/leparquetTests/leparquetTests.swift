@testable import LeParquetFramework
import XCTest
import Yams

enum TestError: String, Error {
    case unableToGetConfig
}

final class ConfigTests: XCTestCase {
    var decoder: YAMLDecoder!

    override func setUp() {
        self.decoder = YAMLDecoder()
    }

    func testRepoConfigIsValid() {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: "config.yaml"))
            let config = try self.decoder.decode(Config.self, from: data)
            XCTAssertNoThrow(try config.validate(), "Config calidation must be successful")
        } catch {
            XCTFail("Exception reading data or parsing a config")
        }
    }

    func testLayoutEngineConfig() {
        let configGet: (_ yaml: String) throws -> Config? = { yaml in
            do {
                let config = try self.decoder.decode(Config.self, from: yaml)
                XCTAssertNoThrow(try config.validate(), "Config calidation must be successful")
                return config
            } catch {
                XCTFail("Exception reading data or parsing a config")
            }
            throw TestError.unableToGetConfig
        }

        guard let config = try? configGet(validConfigData_OneFloor_OneRoom) else { return }

        let engineconfig = try! LayoutEngineConfig(config, config.floorChoices[0], config.rooms[0])

        XCTAssertEqual(engineconfig.roomName, config.rooms[0].name, "room name mismatch")
        XCTAssertEqual(engineconfig.floorName, config.floorChoices[0].name, "name mismatch")
        XCTAssertEqual(engineconfig.floorType, config.floorChoices[0].type, "type mismatch")

        let room = config.rooms[0]
        XCTAssertEqual(engineconfig.actualRoomSize, room.size, "Actual room size mismatch")

        let topInset = room.heightClearance ?? config.heightClearance
        let sideInset = room.widthClearance ?? config.widthClearance

        let effectiveSize = Config.Size(width: room.size.width - 2 * sideInset, height: room.size.height - 2 * topInset)
        XCTAssertEqual(engineconfig.effectiveRoomSize, effectiveSize, "Effective size mismatch")

        XCTAssertEqual(engineconfig.insets, Insets(top: topInset, left: sideInset, bottom: topInset, right: sideInset), "Insets mismatch")

        XCTAssertEqual(engineconfig.layout, config.layout)
        XCTAssertEqual(engineconfig.minLastRowHeight, room.minLastRowHeight ?? config.minLastRowHeight)
        XCTAssertEqual(engineconfig.desiredLastRowHeight, room.desiredLastRowHeight ?? config.desiredLastRowHeight)
        XCTAssertEqual(engineconfig.coverMaterialMargin, room.coverMargin ?? config.coverMargin)

        let floor = config.floorChoices[0]
        XCTAssertEqual(engineconfig.material.type, floor.type)
        XCTAssertEqual(engineconfig.material.name, floor.name)
        XCTAssertEqual(engineconfig.material.notes, nil)

        XCTAssertEqual(engineconfig.material.board.area.value, floor.boardSize.height * floor.boardSize.width)
        XCTAssertEqual(engineconfig.material.board.size, floor.boardSize)

        XCTAssertEqual(engineconfig.material.pack.area?.value, 2.72)
        XCTAssertEqual(engineconfig.material.pack.boardsCount?.value, 6)
        XCTAssertEqual(engineconfig.material.pack.pricePerM2, 780.0)
        XCTAssertEqual(engineconfig.material.pack.weight?.value, 20)

        XCTAssertEqual(engineconfig.normalizedLatToolCutWidth, config.latToolCutWidth / engineconfig.material.board.size.width)
        XCTAssertGreaterThanOrEqual(engineconfig.normalizedLatToolCutWidth, 0.0)
        XCTAssertLessThanOrEqual(engineconfig.normalizedLatToolCutWidth, 1.0)
        XCTAssertEqual(engineconfig.lonToolCutWidth, config.lonToolCutWidth)

        XCTAssertNotNil(engineconfig.doors)
        let doors = engineconfig.doors![.left]
        XCTAssertEqual(doors?.count, 1)
        let door = doors![0]
        XCTAssertEqual(door.name, "door1")
        XCTAssertEqual(door.edge, .left)
        XCTAssertEqual(door.nomalized, true)
        XCTAssertEqual(door.frame.size.width.native, 900.0 / floor.boardSize.height)
        XCTAssertEqual(door.frame.size.height.native, (35.0 + sideInset) / floor.boardSize.width)
        XCTAssertEqual(door.frame.origin.x.native, (170.0 - topInset) / floor.boardSize.height)

        // We have one door so we can use door value
        XCTAssertEqual(engineconfig.maxNormalizedLeftProtrusion, door.frame.size.height.native, "left protrusion mismatch")
    }

    func testLayoutEngineConfig_DesiredLastRowHeigh() {
        var config = yamlConfigWith(yaml: validConfigData_OneFloor_OneRoom)!
        config.desiredLastRowHeight = 0
        let engineconfig = try! LayoutEngineConfig(config, config.floorChoices[0], config.rooms[0])

        let room = config.rooms[0]

        XCTAssertEqual(engineconfig.minLastRowHeight, room.minLastRowHeight ?? config.minLastRowHeight)
        XCTAssertEqual(engineconfig.desiredLastRowHeight, room.desiredLastRowHeight ?? config.desiredLastRowHeight)
    }

    func testLayoutEngineConfig_DesiredLastRowHeigh_Capped() {
        var config = yamlConfigWith(yaml: validConfigData_OneFloor_OneRoom)!
        config.desiredLastRowHeight = 10
        let engineconfig = try! LayoutEngineConfig(config, config.floorChoices[0], config.rooms[0])

        let room = config.rooms[0]

        XCTAssertEqual(engineconfig.minLastRowHeight, room.minLastRowHeight ?? config.minLastRowHeight)
        XCTAssertEqual(engineconfig.desiredLastRowHeight, engineconfig.minLastRowHeight)
    }

    func testLayoutEngineConfig_DesiredLastRowHeigh_Taken() {
        var config = yamlConfigWith(yaml: validConfigData_OneFloor_OneRoom)!
        config.desiredLastRowHeight = 79
        let engineconfig = try! LayoutEngineConfig(config, config.floorChoices[0], config.rooms[0])

        let room = config.rooms[0]

        XCTAssertEqual(engineconfig.minLastRowHeight, room.minLastRowHeight ?? config.minLastRowHeight)
        XCTAssertEqual(engineconfig.desiredLastRowHeight, config.desiredLastRowHeight)
    }

    static var allTests = [
        ("testRepoConfigIsValid", testRepoConfigIsValid),
        ("testLayoutEngineConfig", testLayoutEngineConfig),
    ]
}

let validConfigData_OneFloor_OneRoom = """
---
# Set this to true to see how LeParquet does it's calculations
show_calculations: false

# Amount of clearance to take into consider when laying out boards.
# This value is for one side. Taken into account on top/bottom edges.
# Could be overriden per room
height_clearance: 11
# Same as above but for the last and right sides
# Could be overriden per room
width_clearance: 17

# Minimum amoung of last boards height in mm. Usually it must be > 60mm
# Could be overriden per room
min_last_row_height: 77.0
# You could specify last row (the one at the bottom of the room) board height in mm.
# Could be overriden per room
desired_last_row_height: 100.0
# This is not usind in layout computation.
# Specify how large area overhead you expect per room to compare it with reality.
# Could be overriden per room, in %/100
cover_margin: 0.05

# Optional: use it if you want to limit calculation to only selected floor type
# This is zero-based index of the floor in floor array
# If commented then leparquet will use all floors
#floor_index: 1

# Tool cut width for short cuts in mm. Max 5mm
lateral_tool_cut_width: 1.5
# Tool cut width for longitudinal cuts in mm. Max 5mm
longitudinal_tool_cut_width: 2.3

# Type of laylout: 1/2 - brick, 1/3 - deck, free-joints, fixed-joints
# This is global, but you can override it per room
layout:
  type: deck
  first_board: 1/3 # or "full"
  angle: 1

rooms:
 - name: "small"  # Room name to identify it later
   size:
     # Room height in mm (from top to bottom, measured between walls)
     height: 2110
     # Room width  in mm (from left to right (layout direction), measured between walls)
     width: 3800

   # Cover margin override for this room
   cover_margin: 0.1
   # Length (width) of thefFirst board in the first row
   # Valid value: "full", "1/3", "2/3"
   first_board: 1/3

   # doors array is optional,
   # Doors must not intersect
   # Door rect is measure from the wall where it starts. See measurements section in README.md
   doors:
     - edge: left # left, right, top, bottom
       displacement: 170 # (0, 0) top, left
       name: door1 # name used to identify the door
       size:
         height: 35 # Size in mm
         width: 900 # Size in mm

floor_choices:
 -
   type: "151L8AEK1DKW240" # Type, usually Art#
   name: "Classic Nouveau Collection" # Name
   board_size: # Board size as specified by the vendor
     height: 187 # Size in mm
     width: 2420 # Size in mm

   # Optional: If known specify it so that Leparquet can tell you how many packs to buy
   # Usually you take this from floor TDS
   # Value in m^2
   pack_area: 2.72

   # Optional: If known specify it so that Leparquet can tell you how many packs to buy
   # Usually you take this from floor TDS
   # Value in items per pack
   boards_per_pack: 6

   # Optional
   pack_weight: 20

   # If known used to calculate BOM per room
   price_per_msq: 780

"""
