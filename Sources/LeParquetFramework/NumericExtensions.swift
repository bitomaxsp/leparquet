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
        return fabs(self - other) < Double.ulpOfOne
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
