import Foundation

struct MeasurementRecord: Identifiable, Codable {
    let id: UUID
    let value: Double
    let unit: String
    let category: String
    let timestamp: Date
    let notes: String?

    init(value: Double, unit: String, category: String, notes: String? = nil) {
        self.id = UUID()
        self.value = value
        self.unit = unit
        self.category = category
        self.timestamp = Date()
        self.notes = notes
    }
}

final class MeasurementHistoryManager {
    static let shared = MeasurementHistoryManager()

    private let historyKey = "measurementHistory"
    private let maxRecords = 500

    private init() {}

    func addRecord(_ record: MeasurementRecord) {
        var history = fetchHistory()
        history.append(record)

        if history.count > maxRecords {
            history = Array(history.suffix(maxRecords))
        }

        saveHistory(history)
    }

    func fetchHistory() -> [MeasurementRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([MeasurementRecord].self, from: data)
        } catch {
            return []
        }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func saveHistory(_ history: [MeasurementRecord]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save measurement history: \(error)")
        }
    }
}
