// Renders App/Assets.xcassets/AppIcon.appiconset: three short easing curves
// stacked vertically in black, red, and gold (a quiet nod to the German flag).
// Usage: swift scripts/make-icon.swift
import AppKit

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    func c(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255, alpha: a)
    }
    // macOS icon grid: 824/1024 body with ~22.5% corner radius.
    let inset = s * 100 / 1024, body = s - 2 * inset
    let rect = CGRect(x: inset, y: inset, width: body, height: body)
    let shape = CGPath(roundedRect: rect, cornerWidth: body * 0.225, cornerHeight: body * 0.225, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.025, color: c(0, 0.35))
    ctx.addPath(shape); ctx.setFillColor(c(0xF4F1EA)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    let grad = CGGradient(colorsSpace: cs, colors: [c(0xFBF9F4), c(0xE9E5DC)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: rect.maxY), end: CGPoint(x: 0, y: rect.minY), options: [])
    // Faint grid.
    ctx.setStrokeColor(c(0x000000, 0.05)); ctx.setLineWidth(max(1, s / 512))
    for i in 1..<8 {
        let v = rect.minX + body * CGFloat(i) / 8
        ctx.move(to: CGPoint(x: v, y: rect.minY)); ctx.addLine(to: CGPoint(x: v, y: rect.maxY))
        ctx.move(to: CGPoint(x: rect.minX, y: v)); ctx.addLine(to: CGPoint(x: rect.maxX, y: v))
    }
    ctx.strokePath()

    // Three short ease-in-out curves, top to bottom: black, red, gold.
    let colors: [UInt32] = [0x1C1C1E, 0xDD0000, 0xF2B500]
    let w = body * 0.52, h = body * 0.16, gap = body * 0.25
    ctx.setLineCap(.round); ctx.setLineWidth(body * 0.075)
    for (i, col) in colors.enumerated() {
        let cy = rect.midY + gap * CGFloat(1 - i)
        let a = CGPoint(x: rect.midX - w / 2, y: cy - h / 2), b = CGPoint(x: rect.midX + w / 2, y: cy + h / 2)
        ctx.move(to: a)
        ctx.addCurve(to: b, control1: CGPoint(x: a.x + w * 0.55, y: a.y), control2: CGPoint(x: b.x - w * 0.55, y: b.y))
        ctx.setStrokeColor(c(col)); ctx.strokePath()
    }
    ctx.restoreGState()

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : "App/Assets.xcassets/AppIcon.appiconset")
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: dir.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: dir.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
