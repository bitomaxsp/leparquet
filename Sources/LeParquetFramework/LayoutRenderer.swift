//
//  File.swift
//
//
//  Created by Dmitry on 2021-05-23.
//

import Foundation

/// Amount of margin for the drawing in points
private let MarginPoints = 300

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
    /// Object scale in px/mm
    private let scale: CGFloat
    private let borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

    init(_ file: URL, _ report: RawReport) {
        self.report = report
        self.filePath = file.appendingPathExtension("png")
        self.roomWHRatio = report.engineConfig.effectiveRoomSize.width / report.engineConfig.effectiveRoomSize.height
        self.topMarginPoints = MarginPoints
        self.sideMarginPoints = Int(self.topMarginPoints.doubleValue * self.roomWHRatio)
        self.imageW = 5000 // TODO: what to do for big scale?
        self.imageH = Int(self.imageW.doubleValue / self.roomWHRatio)
        self.scale = ((self.imageW - self.sideMarginPoints * 2).doubleValue / report.engineConfig.effectiveRoomSize.width).floatValue
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
        ctx.setBlendMode(.normal)
    }

    private func draw(inContext ctx: CGContext) {
        self.setup(context: ctx)

        // Fill BG
        ctx.setFillColor(CGColor(red: 255, green: 255, blue: 255, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))

        self.drawBoards(inContext: ctx)
        self.drawHorizontalDoors(inContext: ctx)
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
        ctx.setLineWidth(4.0)
        ctx.setFillColor(gray: 0.72, alpha: 1.0) // Gray fill

        // TODO: Clearance in config
        var x = 0.floatValue
        var y = 0.floatValue
        var hStep = 0.floatValue

        for i in 0 ..< self.report.rows.count {
            let r = self.report.rows[i]

            var tileIndex = 0
            let rects = r.map { (b) -> CGRect in
                let w = (b.width * self.report.engineConfig.material.board.size.width).floatValue * self.scale
                if i == 0 {
                    hStep = self.report.firstRowHeight.floatValue
                } else if i == self.report.rows.count - 1 {
                    hStep = self.report.lastRowHeight.floatValue
                } else {
                    hStep = b.height.floatValue
                }
                hStep *= self.scale

                if let e = self.report.expansions[.left] {
                    if e[i] > 0 {
                        if (tileIndex == 0) {
                            // We only need to shift first board
                            x -= ((e[i] * self.report.engineConfig.material.board.size.width) * self.scale.native).floatValue
                        }
                    }
                }

                let r = CGRect(x: x, y: y, width: w, height: hStep)
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

        // TODO: draw top/bottom room rect
        // TODO: draw doors in dark gray
    }

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
                let x = d.frame.origin.x / (d.nomalized ? d.wNorm.floatValue : 1.0)
                let y = d.edge == .top ? 0.0.floatValue : self.report.engineConfig.effectiveRoomSize.height.floatValue * self.scale
                let w = d.frame.size.width / (d.nomalized ? d.wNorm.floatValue : 1.0)
                let h = d.frame.size.height / (d.nomalized ? d.hNorm.floatValue : 1.0) * (d.edge == .top ? -1.0 : 1.0)
                ctx.fill(CGRect(x: x, y: y, width: w, height: h))
                ctx.addRect(CGRect(x: x, y: y, width: w, height: h))
                ctx.strokePath()
            }
        }
    }
}
