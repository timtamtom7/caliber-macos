import Foundation
import Combine
import AppKit

// MARK: - Custom Preset

struct MeasurementPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var widthPt: Int
    var heightPt: Int
    var category: String

    init(id: UUID = UUID(), name: String, widthPt: Int, heightPt: Int, category: String = "Custom") {
        self.id = id
        self.name = name
        self.widthPt = widthPt
        self.heightPt = heightPt
        self.category = category
    }
}

// MARK: - Unit

enum MeasurementUnit: String, CaseIterable, Codable {
    case px = "px"
    case pt = "pt"
    case inch = "inch"
    case cm = "cm"
    case mm = "mm"

    var displayName: String {
        switch self {
        case .px: return "Pixels"
        case .pt: return "Points"
        case .inch: return "Inches"
        case .cm: return "Centimeters"
        case .mm: return "Millimeters"
        }
    }

    var shortName: String {
        rawValue
    }

    // Convert pt to this unit
    func fromPt(_ pt: Double, dpi: Double = 72) -> Double {
        switch self {
        case .px: return pt * dpi / 72
        case .pt: return pt
        case .inch: return pt / 72
        case .cm: return pt / 72 * 2.54
        case .mm: return pt / 72 * 25.4
        }
    }

    // Convert to pt from this unit
    func toPt(_ value: Double, dpi: Double = 72) -> Double {
        switch self {
        case .px: return value * 72 / dpi
        case .pt: return value
        case .inch: return value * 72
        case .cm: return value / 2.54 * 72
        case .mm: return value / 25.4 * 72
        }
    }
}

// MARK: - Measurement with Units

struct Measurement: Identifiable, Equatable, Codable {
    let id: UUID
    let widthPx: Int
    let heightPx: Int
    let widthPt: Int
    let heightPt: Int
    let screenName: String
    let createdAt: Date
    let dpi: Double

    init(
        id: UUID = UUID(),
        widthPx: Int,
        heightPx: Int,
        widthPt: Int,
        heightPt: Int,
        screenName: String,
        createdAt: Date = Date(),
        dpi: Double = 144
    ) {
        self.id = id
        self.widthPx = widthPx
        self.heightPx = heightPx
        self.widthPt = widthPt
        self.heightPt = heightPt
        self.screenName = screenName
        self.createdAt = createdAt
        self.dpi = dpi
    }

    var formattedPx: String {
        "\(widthPx) × \(heightPx) px"
    }

    var formattedPt: String {
        "\(widthPt) × \(heightPt) pt"
    }

    var shortFormat: String {
        "\(widthPx)×\(heightPx)"
    }

    var expandedFormat: String {
        "\(widthPx) × \(heightPx) px (\(widthPt) × \(heightPt) pt)"
    }

    func formatted(unit: MeasurementUnit) -> String {
        let w = unit.fromPt(Double(widthPt), dpi: dpi)
        let h = unit.fromPt(Double(heightPt), dpi: dpi)
        let formatter = unit == .px || unit == .pt ? "%.0f" : "%.2f"
        return String(format: "\(formatter) × \(formatter) %@", w, h, unit.shortName)
    }
}

// MARK: - MeasurementStore

class MeasurementStore: ObservableObject {

    @Published var isMeasuring: Bool = false
    @Published var currentMeasurement: Measurement?
    @Published var lastMeasurement: Measurement?
    @Published var measurementHistory: [Measurement] = []
    @Published var presets: [MeasurementPreset] = []
    @Published var selectedUnit: MeasurementUnit = .pt {
        didSet { UserDefaults.standard.set(selectedUnit.rawValue, forKey: "caliber_unit") }
    }
    @Published var dpi: Double = 144 {
        didSet { UserDefaults.standard.set(dpi, forKey: "caliber_dpi") }
    }

    private let presetsKey = "caliber_presets"
    private let historyKey = "caliber_history"

    init() {
        loadPresets()
        loadHistory()
        loadSettings()
        ensureDefaultPresets()
    }

    // MARK: - History

    func addToHistory(_ measurement: Measurement) {
        measurementHistory.insert(measurement, at: 0)
        if measurementHistory.count > 50 {
            measurementHistory = Array(measurementHistory.prefix(50))
        }
        saveHistory()
    }

    func clearHistory() {
        measurementHistory.removeAll()
        lastMeasurement = nil
        currentMeasurement = nil
        saveHistory()
    }

    func deleteHistoryItem(_ id: UUID) {
        measurementHistory.removeAll { $0.id == id }
        saveHistory()
    }

    // MARK: - Presets

    func addPreset(_ preset: MeasurementPreset) {
        presets.append(preset)
        savePresets()
    }

    func deletePreset(_ id: UUID) {
        presets.removeAll { $0.id == id }
        savePresets()
    }

    func updatePreset(_ preset: MeasurementPreset) {
        if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[idx] = preset
            savePresets()
        }
    }

    private func ensureDefaultPresets() {
        if presets.isEmpty {
            presets = [
                MeasurementPreset(name: "iPhone SE", widthPt: 320, heightPt: 568, category: "iPhone"),
                MeasurementPreset(name: "iPhone 14", widthPt: 390, heightPt: 844, category: "iPhone"),
                MeasurementPreset(name: "iPad Mini", widthPt: 768, heightPt: 1024, category: "iPad"),
                MeasurementPreset(name: "iPad Pro 11", widthPt: 834, heightPt: 1194, category: "iPad"),
                MeasurementPreset(name: "MacBook Air 13", widthPt: 900, heightPt: 600, category: "Mac"),
                MeasurementPreset(name: "1080p Display", widthPt: 1920, heightPt: 1080, category: "Display"),
                MeasurementPreset(name: "4K Display", widthPt: 3840, heightPt: 2160, category: "Display"),
                MeasurementPreset(name: "Instagram Square", widthPt: 540, heightPt: 540, category: "Social"),
                MeasurementPreset(name: "Twitter Header", widthPt: 1500, heightPt: 500, category: "Social"),
            ]
            savePresets()
        }
    }

    // MARK: - Clipboard

    func copyLastToClipboard(unit: MeasurementUnit? = nil) {
        guard let last = lastMeasurement else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let text = unit != nil ? last.formatted(unit: unit!) : last.shortFormat
        pasteboard.setString(text, forType: .string)
    }

    func copyExpandedToClipboard() {
        guard let last = lastMeasurement else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(last.expandedFormat, forType: .string)
    }

    // MARK: - Measurement Control

    func startMeasuring() {
        isMeasuring = true
        currentMeasurement = nil
    }

    func stopMeasuring() {
        isMeasuring = false
    }

    // MARK: - Unit Conversion

    func convert(width: Int, height: Int, from: MeasurementUnit, to: MeasurementUnit) -> (width: Double, height: Double) {
        let wPt = from.toPt(Double(width), dpi: dpi)
        let hPt = from.toPt(Double(height), dpi: dpi)
        return (to.fromPt(wPt, dpi: dpi), to.fromPt(hPt, dpi: dpi))
    }

    // MARK: - Persistence

    private func savePresets() {
        guard let encoded = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(encoded, forKey: presetsKey)
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: presetsKey),
              let decoded = try? JSONDecoder().decode([MeasurementPreset].self, from: data) else {
            return
        }
        presets = decoded
    }

    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(measurementHistory) else { return }
        UserDefaults.standard.set(encoded, forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([Measurement].self, from: data) else {
            return
        }
        measurementHistory = decoded
    }

    private func loadSettings() {
        if let unitRaw = UserDefaults.standard.string(forKey: "caliber_unit"),
           let unit = MeasurementUnit(rawValue: unitRaw) {
            selectedUnit = unit
        }
        if UserDefaults.standard.object(forKey: "caliber_dpi") != nil {
            dpi = UserDefaults.standard.double(forKey: "caliber_dpi")
        }
    }
}
