import Foundation

public class RowLayoutEngine {
    typealias Stash = RawReport.BoardStash
    typealias StashOfLefts = [LeftCut]
    typealias StashOfRights = [RightCut]

    // ###################################

    let engineConfig: LayoutEngineConfig
    let report: RawReport
    static let normalizedWholeStep = 1.0
    let debug: Bool
    // NOTE: Reusable right cut can only be used on left side, and vise versa
    private var reusableLeft = StashOfRights()
    private var reusableRight = StashOfLefts()

    init(_ input: LayoutEngineConfig, debug: Bool) {
        self.engineConfig = input
        self.report = RawReport(self.engineConfig, normalizedWidth: Self.normalizedWholeStep)
        self.debug = debug
    }

    func layout() -> RawReport {
        self.calculateRows()

        let board_width = self.engineConfig.material.board.size.width

        // 1 - Normalized to one board length
        let normalizedRowWidth = self.engineConfig.effectiveRoomSize.width / board_width

        if self.debug {
            print("Norm row width: \(normalizedRowWidth.round(4)), Effective covering lenth in each row: \(normalizedRowWidth * board_width)mm")
        }

        self.normalizedLayoutCalculation(normalizedRowWidth)
        self.report.collectRests(from: self.reusableRight)
        self.report.collectRests(from: self.reusableLeft)
        self.reusableLeft.removeAll()
        self.reusableRight.removeAll()

        if self.debug {
            print(self.report.output())
        }

        return self.report
    }

    // MARK: Implementation

    private func calculateRows() {
        let board_height = self.engineConfig.material.board.size.height
        let borad_num_frac = self.engineConfig.effectiveRoomSize.height / board_height
        let total_rows = ceil(borad_num_frac)
        self.report.total_rows = Int(total_rows)

        // TODO: FIXME: Cover using whole boards (account spike that is cut off)
        // if self.unused_height_on_last_row < spike_mm:
        // spike_mm = 0  # 15  # [mm]

        self.report.unused_height_on_last_row = total_rows * board_height - self.engineConfig.effectiveRoomSize.height

        precondition(self.report.unused_height_on_last_row <= board_height, "Ununsed last board height must be less then 1 board height")

        self.report.last_row_height = board_height - self.report.unused_height_on_last_row

        if self.debug {
            print("Preliminary last row height: \(self.report.last_row_height)")
        }

        // whole room covered using whole boards in hieght
        if self.report.last_row_height.isZero {
            self.report.last_row_height = board_height
        }

        // we need to shif to get at least min_last_height mm on last row
        let min_combined_height_limit = max(self.engineConfig.minLastRowHeight, self.engineConfig.desiredLastRowHeight)

        while self.report.last_row_height < min_combined_height_limit {
            let shift = min_combined_height_limit - self.report.last_row_height
            self.report.first_row_height -= shift
            self.report.last_row_height += shift
            if self.debug {
                print("Last row is less than needed, adjusting it by \(shift)")
            }
        }

        let needFirstCut = !board_height.eq(self.report.first_row_height)
        let needLastCut = !board_height.eq(self.report.last_row_height)

        self.report.unused_height_on_first_row = board_height - self.report.first_row_height - (needFirstCut ? min(self.report.unused_height_on_first_row, self.engineConfig.lonToolCutWidth) : 0.0)
        self.report.unused_height_on_last_row = board_height - self.report.last_row_height - (needLastCut ? min(self.report.unused_height_on_last_row, self.engineConfig.lonToolCutWidth) : 0.0)
        precondition(self.report.unused_height_on_first_row >= 0.0, "Unused first row rest must be positive")
        precondition(self.report.unused_height_on_last_row >= 0.0, "Unused last row rest must be positive")
    }

    private func normalizedLayoutCalculation(_ normalizedRowWidth: Double) {
        let startLength = self.engineConfig.firstBoard.lengthAsDouble()

        // TODO: normalizedType
        var cutLength: Double = startLength
        // ReusableBoard(width: start, height: self.input.material.board.size.height)

        for rowCount in 0 ..< self.report.total_rows {
            if self.debug {
                print("Row -------------------------------- \(rowCount)")
            }

            self.report.newRow()
            self.report.add(instruction: "Start row #\(rowCount + 1):")
            var rowCovered = 0.0

            // First board used from LEFT stash
            var board: ReusableBoard? = self.useBoardFromLeftStash(cutLength)
            if board == nil {
                // Use new first board and save the rest if stash is empty
                board = self.useWholeBoardOnTheLeftSide(cutLength)
            } else {
                // Step: Take board marked with X from Left stash
                self.report.add(instruction: "Take board marked as \(board!.mark) and put it in the row.")
            }

            precondition(board != nil, "Board must be valid here")
            self.report.add(board: board!)
            rowCovered += board!.width

            if self.debug {
                print("Row:\(rowCount) Step: \(cutLength.round(4))")
            }

            // Use whole board if we in the middle
            cutLength = Self.normalizedWholeStep

            while rowCovered < normalizedRowWidth {
                board = nil
                cutLength = min(Self.normalizedWholeStep, Double(normalizedRowWidth - rowCovered))

                if self.debug {
                    print("Row:\(rowCount) Step: \(cutLength.round(4))")
                }

                if cutLength == Self.normalizedWholeStep {
                    board = self.report.newBoard()
                    self.report.add(instruction: "Take new board from the pack. Put in the row.")

                } else if cutLength < Self.normalizedWholeStep {
                    board = self.useBoardFromRightStash(cutLength)
                    // Right reused from stash if we have it with required length
                    if board == nil {
                        // Or new one and save the rest
                        board = self.useWholeBoardOnTheRightSide(cutLength)
                    } else {
                        // Step: Take board marked with X from right stash
                        self.report.add(instruction: "Take board marked as \(board!.mark) and put it in the row.")
                    }
                }
                precondition(board != nil, "Board must be valid here")

                rowCovered += cutLength
                self.report.add(board: board!)
            }
            // Update step before new row
            cutLength = self.nextRowFirstLength(startLength, rowCount)
        }

        if self.debug {
            print("-------------------------------- DONE")
        }
    }

    private func nextRowFirstLength(_ startLength: Double, _ rowCount: Int) -> Double {
        let step = Double(1, 3)
        let r = rowCount % 3

        var nexts = startLength + step + step * Double(r)
        if nexts > Self.normalizedWholeStep {
            nexts -= Self.normalizedWholeStep
        }

        return nexts
    }

    // return used cut
    private func useWholeBoardOnTheRightSide(_ cutLength: Double) -> ReusableBoard {
        precondition(cutLength > 0.0, "Cut must be greater than 0")

        let board = self.report.newBoard()
        self.report.add(instruction: "Take new board from the pack.")

        if cutLength < Self.normalizedWholeStep {
            let (left, right) = board.cutAlongWidth(atDistance: cutLength, from: .left, cutWidth: self.engineConfig.normalizedLatToolCutWidth)
            precondition(left.width.eq(cutLength), "left.width must be cutLength")

            // Step: Cut in two
            let aCut = self.normalized(width: cutLength, to: UnitLength.millimeters)
            self.report.append(instruction: "Cut \(aCut) from the left side.")
            self.report.append(instruction: "Put LEFT cut in the row. Mark RIGHT cut as \(right.mark).")

            // Collect usable only if it grater than smallest cutLength for the last which 1/3 for the deck layout
            if right.width >= Double(1, 3) { // TODO: min row step (runout)
                if self.debug {
                    print("Save reusable \(right) for the left side: \(right.width.round(4))")
                }
                // Save usable rest from right which can be used on left side
                self.stash(right: right)
            } else {
                self.collect(trash: right)
            }
            return left

        } else {
            // Step: put in row
            self.report.append(instruction: "Put in the row.")
        }

        return board
    }

    // return used cut
    private func useWholeBoardOnTheLeftSide(_ cutLength: Double) -> ReusableBoard {
        precondition(cutLength > 0.0, "Cut must be greater than 0")

        // Take new board
        let board = self.report.newBoard()
        self.report.add(instruction: "Take new board from the pack.")

        // Determine rest from left to right side
        if cutLength < Self.normalizedWholeStep {
            let (left, right) = board.cutAlongWidth(atDistance: cutLength, from: .right, cutWidth: self.engineConfig.normalizedLatToolCutWidth)
            precondition(right.width.eq(cutLength), "right.width must be cutLength")

            // Step: Cut in two
            let aCut = self.normalized(width: cutLength, to: UnitLength.millimeters)
            self.report.append(instruction: "Cut \(aCut) from the right side.")
            self.report.append(instruction: "Put RIGHT cut in the row. Mark LEFT cut as \(left.mark).")

            self.stash(left: left)
            if self.debug {
                print("Save reusable \(left) for the right side: \(left.width.round(4))")
            }
            return right

        } else {
            // Step: put in row
            self.report.append(instruction: "Put in the row.")
        }

        return board
    }

    private func stash(right: RightCut) {
        self.report.append(instruction: "Put the cut \(right.mark) to the left stash.")
        self.reusableLeft.append(right)
    }

    private func stash(left: LeftCut) {
        self.report.append(instruction: "Put the cut \(left.mark) to the right stash.")
        self.reusableRight.append(left)
    }

    // Get cut (of right part) from left stash for left side
    private func useBoardFromLeftStash(_ requiredLength: Double) -> RightCut? {
        return self.useFrom(&self.reusableLeft, requiredLength)
    }

    // Get cut (of left) from right stash for right side
    private func useBoardFromRightStash(_ requiredLength: Double) -> LeftCut? {
        return self.useFrom(&self.reusableRight, requiredLength)
    }

    private func useFrom<T>(_ stash: inout [T], _ requiredLength: Double) -> T? where T: ReusableBoard {
        if stash.count > 0 {
            stash.sort()
            if self.debug {
                print("Checking stash of reusable \(T.self) part: \(stash.map { $0.width.round(4) })")
            }

            // Use nextDown to avoid rounding errors
            if let idx = stash.firstIndex(where: {
                // When we search a cut we need to account for tool cut width
                let diff = $0.width - (requiredLength + self.engineConfig.normalizedLatToolCutWidth)
                // If the are close to each other or too far
                return $0.width.eq(requiredLength) || diff > Double.ulpOfOne
            }) {
                let board = stash.remove(at: idx)

                precondition(board.width - (requiredLength + self.engineConfig.normalizedLatToolCutWidth) > Double.ulpOfOne || board.width.eq(requiredLength))

                if self.debug {
                    print("Found reusable \(T.self) part: \(board.width.round(4)), using \(requiredLength.round(4)) of it")
                }

                // Use own eq to avoid rounding errors
                if board.width.eq(requiredLength) {
                    return board
                }

                let edge: VerticalEdge = T.self == LeftCut.self ? .left : .right

                let (left, right) = board.cutAlongWidth(atDistance: requiredLength, from: edge, cutWidth: self.engineConfig.normalizedLatToolCutWidth)

                // Step: Cut in two
                self.report.add(instruction: "Take board marked as \(board.mark).")
                let aCut = self.normalized(width: requiredLength, to: UnitLength.millimeters)
                self.report.append(instruction: "Cut \(aCut) from the \(edge) side.")
                self.report.append(instruction: "Mark LEFT cut as \(left.mark), and RIGHT cut as \(right.mark).")

                if T.self == LeftCut.self {
                    self.collect(trash: right)
                    return left as? T
                } else {
                    self.collect(trash: left)
                    return right as? T
                }
            }
        }

        return nil
    }

    private func collect(trash: ReusableBoard) {
        self.report.stash(trash: trash)
        self.report.append(instruction: "Put cut marked as \(trash.mark) to trash.")
        if self.debug {
            print("Collect trash \(trash.width.round(6)), reuse: \(trash.reusable)")
        }
    }

    private func normalized(width cut: Double, to newUnit: UnitLength) -> String {
        let aCut = Measurement<UnitLength>(value: cut * self.engineConfig.material.board.size.width, unit: UnitLength.millimeters).converted(to: newUnit)
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.allowsFloats = true
        numberFormatter.decimalSeparator = Locale.current.decimalSeparator
        let m = MeasurementFormatter()
        m.numberFormatter = numberFormatter
        m.unitOptions = .providedUnit
        return m.string(from: aCut)
    }
}

extension Double {
    init(_ nom: Int, _ denom: Int) {
        self = Double(nom) / Double(denom)
    }

    init(_ nom: Double, _ denom: Double) {
        self = nom / denom
    }

    func round(_ signs: Int) -> String {
        return String(format: "%.\(signs)g", self)
    }

    // Use own eq to avoid rounding errors
    func eq(_ other: Double) -> Bool {
        return fabs(self - other) < Double.ulpOfOne
    }
}
