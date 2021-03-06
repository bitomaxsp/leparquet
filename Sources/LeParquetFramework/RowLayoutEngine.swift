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
    private var doors = [Edge: [LayoutEngineConfig.Door]]()

    init(_ input: LayoutEngineConfig, debug: Bool) {
        self.engineConfig = input
        self.report = RawReport(self.engineConfig, normalizedBoardWidth: Self.normalizedWholeStep)
        self.debug = debug
        if let d = input.doors {
            for (k, v) in d {
                self.doors[k] = v
            }
        }
    }

    func layout() throws -> RawReport {
        self.calculateRows()
        try self.normalizedWidthCalculation()

        // TODO: Look top doors
//        let maxX = rowCovered + board!.width
        // TODO: Look bottom doors

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
        let boardHeight = self.engineConfig.material.board.size.height
//        let borad_num_frac = self.engineConfig.effectiveRoomSize.height / boardHeight
        let normalizedRoomHeight = self.engineConfig.effectiveRoomSize.height / boardHeight
        let totalRows = ceil(normalizedRoomHeight)
        self.report.totalRows = Int(totalRows)

//        normalizedRoomHeight.rem

        self.report.unusedHeightInLastRow = totalRows * boardHeight - self.engineConfig.effectiveRoomSize.height

        precondition(self.report.unusedHeightInLastRow <= boardHeight, "Ununsed last board height must be less then 1 board height")

        self.report.lastRowHeight = boardHeight - self.report.unusedHeightInLastRow

        if self.debug {
            print("Preliminary last row height: \(self.report.lastRowHeight)")
        }

        // whole room covered using whole boards in hieght
        if self.report.lastRowHeight.isZero {
            self.report.lastRowHeight = boardHeight
        }

        // we need to shift to get at least min_last_height mm on last row
        let min_combined_height_limit = max(self.engineConfig.minLastRowHeight, self.engineConfig.desiredLastRowHeight)

        while self.report.lastRowHeight < min_combined_height_limit {
            let shift = min_combined_height_limit - self.report.lastRowHeight
            self.report.firstRowHeight -= shift
            self.report.lastRowHeight += shift
            if self.debug {
                print("Last row is less than needed, adjusting it by \(shift)")
            }
        }

        let needFirstCut = !boardHeight.eq(self.report.firstRowHeight)
        let needLastCut = !boardHeight.eq(self.report.lastRowHeight)

        self.report.unusedHeightInFirstRow = boardHeight - self.report.firstRowHeight - (needFirstCut ? min(self.report.unusedHeightInFirstRow, self.engineConfig.lonToolCutWidth) : 0.0)
        self.report.unusedHeightInLastRow = boardHeight - self.report.lastRowHeight - (needLastCut ? min(self.report.unusedHeightInLastRow, self.engineConfig.lonToolCutWidth) : 0.0)
        precondition(self.report.unusedHeightInFirstRow >= 0.0, "Unused first row rest must be positive")
        precondition(self.report.unusedHeightInLastRow >= 0.0, "Unused last row rest must be positive")

        // top, bottom doors
        self.coverHorizontalDoors()
    }

    private func normalizedWidthCalculation() throws {
        let boardWidth = self.engineConfig.material.board.size.width

        let startLength = self.engineConfig.firstBoard.lengthAsDouble()

        var cutLength: Double = startLength

        /*
         Explanation:
         If protrusion on the left > 0 then we have to shift the floor left for that amount.
         Extend normalizedRoomWidth. In the case boards edges will shift between rows where there is a door.
         Shift whole layout on the amount of left board height so that edge do not missalign.
         Algorithimically shift is done by increasing normalizedRoomWidth for the rows where the doors are
         */
        let maximumLeftProtrusion = self.engineConfig.maxNormalizedLeftProtrusion
        // 1 - Normalized to one board length
        let normalizedRoomWidth = self.engineConfig.effectiveRoomSize.width / boardWidth + maximumLeftProtrusion

        if self.debug {
            print("Normalized row width: \(normalizedRoomWidth.round(4)), left protrusion: \(maximumLeftProtrusion)")
        }

        for rowIndex in 0 ..< self.report.totalRows {
            if self.debug {
                print("Row -------------------------------- \(rowIndex)")
            }

            self.report.newRow()
            self.report.add(instruction: "Start row #\(rowIndex + 1):")
            var rowCovered = 0.0

            // Amount of left cut due to protrusion
            var leftCutAmount = 0.0
            if maximumLeftProtrusion > 0.0 {
                // Look left doors to account left cut length
                let boardProtrusion = self.normalizedProtrusion(forEdge: .left, andRow: rowIndex)
                self.report.add(protrusion: boardProtrusion, forEdge: .left, inRow: rowIndex)

                leftCutAmount = maximumLeftProtrusion - boardProtrusion
                if self.debug {
                    print("boardProtrusion:\(boardProtrusion.round(4))[\((boardProtrusion * boardWidth).round(4))], leftCutAmount:\(leftCutAmount.round(4))[\(leftCutAmount * boardWidth)]")
                }

                // If there is not door we need shorted boards by the amount of max protrusion
                cutLength -= leftCutAmount
                if self.debug {
                    print("Reduce cutLength \(cutLength.round(4)) by \(leftCutAmount.round(4))")
                }
            }

            // First board used from LEFT stash
            var board: ReusableBoard? = self.useBoardFromLeftStash(withLength: cutLength)
            if board == nil {
                // Use new first board and save the rest if stash is empty
                board = self.useWholeBoardOnTheLeftSide(withLength: cutLength)
            } else {
                // Step: Take board marked with X from Left stash
                self.report.add(instruction: "Take board marked as \(board!.mark) and put it in the row.")
            }

            precondition(board != nil, "Board must be valid here")
            self.report.add(board: board!)
            rowCovered += board!.width

            if self.debug {
                print("Row:\(rowIndex) Step: \(cutLength.round(4))")
            }

            // Use whole board if we in the middle
            cutLength = Self.normalizedWholeStep

            // Make row shorted by the amount of cut if needed
            // If there is no door the first board is shorted and row also shorter
            let reducedNormalizedRoomWidth = normalizedRoomWidth - leftCutAmount
            while rowCovered < reducedNormalizedRoomWidth {
                board = nil
                cutLength = min(Self.normalizedWholeStep, Double(reducedNormalizedRoomWidth - rowCovered))

                if self.debug {
                    print("Row:\(rowIndex) Step: \(cutLength.round(4))")
                }

                if cutLength == Self.normalizedWholeStep {
                    board = self.report.newBoard()
                    self.report.add(instruction: "Take new board from the pack. Put in the row.")

                } else if cutLength < Self.normalizedWholeStep {
                    // Look right doors to account right cut length
                    let boardProtrusion = self.normalizedProtrusion(forEdge: .right, andRow: rowIndex)
                    self.report.add(protrusion: boardProtrusion, forEdge: .right, inRow: rowIndex)

//                    print("Right boardProtrusion:\(boardProtrusion.round(4))[\((boardProtrusion * boardWidth).round(4))]")

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
            cutLength = self.nextRowFirstLength(startLength, rowIndex)
        }

        if self.debug {
            print("-------------------------------- DONE")
        }
    }

    private func nextRowFirstLength(_ startLength: Double, _ rowIndex: Int) -> Double {
        let step = Double(1, 3)
        let r = rowIndex % 3

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
    private func useWholeBoardOnTheLeftSide(withLength cutLength: Double) -> ReusableBoard {
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
    private func useBoardFromLeftStash(withLength cutLength: Double) -> RightCut? {
        return self.useFrom(&self.reusableLeft, cutLength)
    }

    // Get cut (of left) from right stash for right side
    private func useBoardFromRightStash(_ cutLength: Double) -> LeftCut? {
        return self.useFrom(&self.reusableRight, cutLength)
    }

    private func useFrom<T>(_ stash: inout [T], _ cutLength: Double) -> T? where T: ReusableBoard {
        if stash.count > 0 {
            stash.sort()
            if self.debug {
                print("Checking stash of reusable \(T.self) part: \(stash.map { $0.width.round(4) })")
            }

            if let idx = stash.firstIndex(where: {
                // When we search a cut we need to account for tool cut width
                let diff = $0.width - (cutLength + self.engineConfig.normalizedLatToolCutWidth)
                // If cuts are close to each other or too far
                return $0.width.eq(cutLength) || diff > Double.ulpOfOne
            }) {
                let board = stash.remove(at: idx)

                precondition(board.width - (cutLength + self.engineConfig.normalizedLatToolCutWidth) > Double.ulpOfOne || board.width.eq(cutLength))

                if self.debug {
                    print("Found reusable \(T.self) part: \(board.width.round(4)), using \(cutLength.round(4)) of it")
                }

                // Use own eq to avoid rounding errors
                if board.width.eq(cutLength) {
                    return board
                }

                let edge: Edge = T.self == LeftCut.self ? .left : .right

                let (left, right) = board.cutAlongWidth(atDistance: cutLength, from: edge, cutWidth: self.engineConfig.normalizedLatToolCutWidth)

                // Step: Cut in two
                self.report.add(instruction: "Take board marked as \(board.mark).")
                let aCut = self.normalized(width: cutLength, to: UnitLength.millimeters)
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

    /// Return board length protrusion for the door adjacent to edge
    /// - Parameter edge: target edge to which door belongs
    /// - Returns: relative amount of protrusion in the direction of an edge, or 0 if no protrusion needed
    func normalizedProtrusion(forEdge edge: Edge, andRow rowIndex: Int) -> Double {
        if let idx = self.doors[edge]?.firstIndex(where: { (door) -> Bool in
            // TODO: Make position along edge

            // highest coord in the direction lateral to covering must be in doors range
            let currRange = Double(rowIndex) ..< (Double(rowIndex) + 1.0).nextUp
            return door.longRange.overlaps(currRange)
        }) {
            let door = self.doors[edge]![idx]
            assert(door.edge == edge)
            if self.debug {
                print("Found \(edge) door: \(Double(door.frame.size.height) * self.engineConfig.material.board.size.width)")
            }
            return Double(door.frame.size.height)
        }

        return 0.0
    }

    /// Try to figure our if doors along top and bottom edges can be covered from rests
    /// - Parameter doors: doors to cover
    private func coverHorizontalDoors() {
        // Check that largest (in height) door rect is less than first row: We cover!
        // Note arrays are sorted from ASC
        let boardHeight = self.engineConfig.material.board.size.height
        self.coverDoorsAlong(edge: .top, usingNormalizedRest: self.report.unusedHeightInFirstRow / boardHeight)
        self.coverDoorsAlong(edge: .bottom, usingNormalizedRest: self.report.unusedHeightInLastRow / boardHeight)
    }

    private func coverDoorsAlong(edge: Edge, usingNormalizedRest rest: Double) {
        precondition(edge == .bottom || edge == .top, "Edge must top or bottom")
        precondition(rest >= 0.0 && rest < 1.0, "Rest is not normalized: \(rest)")

        if let e = self.doors[edge] {
            if let last = e.last {
                // Unused part can be used to cover door passage
                if last.frame.size.height <= rest {
                    print("Can cover all \(edge) doors using \(rest) rest")

                    for d in e {
                        self.report.add(door: d)
                    }
                    self.doors.removeValue(forKey: edge)
                } else {
                    // Larges door can't be covered, so we for simplicity fallback to cover from whole boards
                    print("WARN: Couldn't cover some doors along \(edge) edge using \(rest) rest. Fallback to whole boards.")
                }
            }
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
