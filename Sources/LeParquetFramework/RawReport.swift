import CoreGraphics
import Foundation

class RawReport {
    typealias BoardStash = [ReusableBoard]
    typealias InstructionList = [String]

    init(_ config: LayoutEngineConfig) {
        self.engineConfig = config
        self.firstRowHeight = Double(config.material.board.size.height)
        self.normalizedBoardWidth = NormalizedWholeStep
    }

    private let normalizedBoardWidth: Double
    let engineConfig: LayoutEngineConfig
    var boardWidth: Double { return self.engineConfig.material.board.size.width }
    private var boardHeight: Double { return self.engineConfig.material.board.size.height }
    private var boardArea: Measurement<UnitArea> { return self.engineConfig.material.board.area }
    private var roomSize: Config.Size { return self.engineConfig.effectiveRoomSize }

    private var rows = [BoardStash]()
    // This is pure trash, middle cuts mostly
    private var trashCuts = BoardStash()
    private var instructions = InstructionList()
    private var boardsUsed = 0
    private var doors = [Door]()
    // Tiles length added in eash row due to the possible doors. Normalized
    private var expansions = [Edge: [Double]]()

    var firstRowHeight: Double
    var lastRowHeight = 0.0
    var unusedHeightInFirstRow: Double = 0.0
    var unusedHeightInLastRow: Double = 0.0
    var totalRows = 0 {
        didSet {
            for cs in Edge.allCases {
                if cs == .left || cs == .right {
                    self.expansions[cs] = [Double](repeating: 0.0, count: self.totalRows)
                }
            }
        }
    }

    private var boardNumWithMargin = 0

    // MARK: API

    func validate() throws {
        // Sum of each row: must be equal to effective room width + clearance (included in the door height) + side doors rect height
        // according to how algorithm works
        let summed = self.sumRowLengths()

        // Check is based on prior knowledge about room size, clearance and doors used for layout
        // Thus we make sure we have independent check from how algorithm does layout
        for i in 0 ..< summed.count {
            let left = self.expansions[.left]![i] * self.boardWidth - self.engineConfig.insets.left
            let right = self.expansions[.right]![i] * self.boardWidth - self.engineConfig.insets.right
            let inset = left + right

            let rowWidth = summed[i] * self.boardWidth
            let calcWidth = self.engineConfig.actualRoomSize.width + inset

            if !rowWidth.nearlyEq(calcWidth) {
                let err = "Sanity check not passed for row [\(i)]: rowWidth:\(rowWidth.round(4)) != checkWidth:\(calcWidth)"
                throw ValidationError.reportNotConsistent(err)
            }
        }
    }

    func output() -> String {
        var ss = ""

        // TODO: support backward layout
        print("NOTE: Layout is done from left ro right, from top to bottom", to: &ss)

        print("Total rows: \(self.totalRows)", to: &ss)
        print("First row height: \(self.firstRowHeight)mm", to: &ss)
        print("Middle height: \(self.boardHeight)mm", to: &ss)
        print("Last row height: \(self.lastRowHeight)mm", to: &ss)

        var total_height = self.firstRowHeight + self.boardHeight * Double(self.totalRows) + self.lastRowHeight
        var N = 0.0
        if self.firstRowHeight > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }
        if self.lastRowHeight > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }

        print("Total height: \(self.firstRowHeight) + \(self.boardHeight)*\(Double(self.totalRows) - N) + \(self.lastRowHeight) = \(total_height)mm", to: &ss)
        print("(Remember, you need to add both side clearance)", to: &ss)
        print("Unused height from first row: \(self.unusedHeightInFirstRow)mm (cut width: \(self.engineConfig.lonToolCutWidth)mm)", to: &ss)
        print("Unused height from last row: \(self.unusedHeightInLastRow)mm (cut width: \(self.engineConfig.lonToolCutWidth)mm)", to: &ss)

        self.printRows(to: &ss)
        self.printRows(to: &ss, self.engineConfig.material.board.size.width)

        let restWidthSummed = self.trashCuts.reduce(0.0) { (next, b) in
            return next + b.width
        }

        let summedRows = self.sumRowLengths()
        let summedReal = summedRows.map {
            ($0 * self.boardWidth).round(3, "f")
        }

        print("\nEach row length (including side doors, no clearance if no door): \(summedReal)\n", to: &ss)

        let unused_area = self.boardArea * restWidthSummed
        print("Unusable side trash area: \(unused_area.format(convertedTo: .squareMeters))", to: &ss)

        let sideCutTrash = Measurement<UnitArea>(value: (Double(self.totalRows) * self.boardHeight - self.roomSize.height) * self.roomSize.width,
                                                 unit: UnitArea.squareMillimeters)
        let totalTrash = unused_area + sideCutTrash

        print("Unusable top/bottom trash area: \(sideCutTrash.format(convertedTo: .squareMeters))", to: &ss)
        print("Total trash area: \(totalTrash.format(convertedTo: .squareMeters))", to: &ss)
        print("Used boards: \(self.boardsUsed)", to: &ss)

        let totalBoardsArea = Double(self.boardsUsed) * self.boardArea
        print("Total buy area as [boards * boardArea]: \(totalBoardsArea.format(convertedTo: .squareMeters))", to: &ss)
        print("Total buy area - total trash area: \((totalBoardsArea - totalTrash).format(convertedTo: .squareMeters))", to: &ss)

        if let price = self.engineConfig.material.pack.pricePerM2 {
            print("Total price (using total area): \((price * totalBoardsArea.converted(to: .squareMeters).value).rounded())", to: &ss)
        } else {
            print("", to: &ss)
        }

        var packsRequired: Double?

        if let areaPerPack = self.engineConfig.material.pack.area {
            print("----------------------------------------------------", to: &ss)
            print("** Calculate using pack area: \(areaPerPack.format(convertedTo: .squareMeters))", to: &ss)
            let packsRequiredDbl = totalBoardsArea / areaPerPack
            let boardsPerPack = (areaPerPack / self.boardArea)
            // fractionPart represents how much of last pack is used.
            // For example for pack of 6 boards: 1/6 is 0.1(6)
            // For example for pack of 8 boards: 1/8 is 0.125
            // For pack of 10 boards, it is 0.1 and etc.
            // Here we ASSUME, that it is possible to find pack of 10 boards hence if fraction is less than 0.1 we round down, otherwise up
            let fractionPart = packsRequiredDbl.value.remainder(dividingBy: floor(packsRequiredDbl.value))
            let limit = 0.1 // Max 10 board per pack
            packsRequired = fractionPart < limit ? packsRequiredDbl.value.rounded() : packsRequiredDbl.value.rounded(.up)
            print("** Unused boards left: \((packsRequired! * boardsPerPack.value - Double(self.boardsUsed)).rounded())", to: &ss)
            print("** Packs required: \(packsRequired!.rounded())", to: &ss)
            print("** Estimated board/pack: \(boardsPerPack.format())", to: &ss)
        }
        print("----------------------------------------------------", to: &ss)
        if let boardsPerPack = self.engineConfig.material.pack.boardsCount {
            print("++ Calculate using boards per pack: \(boardsPerPack)", to: &ss)
            let packs = Double(self.boardsUsed / Int(boardsPerPack.value)) + (self.boardsUsed % boardsPerPack == 0 ? 0.0 : 1.0)
            if packsRequired == nil {
                packsRequired = packs
            } else {
                if packsRequired! != packs {
                    print(">>>>>>> WARNING: two methods gives two different results for number of packs!")
                }
            }
            let rest = self.boardsUsed % boardsPerPack
            print("++ Unused boards left: \(rest == 0 ? rest : boardsPerPack - rest)", to: &ss)
            print("++ Packs required: \(packs)", to: &ss)
            let areaPerPack = boardsPerPack * self.boardArea
            print("++ Estimated pack area: \(areaPerPack.format(convertedTo: .squareMeters))", to: &ss)
            print("----------------------------------------------------", to: &ss)
        }

        if let weight = self.engineConfig.material.pack.weight {
            if let p = packsRequired {
                print("Total weight: \(weight.converted(to: .kilograms) * p)", to: &ss)
            }
        } else {
            print("", to: &ss)
        }

        for d in self.doors {
            print(d, to: &ss)
        }

        print("\n----------- THEORY DATA -----------", to: &ss)

        print("Calculated area: \(self.engineConfig.calc_covered_area.round(4)) m^2", to: &ss)
        print("Calculated area + (\(self.engineConfig.coverMaterialMargin * 100)% margin): \(self.engineConfig.calc_covered_area_with_margin.round(4)) m^2", to: &ss)
        self.boardNumWithMargin = Int(ceil(self.engineConfig.calc_covered_area_with_margin / self.boardArea.converted(to: .squareMeters).value))
        print("Calculated boards (using margin), float: \((self.engineConfig.calc_covered_area_with_margin / self.boardArea.converted(to: .squareMeters).value).round(4))", to: &ss)
        print("Calculated boards (using margin), int: \(self.boardNumWithMargin)", to: &ss)
        print("Total trash calc: \((totalBoardsArea.converted(to: .squareMeters).value - self.engineConfig.calc_covered_area).round(4)) m^2", to: &ss)

        return ss
    }

    func instructionList() -> String {
        var ss = ""
        for s in self.instructions {
            print(s, to: &ss)
        }
        return ss
    }

    @discardableResult
    func sumRowLengths() -> [Double] {
        // Sum of each row: must be equal to effective room width + clearance (included in the door height) + side doors rect height
        // according to how algorithm works
        var summed = [Double](repeating: 0.0, count: self.rows.count)
        for i in 0 ..< self.rows.count {
            summed[i] = self.rows[i].reduce(0.0) { (next, b) in
                return next + b.width
            }
        }

        return summed
    }

    func trash() -> BoardStash {
        return self.trashCuts
    }

    private func printRows(to ss: inout String, _ mul: Double = 1.0) {
        let flavor = mul > 1.0 ? "real" : "nomalized"
        print("\nLayout [\(flavor)]:", to: &ss)

        for i in 0 ..< self.rows.count {
            let r = self.rows[i]
            let arr = r.map { (_ b: ReusableBoard) -> String in
                if mul == 1.0 {
                    return (b.width * mul).round(4)
                } else {
                    let m = Measurement<UnitLength>(value: b.width * mul, unit: UnitLength.millimeters)
                    return m.format(convertedTo: .millimeters)
                }
            }

            print("Row #\(i): \(arr)", to: &ss)
        }

        let rests = self.trashCuts.map { (_ b: ReusableBoard) -> String in
            if mul == 1.0 {
                return (b.width * mul).round(4)
            } else {
                let m = Measurement<UnitLength>(value: b.width * mul, unit: UnitLength.millimeters)
                return m.format(convertedTo: .millimeters)
            }
        }

        print("\nUnusable rests [\(flavor)]: \(rests)", to: &ss)
    }
}

extension RawReport {
    func newRow() {
        self.rows.append(BoardStash())
    }

    func newBoard() -> FloorBoard {
        defer {
            self.boardsUsed += 1
        }
        return FloorBoard(width: self.normalizedBoardWidth, height: self.boardHeight)
    }

    func add(board: ReusableBoard) {
        self.rows[self.rows.count - 1].append(board)
    }

    func add(instruction: String) {
        self.instructions.append(instruction)
    }

    /// Add covered door to report
    /// - Parameter door: Covered door
    func add(door: Door) {
        self.doors.append(door)
    }

    func add(protrusion: Double, forEdge edge: Edge, inRow rowIndex: Int) {
        self.expansions[edge]![rowIndex] += protrusion
    }

    func add(trash: ReusableBoard) {
        //        precondition(trash.width > 0.0, "Zero width trash. Weird!")
        if (!trash.width.isZero) {
            self.trashCuts.append(trash)
        }
    }

    func append(instruction: String) {
        if var l = self.instructions.last {
            l.append(" ")
            l.append(instruction)
            self.instructions[self.instructions.count - 1] = l
        }
    }

    func collectRests<T>(from: [T]) where T: ReusableBoard {
        self.trashCuts.append(contentsOf: from)
        self.trashCuts.sort()
    }
}

extension RawReport {
    enum ImageErrors: Error {
        case contextCreationFailed(String)
        case saveFailed(String)
        case cantRenderImage
    }

    func layoutImage(toFile file: URL) throws {
        let topMargin = 2 * 300
        let sideMargin = 2 * 400
        let result = self.createBitmapContext(pixelsWide: Int(self.roomSize.width) + sideMargin, pixelsHigh: Int(self.roomSize.height) + topMargin)
        if case .success(let ctx) = result {
            self.draw(inContext: ctx)

            guard let image = ctx.makeImage() else {
                throw ImageErrors.cantRenderImage
            }

            guard let destination = CGImageDestinationCreateWithURL(file.appendingPathExtension("png") as CFURL, kUTTypePNG, 1, nil) else {
                throw ImageErrors.saveFailed("CGImageDestinationCreateWithURL failed")
            }

            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)

        } else if case .failure(let error) = result {
            print("Error saving image file \(file): \(error)")
        }
    }

    private func createBitmapContext(pixelsWide: Int, pixelsHigh: Int) -> Result<CGContext, Error> {
        let cs = CGColorSpace(name: CGColorSpace.sRGB)
        guard let colorSpace = cs else {
            return .failure(ImageErrors.contextCreationFailed("colorSpace is nil"))
        }
        let context = CGContext(data: nil,
                                width: pixelsWide,
                                height: pixelsHigh,
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard context != nil else {
            return .failure(ImageErrors.contextCreationFailed("context is nil"))
        }

        return .success(context!)
    }

    private func setup(context ctx: CGContext) {
        ctx.setAllowsAntialiasing(true)
        // Invert Y axis so the we have simple height calculations
        ctx.translateBy(x: 0, y: CGFloat(ctx.height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setBlendMode(.normal)
    }

    private func draw(inContext ctx: CGContext) {
        self.setup(context: ctx)
        let borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

        // Fill BG
        ctx.setFillColor(CGColor(red: 255, green: 255, blue: 255, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))

        ctx.setStrokeColor(borderColor)
        ctx.setLineWidth(4.0)
        ctx.setFillColor(gray: 0.72, alpha: 1.0) // Gray fill

        // TODO: Clearance in config
        var x = 100.0
        var y = 100.0
        _ = self.rows.map { (r) -> [CGRect] in
            let v = r.map { (b) -> CGRect in
                let w = b.width * self.engineConfig.material.board.size.width
                let r = CGRect(x: x, y: y, width: w, height: b.height)
                x += w
                return r
            }
            y += v[0].height.native
            x = 100.0

            ctx.fill(v) // This invalidates the path
            ctx.addRects(v) // added here on previous iteration
            ctx.strokePath() // so we need to stroke them
            return v
        }

        // TODO: draw room rect
        // TODO: fraw doors in dark gray
    }
}
