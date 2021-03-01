import Foundation

/// Repesents rectangle insets. Position values reduce rect area, negative increases it
struct Insets: Codable, Equatable {
    let top: Double
    let left: Double
    let bottom: Double
    let right: Double
}
