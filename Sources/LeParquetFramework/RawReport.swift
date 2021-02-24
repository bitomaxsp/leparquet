import Foundation

class RawReport {
    typealias BoardStash = [ReusableBoard]
    typealias InstructionList = [String]

    init(_ config: LayoutEngineConfig, normalizedWidth: Double) {
        self.engineConfig = config
        self.first_row_height = Double(config.material.board.size.height)
        self.normalizedWidth = normalizedWidth
    }

    let normalizedWidth: Double
    let engineConfig: LayoutEngineConfig
    var boardHeight: Double { return self.engineConfig.material.board.size.height }
    var boardArea: Double { return self.engineConfig.material.board.area }
    var roomSize: Config.Size { return self.engineConfig.effectiveRoomSize }

    var first_row_height: Double
    var last_row_height = 0.0

    private var rows = [BoardStash]()
    // This is pure trash, middle cuts mostly
    private var trashCuts = BoardStash()
    private var instructions = InstructionList()
    private var boardsUsed = 0

    var unused_height_on_first_row: Double = 0.0
    var unused_height_on_last_row: Double = 0.0
    var total_rows = 0
    var boardNumWithMargin = 0

    // MARK: Implementation

    func newRow() {
        self.rows.append(BoardStash())
    }

    func add(board: ReusableBoard) {
        self.rows[self.rows.count - 1].append(board)
    }

    func newBoard() -> FloorBoard {
        defer {
            self.boardsUsed += 1
        }
        return FloorBoard(width: self.normalizedWidth, height: self.boardHeight)
    }

    func add(instruction: String) {
        self.instructions.append(instruction)
    }

    func append(instruction: String) {
        if var l = self.instructions.last {
            l.append(" ")
            l.append(instruction)
            self.instructions[self.instructions.count - 1] = l
        }
    }

    func stash(trash: ReusableBoard) {
        precondition(trash.width > 0.0, "Zero width trash. Weird!")
        self.trashCuts.append(trash)
    }

    func collectRests<T>(from: [T]) where T: ReusableBoard {
        self.trashCuts.append(contentsOf: from)
        self.trashCuts.sort()
    }

    func output() -> String {
        var ss = ""

        // TODO: support backward layout
        print("NOTE: Layout is done from left ro right, from top to bottom", to: &ss)

        print("Total rows: \(self.total_rows)", to: &ss)
        print("First row height: \(self.first_row_height)mm", to: &ss)
        print("Middle height: \(self.boardHeight)mm", to: &ss)
        print("Last row height: \(self.last_row_height)mm", to: &ss)

        var total_height = self.first_row_height + self.boardHeight * Double(self.total_rows) + self.last_row_height
        var N = 0.0
        if self.first_row_height > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }
        if self.last_row_height > 0.0 {
            total_height -= self.boardHeight
            N += 1
        }

        print("Total height: \(self.first_row_height) + \(self.boardHeight)*\(Double(self.total_rows) - N) + \(self.last_row_height) = \(total_height)mm", to: &ss)
        print("(Remember, you need to add both side clearance)", to: &ss)
        print("Unused height from first row: \(self.unused_height_on_first_row)mm (cut width: \(self.engineConfig.lonToolCutWidth)mm)", to: &ss)
        print("Unused height from last row: \(self.unused_height_on_last_row)mm (cut width: \(self.engineConfig.lonToolCutWidth)mm)", to: &ss)

        self.printRows(to: &ss)
        print("Unusable normalized rests: \(self.trashCuts.map { $0.width.round(4) }) [norm to board length]", to: &ss)

        self.printRows(to: &ss, self.engineConfig.material.board.size.width)
        print("Unusable rests: \(self.trashCuts.map { ($0.width * self.engineConfig.material.board.size.width).round(4) }) mm", to: &ss)

        let rest_width_sum = self.trashCuts.reduce(0.0) { (next, b) in
            return next + b.width
        }

        let unused_area = rest_width_sum * self.boardArea
        print("Unusable side trash area: \(unused_area.round(4)) m^2", to: &ss)

        let side_cut_trash_area_m2 = (Double(self.total_rows) * self.boardHeight - self.roomSize.height) * self.roomSize.width * 1e-6
        let total_trash = unused_area + side_cut_trash_area_m2

        print("Unusable top/bottom trash area: \(side_cut_trash_area_m2) m^2", to: &ss)
        print("Total trash area: \(total_trash.round(4)) m^2", to: &ss)
        print("Used boards: \(self.boardsUsed)", to: &ss)

        let totalBoardsArea = Double(self.boardsUsed) * self.boardArea
        print("Total buy area as [boards * boardArea]: \(totalBoardsArea) m^2", to: &ss)
        print("Total buy area - total trash area: \((totalBoardsArea - total_trash).round(4)) m^2", to: &ss)

        if let price = self.engineConfig.material.pricePerM2 {
            print("Total price (using total area): \((price * totalBoardsArea).roundf(2))", to: &ss)
        } else {
            print("", to: &ss)
        }

        var packsRequired: Double?

        if let packArea = self.engineConfig.material.pack.area {
            print("----------------------------------------------------", to: &ss)
            print("** Calculate using pack area: \(packArea)", to: &ss)
            let packsRequiredDbl = totalBoardsArea / packArea
            let boardsPerPack = (packArea / self.boardArea).rounded()
            // fractionPart represents how much of last pack is used.
            // For example for pack of 6 boards: 1/6 is 0.1(6)
            // For example for pack of 8 boards: 1/8 is 0.125
            // For pack of 10 boards, it is 0.1 and etc.
            // Here we ASSUME, that it is possible to find pack of 10 boards hence if fraction is less than 0.1 we round down, otherwise up
            let fractionPart = packsRequiredDbl.remainder(dividingBy: floor(packsRequiredDbl))
            let limit = 0.1 // Max 10 board per pack
            packsRequired = fractionPart < limit ? packsRequiredDbl.rounded() : packsRequiredDbl.rounded(.up)
            print("** Unused boards left: \((packsRequired! * boardsPerPack - Double(self.boardsUsed)).rounded())", to: &ss)
            print("** Packs required: \(packsRequired!.rounded())", to: &ss)
            print("** Estimated board/pack: \(boardsPerPack.round(1))", to: &ss)
        }
        print("----------------------------------------------------", to: &ss)
        if let boardsPerPack = self.engineConfig.material.pack.boardsCount {
            print("++ Calculate using boards per pack: \(boardsPerPack)", to: &ss)
            let packs = Double(self.boardsUsed / boardsPerPack) + (self.boardsUsed % boardsPerPack == 0 ? 0.0 : 1.0)
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
            print("++ Estimated pack area: \(Double(boardsPerPack) * self.boardArea)", to: &ss)
            print("----------------------------------------------------", to: &ss)
        }

        if let weight = self.engineConfig.material.packWeight {
            if let p = packsRequired {
                print("Total weight: \(weight.converted(to: .kilograms) * p)", to: &ss)
            }
        } else {
            print("", to: &ss)
        }

        print("\n----------- THEORY DATA -----------", to: &ss)

        print("Calculated area: \(self.engineConfig.calc_covered_area.round(4)) m^2", to: &ss)
        print("Calculated area + (\(self.engineConfig.coverMaterialMargin * 100)% margin): \(self.engineConfig.calc_covered_area_with_margin.round(4)) m^2", to: &ss)
        self.boardNumWithMargin = Int(ceil(self.engineConfig.calc_covered_area_with_margin / self.boardArea))
        print("Calculated boards (using margin), float: \((self.engineConfig.calc_covered_area_with_margin / self.boardArea).round(4))", to: &ss)
        print("Calculated boards (using margin), int: \(self.boardNumWithMargin)", to: &ss)
        print("Total trash calc: \((totalBoardsArea - self.engineConfig.calc_covered_area).round(4)) m^2", to: &ss)

        return ss
    }

    func instructionList() -> String {
        var ss = ""
        for s in self.instructions {
            print(s, to: &ss)
        }
        return ss
    }

    func printRows(to: inout String, _ mul: Double = 1.0) {
        let flavor = mul > 1.0 ? "real" : "nomalized"
        print("\nLayout [\(flavor)]:", to: &to)

        for r in self.rows {
            print(r.map { ($0.width * mul).round(4) }, to: &to)
        }
        print("\n", to: &to)
    }
}
