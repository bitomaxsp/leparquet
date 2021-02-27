import Foundation

class UnitAreaPerPack: Dimension {
    static let squareMeters = UnitAreaPerPack(symbol: "m²/pack", converter: UnitConverterLinear(coefficient: 1))
    static let baseUnit = UnitAreaPerPack.squareMeters
}

class UnitBoardsPerPack: Dimension {
    static let boards = UnitBoardsPerPack(symbol: "board(s)", converter: UnitConverterLinear(coefficient: 1))
    static let baseUnit = UnitBoardsPerPack.boards
}

class UnitPack: Dimension {
    static let packs = UnitPack(symbol: "pack(s)", converter: UnitConverterLinear(coefficient: 1))
    static let baseUnit = UnitPack.packs
}

// MARK: Output

extension Measurement where UnitType: UnitAreaPerPack {
    func format<U>(convertedTo: U, usingDigits n: Int = 3) -> String where U: UnitAreaPerPack {
        let m = self.formatter(withFractionDigits: n)
        return m.string(from: self.converted(to: convertedTo as! UnitType))
    }
}

extension Measurement where UnitType: UnitBoardsPerPack {
    func format() -> String {
        let m = self.formatter(withFractionDigits: 0)
        m.numberFormatter.allowsFloats = false
        return m.string(from: self)
    }
}

extension Measurement where UnitType: UnitArea {
    func format<U>(convertedTo: U, usingDigits n: Int = 3) -> String where U: UnitArea {
        let m = self.formatter(withFractionDigits: n)
        return m.string(from: self.converted(to: convertedTo as! UnitType))
    }
}

extension Measurement where UnitType: UnitLength {
    func format<U>(convertedTo: U, usingDigits n: Int = 2) -> String where U: UnitLength {
        let m = self.formatter(withFractionDigits: n)
        return m.string(from: self.converted(to: convertedTo as! UnitType))
    }
}

// MARK: operators

extension Measurement {
    // Packs
    static func / (lhs: Int, rhs: Measurement<UnitBoardsPerPack>) -> Measurement<UnitPack> {
        return Measurement<UnitPack>(value: Double(lhs) / rhs.value, unit: UnitPack.packs)
    }

    // Rest in pack
    static func % (lhs: Int, rhs: Measurement<UnitBoardsPerPack>) -> Int {
        return lhs % Int(rhs.value)
    }

    static func - (lhs: Measurement<UnitBoardsPerPack>, rhs: Int) -> Int {
        return Int(lhs.value) - rhs
    }

    // rhs: boardArea
    static func * (lhs: Measurement<UnitBoardsPerPack>, rhs: Measurement<UnitArea>) -> Measurement<UnitAreaPerPack> {
        let v = lhs.value * rhs.converted(to: .squareMeters).value
        return Measurement<UnitAreaPerPack>(value: v, unit: .squareMeters)
    }

    // lhs: total area
    static func / (lhs: Measurement<UnitArea>, rhs: Measurement<UnitAreaPerPack>) -> Measurement<UnitPack> {
        return Measurement<UnitPack>(value: lhs.converted(to: .squareMeters).value / rhs.value, unit: UnitPack.packs)
    }

    // rhs: board area
    static func / (lhs: Measurement<UnitAreaPerPack>, rhs: Measurement<UnitArea>) -> Measurement<UnitBoardsPerPack> {
        let v = lhs.value / rhs.converted(to: .squareMeters).value
        return Measurement<UnitBoardsPerPack>(value: v.rounded(), unit: UnitBoardsPerPack.boards)
    }
}

extension Measurement {
    func formatter(withFractionDigits digits: Int) -> MeasurementFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = digits
        numberFormatter.allowsFloats = true
        numberFormatter.decimalSeparator = Locale.current.decimalSeparator
        let m = MeasurementFormatter()
        m.numberFormatter = numberFormatter
        m.unitOptions = .providedUnit
        return m
    }
}
