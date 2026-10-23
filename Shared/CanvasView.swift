import AppKit

enum CanvasBackground: String, CaseIterable, Identifiable {
    case checkerboard, dark, gray, white

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkerboard: return "Checkerboard"
        case .dark: return "Dark"
        case .gray: return "Gray"
        case .white: return "White"
        }
    }
}

/// Fills itself with a background and hosts one content view (the Lottie view) edge to edge.
final class CanvasView: NSView {
    var background: CanvasBackground = .checkerboard {
        didSet { if background != oldValue { needsDisplay = true } }
    }

    private let tileSize: CGFloat = 10

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }

    /// Replaces all subviews with `content`, sized to fill.
    func setContent(_ content: NSView) {
        subviews.forEach { $0.removeFromSuperview() }
        content.frame = bounds
        content.autoresizingMask = [.width, .height]
        addSubview(content)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        switch background {
        case .checkerboard:
            let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let base = isDark ? NSColor(white: 0.15, alpha: 1) : NSColor(white: 1.0, alpha: 1)
            let tile = isDark ? NSColor(white: 0.20, alpha: 1) : NSColor(white: 0.91, alpha: 1)
            base.setFill()
            dirtyRect.fill()

            let path = NSBezierPath()
            let firstCol = Int(floor(dirtyRect.minX / tileSize)), lastCol = Int(ceil(dirtyRect.maxX / tileSize))
            let firstRow = Int(floor(dirtyRect.minY / tileSize)), lastRow = Int(ceil(dirtyRect.maxY / tileSize))
            for row in firstRow..<max(firstRow, lastRow) {
                for col in firstCol..<max(firstCol, lastCol) where (row + col) & 1 == 0 {
                    path.appendRect(NSRect(x: CGFloat(col) * tileSize, y: CGFloat(row) * tileSize,
                                           width: tileSize, height: tileSize))
                }
            }
            tile.setFill()
            path.fill()
        case .dark:
            NSColor(white: 0.08, alpha: 1).setFill()
            dirtyRect.fill()
        case .gray:
            NSColor(white: 0.5, alpha: 1).setFill()
            dirtyRect.fill()
        case .white:
            NSColor.white.setFill()
            dirtyRect.fill()
        }
    }
}
