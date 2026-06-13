import AppKit

private let outputPath = CommandLine.arguments.dropFirst().first ?? "docs/screenshot.png"
private let canvas = CGSize(width: 1440, height: 900)

private func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

private func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

private func text(
    _ value: String,
    _ rect: NSRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .white,
    alignment: NSTextAlignment = .left,
    monospaced: Bool = false
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    let font = monospaced
        ? NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        : NSFont.systemFont(ofSize: size, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    (value as NSString).draw(in: rect, withAttributes: attributes)
}

private final class ReadmeScreenshotView: NSView {
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSGradient(colors: [color(0x101214), color(0x1b211d)])?
            .draw(in: bounds, angle: -18)

        rounded(NSRect(x: 0, y: 0, width: canvas.width, height: 46), radius: 0, fill: color(0xf0f0ee, 0.82))
        text("Finder", NSRect(x: 28, y: 14, width: 70, height: 20), size: 15, weight: .medium, color: color(0x2c2d2f))
        text("File", NSRect(x: 110, y: 14, width: 50, height: 20), size: 15, color: color(0x37383a))
        text("Edit", NSRect(x: 186, y: 14, width: 50, height: 20), size: 15, color: color(0x37383a))
        text("View", NSRect(x: 256, y: 14, width: 54, height: 20), size: 15, color: color(0x37383a))
        text("Go", NSRect(x: 334, y: 14, width: 40, height: 20), size: 15, color: color(0x37383a))
        text("Window", NSRect(x: 394, y: 14, width: 76, height: 20), size: 15, color: color(0x37383a))
        text("Help", NSRect(x: 478, y: 14, width: 55, height: 20), size: 15, color: color(0x37383a))

        rounded(NSRect(x: 1090, y: 8, width: 178, height: 30), radius: 15, fill: color(0x151719))
        rounded(NSRect(x: 1105, y: 19, width: 8, height: 8), radius: 4, fill: color(0x39ff14))
        text("Claude", NSRect(x: 1122, y: 13, width: 62, height: 18), size: 14, weight: .medium, color: color(0xf2f7f1))
        text("68%", NSRect(x: 1190, y: 13, width: 54, height: 18), size: 14, weight: .semibold, color: color(0x39ff14), monospaced: true)
        text("Sat 5:25 PM", NSRect(x: 1296, y: 14, width: 118, height: 20), size: 15, color: color(0x2f3032))

        text("claude-usage", NSRect(x: 116, y: 600, width: 420, height: 58), size: 46, weight: .semibold, color: color(0xf4f7f2))
        text("Real-time Claude Code limits\nfrom the macOS menu bar.", NSRect(x: 118, y: 672, width: 420, height: 58), size: 23, color: color(0xd8ddd6))
        rounded(NSRect(x: 118, y: 750, width: 224, height: 42), radius: 21, fill: color(0x00e676))
        text("Download for macOS", NSRect(x: 142, y: 762, width: 176, height: 20), size: 16, weight: .semibold, color: color(0x101214), alignment: .center)

        let panel = NSRect(x: 836, y: 68, width: 450, height: 280)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = color(0x000000, 0.32)
        shadow.shadowBlurRadius = 34
        shadow.shadowOffset = NSSize(width: 0, height: -18)
        shadow.set()
        rounded(panel, radius: 18, fill: color(0x1d2022, 0.96), stroke: color(0xffffff, 0.10))
        NSGraphicsContext.restoreGraphicsState()

        rounded(NSRect(x: 862, y: 94, width: 10, height: 10), radius: 5, fill: color(0x39ff14))
        text("Claude", NSRect(x: 884, y: 86, width: 120, height: 28), size: 20, weight: .medium, color: color(0xf3f6f0))
        rounded(NSRect(x: 1174, y: 82, width: 56, height: 28), radius: 14, fill: color(0xffffff, 0.08))
        text("Pro", NSRect(x: 1174, y: 88, width: 56, height: 16), size: 12, weight: .medium, color: color(0xcbd0cc), alignment: .center)

        card(x: 856, y: 126, title: "현재 세션", percent: "68%", detail: "1시간 52분 후 재설정", tint: color(0x39ff14), progress: 0.68)
        card(x: 856, y: 220, title: "모든 모델", percent: "41%", detail: "(일) 오후 6:59에 재설정", tint: color(0x38d8f2), progress: 0.41)

        text("업데이트 오후 5:25", NSRect(x: 860, y: 314, width: 180, height: 18), size: 11, color: color(0xffffff, 0.36))
        text("종료", NSRect(x: 1196, y: 314, width: 40, height: 18), size: 11, color: color(0x39ff14, 0.86), alignment: .right)
    }

    private func card(x: CGFloat, y: CGFloat, title: String, percent: String, detail: String, tint: NSColor, progress: CGFloat) {
        rounded(NSRect(x: x, y: y, width: 394, height: 78), radius: 10, fill: color(0xffffff, 0.055))
        text(title, NSRect(x: x + 16, y: y + 15, width: 130, height: 18), size: 13, weight: .semibold, color: color(0xc2c8c2))
        text(percent, NSRect(x: x + 280, y: y + 10, width: 92, height: 30), size: 30, weight: .bold, color: tint, alignment: .right, monospaced: true)
        rounded(NSRect(x: x + 16, y: y + 47, width: 360, height: 6), radius: 3, fill: color(0xffffff, 0.08))
        rounded(NSRect(x: x + 16, y: y + 47, width: 360 * progress, height: 6), radius: 3, fill: tint)
        text(detail, NSRect(x: x + 16, y: y + 59, width: 230, height: 16), size: 12, weight: .medium, color: color(0xffffff, 0.48))
    }
}

private let view = ReadmeScreenshotView(frame: NSRect(origin: .zero, size: canvas))
private let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
view.cacheDisplay(in: view.bounds, to: rep)

guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not render screenshot PNG")
}

try data.write(to: URL(fileURLWithPath: outputPath))
