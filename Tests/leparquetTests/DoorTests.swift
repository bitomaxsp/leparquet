@testable import LeParquetFramework
import XCTest

final class DoorTests: XCTestCase {
    func testUnityDoorIsValid() {
        let name = "ddddoor"
        let e = Edge.bottom
        let frame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        let widthNorm = 1.0
        let heightNorm = 1.0

        let door = Door(name: name, edge: e, frame: frame, normalize: true, wn: widthNorm, hn: heightNorm)
        XCTAssertEqual(door.name, name, "Door name mismatch")
        XCTAssertEqual(door.edge, e, "Door edge mismatch")
        XCTAssertEqual(door.frame, frame, "Door frame mismatch")
        XCTAssertTrue(door.nomalized, "Door not normalized")
        XCTAssertEqual(door.longRange, frame.origin.x.native ..< frame.origin.x.native + frame.size.width.native, "Range mismatch")
    }

    func testNotNormalizedDoorIsValid() {
        let name = "ddddoor"
        let e = Edge.bottom
        let frame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        let widthNorm = 2.0
        let heightNorm = 3.0

        let door = Door(name: name, edge: e, frame: frame, normalize: false, wn: widthNorm, hn: heightNorm)
        XCTAssertEqual(door.name, name, "Door name mismatch")
        XCTAssertEqual(door.edge, e, "Door edge mismatch")
        XCTAssertEqual(door.frame, frame, "Door frame mismatch")
        XCTAssertFalse(door.nomalized, "Door not normalized")
        XCTAssertEqual(door.longRange, frame.origin.x.native ..< frame.origin.x.native + frame.size.width.native, "Range mismatch")
    }

    func testNormalizedDoorIsValid() {
        let name = "ddddoor"
        let e = Edge.bottom
        var frame = CGRect(x: 0.2, y: 0.0, width: 1.0, height: 1.0)
        let widthNorm = 2.0
        let heightNorm = 3.0

        let door = Door(name: name, edge: e, frame: frame, normalize: true, wn: widthNorm, hn: heightNorm)
        XCTAssertEqual(door.name, name, "Door name mismatch")
        XCTAssertEqual(door.edge, e, "Door edge mismatch")
        frame.origin.x.native *= widthNorm
        frame.size.width.native *= widthNorm
        frame.size.height.native *= heightNorm
        XCTAssertEqual(door.frame, frame, "Door frame mismatch")
        XCTAssertTrue(door.nomalized, "Door not normalized")
        XCTAssertEqual(door.longRange, frame.origin.x.native ..< frame.origin.x.native + frame.size.width.native, "Range mismatch")
    }

    static var allTests = [
        ("testUnityDoorIsValid", testUnityDoorIsValid),
        ("testNotNormalizedDoorIsValid", testNotNormalizedDoorIsValid),
        ("testNormalizedDoorIsValid", testNormalizedDoorIsValid),
    ]
}
