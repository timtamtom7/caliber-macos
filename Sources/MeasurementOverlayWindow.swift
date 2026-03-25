import AppKit
import SwiftUI

class MeasurementOverlayWindow: NSWindow {

    private let measurementStore: MeasurementStore
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var overlayView: MeasurementOverlayView!

    init(screen: NSScreen, measurementStore: MeasurementStore) {
        self.measurementStore = measurementStore

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.backgroundColor = NSColor.black.withAlphaComponent(0.01)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        overlayView = MeasurementOverlayView(frame: screen.frame)
        overlayView.onComplete = { [weak self] width, height in
            self?.completeMeasurement(width: width, height: height, screen: screen)
        }
        overlayView.onCancel = { [weak self] in
            self?.cancelMeasurement()
        }

        self.contentView = overlayView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    private func completeMeasurement(width: CGFloat, height: CGFloat, screen: NSScreen) {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.finishMeasurement(width: width, height: height, screen: screen)
    }

    private func cancelMeasurement() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.cancelMeasurement()
    }
}

// MARK: - MeasurementOverlayView

class MeasurementOverlayView: NSView {

    var onComplete: ((CGFloat, CGFloat) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var isDragging = false

    private let selectionColor = NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 0.2) // #007AFF 20%
    private let strokeColor = NSColor.white
    private let labelBackgroundColor = NSColor(calibratedWhite: 0.1, alpha: 0.85)
    private let cornerHandleSize: CGFloat = 8

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        let location = NSEvent.mouseLocation
        // Convert to view coordinates
        let viewLocation = convert(location, from: nil)
        startPoint = viewLocation
        currentPoint = viewLocation
        isDragging = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let start = startPoint else { return }
        let location = NSEvent.mouseLocation
        currentPoint = convert(location, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let start = startPoint, let end = currentPoint else {
            isDragging = false
            return
        }
        isDragging = false

        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)

        // Minimum 1x1
        if width < 1 || height < 1 {
            onCancel?()
            return
        }

        onComplete?(width, height)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let start = startPoint, let current = currentPoint, isDragging else { return }

        let norm = normalize(start, current)

        // Draw semi-transparent overlay outside selection
        NSColor.black.withAlphaComponent(0.15).setFill()
        dirtyRect.fill()

        // Clear the selection rect area
        let selectionRect = NSRect(
            x: norm.0.x,
            y: norm.0.y,
            width: norm.1.x - norm.0.x,
            height: norm.1.y - norm.0.y
        )
        NSColor.clear.setFill()
        selectionRect.fill(using: .copy)

        // Draw selection rect fill
        selectionColor.setFill()
        selectionRect.fill()

        // Draw dashed stroke
        strokeColor.setStroke()
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = 1.0
        let dashPattern: [CGFloat] = [4, 4]
        path.setLineDash(dashPattern, count: 2, phase: 0)
        path.stroke()

        // Draw corner handles
        drawCornerHandles(for: selectionRect)

        // Draw dimension label
        drawDimensionLabel(for: selectionRect, width: norm.1.x - norm.0.x, height: norm.1.y - norm.0.y)
    }

    private func normalize(_ start: NSPoint, _ end: NSPoint) -> (NSPoint, NSPoint) {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        return (NSPoint(x: minX, y: minY), NSPoint(x: maxX, y: maxY))
    }

    private func drawCornerHandles(for rect: NSRect) {
        let handleSize = cornerHandleSize
        let handles = [
            // Top-left
            NSRect(x: rect.minX - handleSize / 2, y: rect.maxY - handleSize / 2, width: handleSize, height: handleSize),
            // Top-right
            NSRect(x: rect.maxX - handleSize / 2, y: rect.maxY - handleSize / 2, width: handleSize, height: handleSize),
            // Bottom-left
            NSRect(x: rect.minX - handleSize / 2, y: rect.minY - handleSize / 2, width: handleSize, height: handleSize),
            // Bottom-right
            NSRect(x: rect.maxX - handleSize / 2, y: rect.minY - handleSize / 2, width: handleSize, height: handleSize)
        ]

        for handle in handles {
            NSColor.white.setFill()
            NSBezierPath(rect: handle).fill()
            NSColor.darkGray.setStroke()
            let strokePath = NSBezierPath(rect: handle)
            strokePath.lineWidth = 1.0
            strokePath.stroke()
        }
    }

    private func drawDimensionLabel(for rect: NSRect, width: CGFloat, height: CGFloat) {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let widthPx = Int(width)
        let heightPx = Int(height)
        let widthPt = Int(width / scaleFactor)
        let heightPt = Int(height / scaleFactor)

        let text = "\(widthPx) × \(heightPx) px / \(widthPt) × \(heightPt) pt"

        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)
        let padding: CGFloat = 8
        let labelWidth = textSize.width + padding * 2
        let labelHeight = textSize.height + padding * 2

        // Position at bottom-right of selection, inside the rect if possible
        var labelX = rect.maxX - labelWidth - 4
        var labelY = rect.minY + 4

        // Clamp so label doesn't go off-screen
        labelX = max(4, min(labelX, bounds.width - labelWidth - 4))
        labelY = max(4, min(labelY, bounds.height - labelHeight - 4))

        let labelRect = NSRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)

        // Draw background pill
        let pillPath = NSBezierPath(roundedRect: labelRect, xRadius: 6, yRadius: 6)
        labelBackgroundColor.setFill()
        pillPath.fill()

        // Draw text
        let textRect = NSRect(
            x: labelX + padding,
            y: labelY + (labelHeight - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }
}
