import Foundation
import Combine
import AppKit

class MeasurementStore: ObservableObject {

    @Published var isMeasuring: Bool = false
    @Published var currentMeasurement: Measurement?
    @Published var lastMeasurement: Measurement?
    @Published var measurementHistory: [Measurement] = []

    private let measurementService = MeasurementService()

    func addToHistory(_ measurement: Measurement) {
        measurementHistory.insert(measurement, at: 0)
        // Keep last 20 measurements
        if measurementHistory.count > 20 {
            measurementHistory = Array(measurementHistory.prefix(20))
        }
    }

    func clearHistory() {
        measurementHistory.removeAll()
        lastMeasurement = nil
        currentMeasurement = nil
    }

    func copyLastToClipboard() {
        guard let last = lastMeasurement else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(last.shortFormat, forType: .string)
    }

    func copyExpandedToClipboard() {
        guard let last = lastMeasurement else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(last.expandedFormat, forType: .string)
    }
}
