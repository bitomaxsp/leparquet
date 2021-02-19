//
//  File.swift
//
//
//  Created by Dmitry on 2021-02-19.
//

import Foundation

enum VerticalEdge: CaseIterable {
    case left
    case right
}

enum HorizontalEdge: CaseIterable {
    case top
    case bottom
}

protocol Rect {
    var width: Double { get }
    var height: Double { get }
    var area: Double { get }
    func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge) -> (LeftCut, RightCut)
    func cutAlongHeight(atDistance: Double, from fromEdge: HorizontalEdge) -> (TopCut, BottomCut)
}

class ReusableBoard: Rect, Comparable {
    private var w: Double
    private var h: Double
    private var trash: Bool

    fileprivate convenience init() {
        self.init(width: 0, height: 0, reuse: false)
    }

    fileprivate init(width: Double, height: Double, reuse: Bool) {
        self.w = width
        self.h = height
        self.trash = !reuse
    }

    var reusable: Bool { !self.trash }
    var width: Double { self.w }
    var height: Double { self.h }
    var area: Double { self.w * self.h }

    func createLeft(width: Double, reuse: Bool) -> LeftCut {
        return LeftCut(width: width, height: self.height, reuse: reuse)
    }

    func createRight(width: Double, reuse: Bool) -> RightCut {
        return RightCut(width: width, height: self.height, reuse: reuse)
    }

    func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge) -> (LeftCut, RightCut) {
        assert(false, "IMPLEMENT IN SUBCLASS")
        return (LeftCut(), RightCut())
    }
}

final class LeftCut: ReusableBoard {
    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge) -> (LeftCut, RightCut) {
        // Left is good
        // Right is trash
        let newWidth = self.width - atDistance
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: false))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: false))
        }
    }
}

final class RightCut: ReusableBoard {
    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge) -> (LeftCut, RightCut) {
        // Left is trash
        // Right is good
        let newWidth = self.width - atDistance
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: false), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: false), createRight(width: atDistance, reuse: true))
        }
    }
}

final class TopCut: ReusableBoard {}

final class BottomCut: ReusableBoard {}

final class FloorBoard: ReusableBoard {
    init(width: Double, height: Double) {
        super.init(width: width, height: height, reuse: true)
    }

    override func cutAlongWidth(atDistance: Double, from fromEdge: VerticalEdge) -> (LeftCut, RightCut) {
        // Left is good
        // Right is good
        let newWidth = self.width - atDistance
        switch fromEdge {
        case .left:
            return (createLeft(width: atDistance, reuse: true), createRight(width: newWidth, reuse: true))
        case .right:
            return (createLeft(width: newWidth, reuse: true), createRight(width: atDistance, reuse: true))
        }
    }
}

extension Rect {
    func cutAlongHeight(atDistance: Double, from fromEdge: HorizontalEdge) -> (TopCut, BottomCut) {
        assert(false, "NOT IMPLEMENTED")
        return (TopCut(), BottomCut())
    }
}

extension ReusableBoard {
    static func < (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w < rhs.w
    }

    static func > (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w > rhs.w
    }

    static func == (lhs: ReusableBoard, rhs: ReusableBoard) -> Bool {
        return lhs.w == rhs.w
    }
}
