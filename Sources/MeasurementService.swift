import Foundation
import AppKit

class MeasurementService {

    func calculateMeasurement(from start: NSPoint, to end: NSPoint, screen: NSScreen) -> (width: CGFloat, height: CGFloat) {
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        return (width, height)
    }

    func normalizePoints(_ start: NSPoint, _ end: NSPoint) -> (start: NSPoint, end: NSPoint) {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        return (NSPoint(x: minX, y: minY), NSPoint(x: maxX, y: maxY))
    }

    func scaleFactor(for screen: NSScreen) -> CGFloat {
        return screen.backingScaleFactor
    }

    func pixelsToPoints(_ pixels: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        return pixels / scaleFactor
    }

    func pointsToPixels(_ points: CGFloat, scaleFactor: CGFloat) -> CGFloat {
        return points * scaleFactor
    }
}
