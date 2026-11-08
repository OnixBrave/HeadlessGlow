// Generates the HeadlessGlow icon (AppIcon.iconset): a dark, backlit keyboard key
// on a graphite background. Fully vector drawing (no SF Symbols, whose
// license forbids using them in app icons).
//   make-icon <folder.iconset>
import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func gradient(_ stops: [(UInt32, CGFloat, CGFloat)]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
               colors: stops.map { color($0.0, $0.1) } as CFArray,
               locations: stops.map { $0.2 })!
}

/// "Continuous" rounded rectangle (approximates the Apple icon curve).
func squircle(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let k: CGFloat = 1.28   // stretches the transitions to soften the curvature
    let rr = min(radius * k, min(r.width, r.height) / 2)
    let c: CGFloat = 0.62   // control point tension
    p.move(to: CGPoint(x: r.minX + rr, y: r.minY))
    p.addLine(to: CGPoint(x: r.maxX - rr, y: r.minY))
    p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + rr),
               control1: CGPoint(x: r.maxX - rr * (1 - c), y: r.minY), control2: CGPoint(x: r.maxX, y: r.minY + rr * (1 - c)))
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - rr))
    p.addCurve(to: CGPoint(x: r.maxX - rr, y: r.maxY),
               control1: CGPoint(x: r.maxX, y: r.maxY - rr * (1 - c)), control2: CGPoint(x: r.maxX - rr * (1 - c), y: r.maxY))
    p.addLine(to: CGPoint(x: r.minX + rr, y: r.maxY))
    p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - rr),
               control1: CGPoint(x: r.minX + rr * (1 - c), y: r.maxY), control2: CGPoint(x: r.minX, y: r.maxY - rr * (1 - c)))
    p.addLine(to: CGPoint(x: r.minX, y: r.minY + rr))
    p.addCurve(to: CGPoint(x: r.minX + rr, y: r.minY),
               control1: CGPoint(x: r.minX, y: r.minY + rr * (1 - c)), control2: CGPoint(x: r.minX + rr * (1 - c), y: r.minY))
    p.closeSubpath()
    return p
}

func render(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ns = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ns
    let ctx = ns.cgContext
    ctx.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    ctx.setShouldAntialias(true)

    // Apple grid: 824 pt body centered in 1024.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = squircle(body, 185)

    // Icon drop shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.35))
    ctx.addPath(bodyPath); ctx.setFillColor(color(0x101218)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath); ctx.clip()

    // Background: bluish graphite, lighter at the top.
    ctx.drawLinearGradient(gradient([(0x3A4258, 1, 0), (0x1B1F2B, 1, 0.55), (0x0D0F15, 1, 1)]),
                           start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    // Backlight glow escaping from under the key.
    let center = CGPoint(x: 512, y: 488)
    ctx.drawRadialGradient(gradient([(0xFFFFFF, 0.75, 0), (0xDCE8FF, 0.42, 0.40), (0x8FB4FF, 0.16, 0.66), (0x5A7BD6, 0, 1)]),
                           startCenter: center, startRadius: 0, endCenter: center, endRadius: 440, options: [])

    // Key: skirt (outline), then a slightly inset top face.
    let skirt = CGRect(x: 512 - 222, y: 488 - 222, width: 444, height: 444)
    let skirtPath = squircle(skirt, 92)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: color(0x000000, 0.55))
    ctx.addPath(skirtPath); ctx.setFillColor(color(0x15171D)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(skirtPath); ctx.clip()
    ctx.drawLinearGradient(gradient([(0x2C303B, 1, 0), (0x171920, 1, 1)]),
                           start: CGPoint(x: 512, y: skirt.maxY), end: CGPoint(x: 512, y: skirt.minY), options: [])
    ctx.restoreGState()
    // Bright rim around the key (light leaking between the keys).
    ctx.addPath(skirtPath); ctx.setStrokeColor(color(0xF2F6FF, 0.55)); ctx.setLineWidth(5); ctx.strokePath()

    let top = skirt.insetBy(dx: 30, dy: 30).offsetBy(dx: 0, dy: 14)
    let topPath = squircle(top, 70)
    ctx.saveGState()
    ctx.addPath(topPath); ctx.clip()
    ctx.drawLinearGradient(gradient([(0x343846, 1, 0), (0x22252E, 1, 1)]),
                           start: CGPoint(x: 512, y: top.maxY), end: CGPoint(x: 512, y: top.minY), options: [])
    ctx.restoreGState()
    ctx.addPath(topPath); ctx.setStrokeColor(color(0xFFFFFF, 0.10)); ctx.setLineWidth(3); ctx.strokePath()

    // Legend: "light" symbol (half sun, rays, baseline) in glowing white.
    let base = CGPoint(x: 512, y: top.midY - 40)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 26, color: color(0xCFE0FF, 0.95))
    ctx.setStrokeColor(color(0xFFFFFF)); ctx.setFillColor(color(0xFFFFFF))
    ctx.setLineCap(.round); ctx.setLineWidth(20)
    ctx.addArc(center: base, radius: 54, startAngle: 0, endAngle: .pi, clockwise: false)
    ctx.closePath(); ctx.fillPath()
    for angle in stride(from: 18.0, through: 162.0, by: 36.0) {   // fan of 5 rays
        let a = CGFloat(angle) * .pi / 180
        ctx.move(to: CGPoint(x: base.x + cos(a) * 86, y: base.y + sin(a) * 86))
        ctx.addLine(to: CGPoint(x: base.x + cos(a) * 124, y: base.y + sin(a) * 124))
    }
    ctx.strokePath()
    ctx.move(to: CGPoint(x: base.x - 112, y: base.y - 2)); ctx.addLine(to: CGPoint(x: base.x + 112, y: base.y - 2))
    ctx.strokePath()
    ctx.restoreGState()

    // Subtle top sheen on the icon body.
    ctx.drawLinearGradient(gradient([(0xFFFFFF, 0.10, 0), (0xFFFFFF, 0, 1)]),
                           start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 640), options: [])
    ctx.restoreGState()

    // Body rim.
    ctx.addPath(bodyPath); ctx.setStrokeColor(color(0xFFFFFF, 0.08)); ctx.setLineWidth(3); ctx.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
                   ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    let data = render(pixels: px).representation(using: .png, properties: [:])!
    try! data.write(to: out.appendingPathComponent("icon_\(name).png"))
}
