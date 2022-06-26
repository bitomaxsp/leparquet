import CoreGraphics
import ImageIO
import CoreText
import Foundation

/// Amount of margin for the drawing in points
// private let MarginPoints = 300

enum ImageErrors: Error {
    case contextCreationFailed(String)
    case saveFailed(String)
    case cantRenderImage
}

class LayoutRenderer {
    private let report: RawReport
    private let filePath: URL
    /// Room width/height ration
    private let roomWHRatio: Double
    /// Amount of space on top. Value is per one side
    private let topMarginPoints: Int
    /// Amount of space on the sides. Value is per one side
    private let sideMarginPoints: Int
    /// Image width in points
    private let imageW: Int
    /// Image height in points
    private let imageH: Int
    /// Horizontal scale in px/mm
    private let hScale: CGFloat
    /// Vertical scale in px/mm
    private let vScale: CGFloat
    private let borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
    // This is the space where we can draw our boards
    private let effectiveW: Double
    // This is the space where we can draw our boards
    private let effectiveH: Double
    
    init(_ file: URL, _ report: RawReport) {
        self.report = report
        self.filePath = file.appendingPathExtension("png")
        self.roomWHRatio = report.engineConfig.effectiveCoverSize.width / report.engineConfig.effectiveCoverSize.height
        self.imageW = 5000 // TODO: what to do for big scale?
        self.imageH = Int(self.imageW.doubleValue / self.roomWHRatio)

        self.topMarginPoints = 10 * self.imageH / 100 // MarginPoints
        self.sideMarginPoints = 5 * self.imageW / 100 // MarginPoints
        
        self.effectiveW = (self.imageW - self.sideMarginPoints * 2).doubleValue
        self.effectiveH = (self.imageH - self.topMarginPoints * 2).doubleValue
                           
        self.hScale = ((self.imageW - self.sideMarginPoints * 2).doubleValue / report.engineConfig.effectiveCoverSize.width).floatValue
        self.vScale = ((self.imageH - self.topMarginPoints * 2).doubleValue / report.engineConfig.effectiveCoverSize.height).floatValue
    }

    func Render() throws {
        let result = self.createBitmapContext(pixelsWide: self.imageW, pixelsHigh: self.imageH)
        if case .success(let ctx) = result {
            self.draw(inContext: ctx)

            guard let image = ctx.makeImage() else {
                throw ImageErrors.cantRenderImage
            }

            guard let destination = CGImageDestinationCreateWithURL(self.filePath as CFURL, kUTTypePNG, 1, nil) else {
                throw ImageErrors.saveFailed("CGImageDestinationCreateWithURL failed")
            }

            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)

        } else if case .failure(let error) = result {
            throw ImageErrors.saveFailed("Error saving image file \(self.filePath): \(error)")
        }
    }

    // MARK: Implementation

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
        ctx.setBlendMode(.darken)
    }

    private func draw(inContext ctx: CGContext) {
        self.setup(context: ctx)

        // Fill BG
        ctx.setFillColor(CGColor(red: 255, green: 255, blue: 255, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))

        self.drawBoards(inContext: ctx)
        self.drawHorizontalDoors(inContext: ctx)
        self.drawHelpers(inContext: ctx)
    }

    private func drawBoards(inContext ctx: CGContext) {
        // Invert and move up Y axis so the we have simple height calculations
        // Zero is at top left corner, Y points down
        ctx.translateBy(x: self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
        ctx.scaleBy(x: 1, y: -1)

        defer {
            // Invert Y axis back
            ctx.translateBy(x: -self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
            ctx.scaleBy(x: 1, y: -1)
        }

        ctx.setStrokeColor(self.borderColor)
        ctx.setLineWidth(2.0)
        ctx.setFillColor(gray: 0.72, alpha: 1.0) // Gray fill

        // TODO: Clearance in config
        var x = 0.floatValue
        var y = 0.floatValue
        var hStep = 0.floatValue

        for i in 0 ..< self.report.rows.count {
            let r = self.report.rows[i]

            var tileIndex = 0
            let rects = r.map { (b) -> CGRect in
                let wMM = b.width * self.report.engineConfig.material.board.size.width
                let w = (wMM).floatValue * self.hScale
                if i == 0 {
                    hStep = self.report.firstRowHeight.floatValue
                } else if i == self.report.rows.count - 1 {
                    hStep = self.report.lastRowHeight.floatValue
                } else {
                    hStep = b.height.floatValue
                }
                hStep *= self.vScale

                if let e = self.report.expansions[.left] {
                    if e[i] > 0 {
                        if (tileIndex == 0) {
                            // We only need to shift first board
                            x -= ((e[i] * self.report.engineConfig.material.board.size.width) * self.hScale.native).floatValue
                        }
                    }
                }

                let r = CGRect(x: x, y: y, width: w, height: hStep)

                self.drawLabel(inContext: ctx, str: "\(wMM.round(1, "f"))", rect: r)

                x += w
                tileIndex += 1
                return r
            }

            y += hStep
            x = 0.floatValue

            ctx.fill(rects) // This invalidates the path
            ctx.addRects(rects) // added here on previous iteration
            ctx.strokePath() // so we need to stroke them
        }
    }

    private func drawLabel(inContext ctx: CGContext, str: String, rect: CGRect) {
        ctx.saveGState()
        defer {
            ctx.restoreGState()
        }

        ctx.setTextDrawingMode(.fill)

        ctx.textMatrix = CGAffineTransform.identity
        // Translate Y axis
        ctx.textMatrix.d *= -1

        let string = str as CFString
        
        var fontKern = 114.0
        if fontKern > rect.height / 2  {
            fontKern = rect.height / 2
        }
    
        // Font size if half Rect heigh
        let font = CTFontCreateWithName("System" as CFString, fontKern, nil)
        
        let attributes = [kCTFontAttributeName: font] as [CFString: Any]
        let attrString = CFAttributedStringCreate(kCFAllocatorDefault, string, attributes as CFDictionary)
        let line = CTLineCreateWithAttributedString(attrString!)

        let bounds = CTLineGetImageBounds(line, ctx)
        // + because of coordinate frame of text is bottom/left after translating
        let y = rect.midY + bounds.height * 0.5
        let x = rect.midX - bounds.width * 0.5

        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)
    }

    // TODO: draw top/bottom room rect
    // TODO: draw doors in dark gray
    private func drawHorizontalDoors(inContext ctx: CGContext) {
        // Invert and move up Y axis so the we have simple height calculations
        // Zero is at top left corner, Y points down
        ctx.translateBy(x: self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
        ctx.scaleBy(x: 1, y: -1)

        defer {
            // Invert Y axis back
            ctx.translateBy(x: -self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
            ctx.scaleBy(x: 1, y: -1)
        }

//        ctx.setLineWidth(6.0)
//        ctx.setStrokeColor(CGColor(srgbRed: 255, green: 0, blue: 0, alpha: 1))
        ctx.setStrokeColor(self.borderColor)
        ctx.setLineWidth(4.0)
        ctx.setFillColor(gray: 0.72, alpha: 1.0) // Gray fill

        for d in self.report.doors {
            if (d.edge.isHorizontal) {
                let x = d.frame.origin.x / (d.nomalized ? d.wNorm.floatValue : 1.0) * self.hScale
                let y = d.edge == .top ? 0.0.floatValue : self.report.engineConfig.effectiveCoverSize.height.floatValue * self.vScale
                let w = d.frame.size.width / (d.nomalized ? d.wNorm.floatValue : 1.0) * self.hScale
                let h = d.frame.size.height / (d.nomalized ? d.hNorm.floatValue : 1.0) * (d.edge == .top ? -1.0 : 1.0) * self.vScale
                ctx.fill(CGRect(x: x, y: y, width: w, height: h))
                ctx.addRect(CGRect(x: x, y: y, width: w, height: h))
                ctx.strokePath()
            }
        }
    }
    
    private func drawHelpers(inContext ctx: CGContext) {
        let config = self.report.engineConfig

        ctx.translateBy(x: self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
        ctx.scaleBy(x: 1, y: -1)
        
        defer {
            // Invert Y axis back
            ctx.translateBy(x: -self.sideMarginPoints.floatValue, y: (ctx.height - self.topMarginPoints).floatValue)
            ctx.scaleBy(x: 1, y: -1)
        }

        ctx.setStrokeColor(CGColor(srgbRed: 200, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(2.0)

        for m in config.horizontalMarks {
            let y = m * self.vScale
            
            var points = [CGPoint]()
            points.append(CGPoint(x: -100, y: y))
            points.append(CGPoint(x: self.effectiveW + 100, y: y))
            ctx.addLines(between: points)
            ctx.closePath()
            ctx.strokePath()
        }

        for m in config.verticalMarks {
            let x = m * self.hScale
            
            var points = [CGPoint]()
            points.append(CGPoint(x: x, y: -20))
            points.append(CGPoint(x: x, y: self.effectiveH+20))
            ctx.addLines(between: points)
            ctx.closePath()
            ctx.strokePath()
        }

//        config.horizontalMarks
        
    }
}
