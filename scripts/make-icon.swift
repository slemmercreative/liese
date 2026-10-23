// Renders App/Assets.xcassets/AppIcon.appiconset: three short easing curves
// stacked vertically in black, red, and gold (a quiet nod to the German flag),
// It writes two things:
//   App/AppIcon.icon: Icon Composer document (macOS 26+) whose background follows
//     the system light/dark appearance.
//   App/Assets.xcassets/AppIcon.appiconset: light-only fallback for macOS 14 and 15.
// Usage: swift scripts/make-icon.swift
import AppKit

let curveColors: [UInt32] = [0x1C1C1E, 0xDD0000, 0xF2B500]

// Three short ease-in-out curves, top to bottom, centered in `rect`. `only` draws just one.
func strokeCurves(_ ctx: CGContext, in rect: CGRect, only: Int? = nil) {
    let body = rect.width
    let w = body * 0.52, h = body * 0.16, gap = body * 0.21
    ctx.setLineCap(.round); ctx.setLineWidth(body * 0.058)
    for (i, col) in curveColors.enumerated() where only == nil || only == i {
        let cy = rect.midY + gap * CGFloat(1 - i)
        let a = CGPoint(x: rect.midX - w / 2, y: cy - h / 2), b = CGPoint(x: rect.midX + w / 2, y: cy + h / 2)
        ctx.move(to: a)
        ctx.addCurve(to: b, control1: CGPoint(x: a.x + w * 0.55, y: a.y), control2: CGPoint(x: b.x - w * 0.55, y: b.y))
        ctx.setStrokeColor(c(col)); ctx.strokePath()
    }
}

func c(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func png(_ ctx: CGContext) -> Data {
    NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

func canvas(_ px: Int) -> CGContext {
    CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = canvas(px)
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

    strokeCurves(ctx, in: rect)
    ctx.restoreGState()

    return png(ctx)
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset")
for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

// Icon Composer document: one layer per curve on a solid fill; the system adds the
// squircle mask, padding, and glass. Dark mode uses a near-black fill.
let doc = URL(fileURLWithPath: "App/AppIcon.icon")
let assets = doc.appendingPathComponent("Assets")
try? fm.removeItem(at: doc)
try! fm.createDirectory(at: assets, withIntermediateDirectories: true)
let names = ["black", "red", "gold"]
for (i, name) in names.enumerated() {
    let ctx = canvas(1024)
    strokeCurves(ctx, in: CGRect(x: 100, y: 100, width: 824, height: 824), only: i)
    try! png(ctx).write(to: assets.appendingPathComponent("\(name).png"))
}
// On the near-black dark background, the black curve turns charcoal so it stays visible.
let charcoal = #", "fill-specializations" : [ { "appearance" : "dark", "value" : { "solid" : "srgb:0.235,0.235,0.250,1.000" } } ]"#
let layers = names.map { #"{ "image-name" : "\#($0).png", "name" : "\#($0)"\#($0 == "black" ? charcoal : "") }"# }
    .joined(separator: ",\n        ")
let json = """
{
  "fill-specializations" : [
    { "value" : { "automatic-gradient" : "srgb:0.957,0.945,0.918,1.000" } },
    { "appearance" : "dark", "value" : { "automatic-gradient" : "srgb:0.040,0.040,0.045,1.000" } }
  ],
  "groups" : [
    {
      "layers" : [
        \(layers)
      ],
      "shadow" : { "kind" : "neutral", "opacity" : 0.5 },
      "translucency" : { "enabled" : false, "value" : 0.5 }
    }
  ],
  "supported-platforms" : { "squares" : [ "macOS" ] }
}

"""
try! json.write(to: doc.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
