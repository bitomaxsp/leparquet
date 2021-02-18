import XCTest
@testable import leparquet

final class leparquetTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(leparquet().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
