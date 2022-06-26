import Foundation

enum ValidationError: Error {
    case badFloorIndex(String)
    case invalidLayout(String)
    case reportNotConsistent(String)
}
