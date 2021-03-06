import Foundation

/// Rectangle edge
enum Edge: String, Codable, CaseIterable {
    case top
    case left
    case bottom
    case right
}

extension Edge {
    func isVertical() -> Bool {
        return self == .left || self == .right
    }

    func isHorizontal() -> Bool {
        return self == .top || self == .bottom
    }
}
