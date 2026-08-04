import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the WaveMark (24x24 geometry: round-cap vertical lines at
// x 4/9/14/19, heights 5/15/9/19 centered on y = 12, lineWidth 1.6) into
// 1024x1024 app icon PNGs, mark spanning the middle ~55% of the canvas.

let canvas: CGFloat = 1024
let markFraction: CGFloat = 0.55
let scale = canvas * markFraction / 24.0
let origin = (canvas - 24 * scale) / 2
// The four lines span x 4...19, centered on 11.5 rather than 12 — nudge
// half a unit right so the mark is optically centered on the icon.
let xNudge = (12.0 - 11.5) * scale

struct Line { let x: CGFloat; let height: CGFloat }
let lines: [Line] = [
    Line(x: 4, height: 5),
    Line(x: 9, height: 15),
    Line(x: 14, height: 9),
    Line(x: 19, height: 19),
]

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func render(background: CGColor?, stroke: CGColor, to url: URL) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: Int(canvas),
        height: Int(canvas),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("Could not create bitmap context") }

    if let background {
        context.setFillColor(background)
        context.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
    }

    context.setStrokeColor(stroke)
    context.setLineWidth(1.6 * scale)
    context.setLineCap(.round)

    // Vertical lines are symmetric about y = 12, so the CG flipped-y origin
    // needs no correction.
    for line in lines {
        let x = origin + line.x * scale + xNudge
        let half = line.height / 2 * scale
        let midY = origin + 12 * scale
        context.move(to: CGPoint(x: x, y: midY - half))
        context.addLine(to: CGPoint(x: x, y: midY + half))
        context.strokePath()
    }

    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
          ) else { fatalError("Could not create image destination") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(url.path)")
    }
    print("Wrote \(url.path)")
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath)

// Light: near-white mark on brand primary.
render(
    background: color(0x007A55),
    stroke: color(0xECFDF5),
    to: outDir.appendingPathComponent("AppIcon.png")
)
// Dark: emerald mark on near-black.
render(
    background: color(0x0A0A0A),
    stroke: color(0x00C08B),
    to: outDir.appendingPathComponent("AppIcon-Dark.png")
)
// Tinted: grayscale mark on transparent (system supplies the tint).
render(
    background: nil,
    stroke: color(0xEDEDED),
    to: outDir.appendingPathComponent("AppIcon-Tinted.png")
)
