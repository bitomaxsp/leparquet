import Foundation

protocol Rect {
    var width: Double { get }
    var height: Double { get }
    var area: Double { get }
    /// Unique rect mark
    var mark: String { get }
}
