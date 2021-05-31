import Foundation

extension Double {
    init(_ nom: Int, _ denom: Int) {
        self = Double(nom) / Double(denom)
    }

    init(_ nom: Double, _ denom: Double) {
        self = nom / denom
    }

    func round(_ signs: Int, _ f: String = "g") -> String {
        return String(format: "%.\(signs)\(f)", self)
    }

    // Use own eq to avoid rounding errors
    func eq(_ other: Double) -> Bool {
        return abs(self - other) < Double.ulpOfOne
    }

    /// Check if given number and other one are nearly equal sing relative error
    /// - Parameters:
    ///   - other: Other number
    ///   - epsilon: relative error of comparison
    /// - Returns: true if neraly the same given relative error, false otherwise
    public func nearlyEq(_ other: Double, _ epsilon: Double = Double.ulpOfOne) -> Bool {
        let absA = abs(self)
        let absB = abs(other)
        let diff = abs(self - other)

        if (self == other) { // shortcut, handles infinities
            return true
        } else if (self == 0.0 || other == 0.0 || (absA + absB < Double.leastNormalMagnitude)) {
            // a or b is zero or both are extremely close to it
            // relative error is less meaningful here
            return diff < (epsilon * Double.leastNormalMagnitude)
        } else { // use relative error
            return diff / min((absA + absB), Double.greatestFiniteMagnitude) < epsilon
        }
    }

    var floatValue: CGFloat {
        CGFloat(self)
    }
}

func > (_ lhs: CGFloat, _ rhs: Double) -> Bool {
    return Double(lhs) > rhs
}

func >= (_ lhs: CGFloat, _ rhs: Double) -> Bool {
    return Double(lhs) >= rhs
}

func < (_ lhs: CGFloat, _ rhs: Double) -> Bool {
    return Double(lhs) < rhs
}

func <= (_ lhs: CGFloat, _ rhs: Double) -> Bool {
    return Double(lhs) <= rhs
}

func < (_ lhs: Double, _ rhs: CGFloat) -> Bool {
    return lhs < Double(rhs)
}

func <= (_ lhs: Double, _ rhs: CGFloat) -> Bool {
    return lhs <= Double(rhs)
}

func > (_ lhs: Double, _ rhs: CGFloat) -> Bool {
    return lhs > Double(rhs)
}

func >= (_ lhs: Double, _ rhs: CGFloat) -> Bool {
    return lhs >= Double(rhs)
}

extension Int {
    var doubleValue: Double {
        return Double(self)
    }

    var floatValue: CGFloat {
        CGFloat(self)
    }
}
