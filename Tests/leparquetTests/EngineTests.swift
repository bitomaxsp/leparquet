@testable import LeParquetFramework
import XCTest
import Yams

final class EngineTests: XCTestCase {
    var engine: RowLayoutEngine!
    var config: Config!
    override func setUp() {
        self.config = yamlConfigWith(yaml: validConfigData_OneFloor_OneRoom_ModHeight)!
        self.setupEngineWith(self.config)
    }

    override func tearDown() {
        self.engine = nil
    }

    func setupEngineWith(_ config: Config) {
        let engineConfig = try! LayoutEngineConfig(config, config.floorChoices[0], config.rooms[0])
        self.engine = RowLayoutEngine(withConfig: engineConfig, debug: config.showCalculations)
    }

    func testEngineLayout_RowsWhenNoLongitudinalCuts_Idempotent() {
        XCTAssertNoThrow(try self.engine.layout())
        XCTAssertNoThrow(try self.engine.layout())
    }

    func testEngineLayout_RoomWhenHeighMultipleIntegerTiles_NoLongitudinalCuts_Correct() {
        let report = try! self.engine.layout()

        XCTAssertEqual(report.totalRows, 20, "Unexpected number of rows")
        XCTAssertEqual(report.firstRowHeight, report.engineConfig.material.board.size.height, "Unexpected firstRowHeight")
        XCTAssertEqual(report.lastRowHeight, report.engineConfig.material.board.size.height, "Unexpected lastRowHeight")
        XCTAssertEqual(report.unusedHeightInFirstRow, 0, "Unexpected unusedHeightInFirstRow")
        XCTAssertEqual(report.unusedHeightInLastRow, 0, "Unexpected unusedHeightInLastRow")
        XCTAssertNoThrow(try report.validate())
    }

    func testEngineLayout_RoomWhenHeighNotMultipleIntegerTiles_Has2LongitudinalCuts_Correct() {
        // Change room heigh
        self.config.rooms[0].size.height = 2050
        self.setupEngineWith(self.config)

        let report = try! self.engine.layout()

        XCTAssertEqual(report.totalRows, 21, "Unexpected number of rows")
        XCTAssertEqual(report.firstRowHeight, 90, "Unexpected firstRowHeight")
        XCTAssertEqual(report.lastRowHeight, report.engineConfig.minLastRowHeight, "Unexpected lastRowHeight")
        let expectedFirstRow = 10 - report.engineConfig.lonToolCutWidth
        XCTAssertEqual(report.unusedHeightInFirstRow, expectedFirstRow, "Unexpected unusedHeightInFirstRow")
        let expectedLastRow = report.engineConfig.material.board.size.height - report.engineConfig.minLastRowHeight - report.engineConfig.lonToolCutWidth
        XCTAssertEqual(report.unusedHeightInLastRow, expectedLastRow, "Unexpected unusedHeightInLastRow")
        XCTAssertNoThrow(try report.validate())
    }

    func testEngineLayout_RoomWhenHeighNotMultipleIntegerTiles_LastRowDesiredHeight_Correct() {
        // Change room heigh
        self.config.rooms[0].size.height = 2090
        self.config.desiredLastRowHeight = 80
        self.setupEngineWith(self.config)

        let report = try! self.engine.layout()

        XCTAssertEqual(report.totalRows, 21, "Unexpected number of rows")
        XCTAssertEqual(report.firstRowHeight, 10, "Unexpected firstRowHeight")
        XCTAssertEqual(report.lastRowHeight, report.engineConfig.desiredLastRowHeight, "Unexpected lastRowHeight")
        let expectedFirstRow = report.engineConfig.material.board.size.height - 10 - report.engineConfig.lonToolCutWidth
        XCTAssertEqual(report.unusedHeightInFirstRow, expectedFirstRow, "Unexpected unusedHeightInFirstRow")
        let expectedLastRow = report.engineConfig.material.board.size.height - report.engineConfig.desiredLastRowHeight - report.engineConfig.lonToolCutWidth
        XCTAssertEqual(report.unusedHeightInLastRow, expectedLastRow, "Unexpected unusedHeightInLastRow")
        XCTAssertNoThrow(try report.validate())
    }

    // TODO: Add trash length check
    func engineLayoutCheck(withBoardWidth boardWidth: Double, roomWidth: Double?, roomHeight: Double?, latToolCutWidth: Double, expectedRowCount: Int, trashCount: Int) {
        // Use ideal tool
        self.config.latToolCutWidth = latToolCutWidth
        self.config.floorChoices[0].boardSize.width = boardWidth
        if let roomWidth = roomWidth {
            self.config.rooms[0].size.width = roomWidth
        }
        if let roomHeight = roomHeight {
            self.config.rooms[0].size.height = roomHeight
        }

//        self.config.showCalculations = true
        self.setupEngineWith(self.config)

        let report = try! self.engine.layout()

        XCTAssertEqual(report.totalRows, expectedRowCount, "Unexpected number of rows for BW:\(boardWidth), RW:\(roomWidth ?? -1)")
        let trash = report.trash()
        XCTAssertEqual(trash.count, trashCount, "No trash expexted for BW:\(boardWidth), RW:\(roomWidth ?? -1)")

        let summedRows = report.sumRowLengths()
        for r in summedRows {
            XCTAssertTrue(report.engineConfig.actualRoomSize.width.nearlyEq(r * boardWidth), "Unexpected row width for BW:\(boardWidth), RW:\(roomWidth ?? -1)")
        }

        XCTAssertNoThrow(try report.validate())
    }

    func testEngineLayout_RoomWhenWidthMultipleIntegerTilesWidth_RowsWidth_Correct() {
        let boardWidth = 1999.0

        // Use ideal tool
        for k in 1 ..< 100 {
            self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: Double(k) * boardWidth, roomHeight: nil, latToolCutWidth: 0.0, expectedRowCount: 20, trashCount: 0)
        }
    }

    func testEngineLayout_RoomWhenWidthMultipleOneThirdTilesWidth_ForDeck_RowsWidth_Correct() {
        let boardWidth = 1500.0
        let rows = 3.0
        let roomHeight = 100.0 * rows

        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 3 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 4 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 5 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 3)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 6 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 7 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 8 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 3)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 9 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 10 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 0)
        self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: 11 * boardWidth / 3.0, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 3)
    }

    func testEngineLayout_RoomWhenWidthMultipleOneHalfTilesWidth_ForDeck_RowsWidth_Correct() {
        let boardWidth = 1500.0
        let denom = 2.0
        let rows = 3.0
        let roomHeight = 100.0 * rows

        for i in stride(from: 3.0, to: 100.0, by: 2.0) {
            self.engineLayoutCheck(withBoardWidth: boardWidth, roomWidth: i * boardWidth / denom, roomHeight: roomHeight, latToolCutWidth: 0.0, expectedRowCount: Int(rows), trashCount: 4)
        }
    }

//    static var allTests = [
//        ("", testUnityDoorIsValid),
//    ]
}

func yamlConfigWith(yaml: String) -> Config! {
    let configGet: () throws -> Config? = {
        do {
            let decoder = YAMLDecoder()
            let config = try decoder.decode(Config.self, from: yaml)
            XCTAssertNoThrow(try config.validate(), "Config calidation must be successful")
            return config
        } catch {
            XCTFail("Exception reading data or parsing a config")
        }
        throw TestError.unableToGetConfig
    }

    guard let config = try? configGet() else { return nil }
    return config
}

let validConfigData_OneFloor_OneRoom_ModHeight = """
---
# Set this to true to see how LeParquet does it's calculations
show_calculations: false

# Amount of clearance to take into consider when laying out boards.
# This value is for one side. Taken into account on top/bottom edges.
# Could be overriden per room
height_clearance: 0
# Same as above but for the last and right sides
# Could be overriden per room
width_clearance: 0

# Minimum amoung of last boards height in mm. Usually it must be > 60mm
# Could be overriden per room
min_last_row_height: 60.0
# You could specify last row (the one at the bottom of the room) board height in mm.
# Could be overriden per room
desired_last_row_height: 0.0
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
longitudinal_tool_cut_width: 2.5

# Type of laylout: 1/2 - brick, 1/3 - deck, free-joints, fixed-joints
# This is global, but you can override it per room
layout:
  type: deck
  first_board: 1/3 # or "full"
  angle: 0

rooms:
 - name: "small"  # Room name to identify it later
   size:
     # Room height in mm (from top to bottom, measured between walls)
     height: 2000
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
   #doors:
   #  - edge: left # left, right, top, bottom
   #    displacement: 170 # (0, 0) top, left
   #    name: door1 # name used to identify the door
   #    size:
   #      height: 35 # Size in mm
   #      width: 900 # Size in mm

floor_choices:
 -
   type: "151L8AEK1DKW240" # Type, usually Art#
   name: "Classic Nouveau Collection" # Name
   board_size: # Board size as specified by the vendor
     height: 100 # Size in mm
     width: 1600 # Size in mm

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
