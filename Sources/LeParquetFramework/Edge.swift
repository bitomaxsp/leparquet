import Foundation

/// Rectangle edge
enum Edge: String, Codable, CaseIterable {
    case top
    case left
    case bottom
    case right
}

extension Edge {
    var isVertical: Bool {
        return self == .left || self == .right
    }

    var isHorizontal: Bool {
        return self == .top || self == .bottom
    }
}
