import Foundation

struct MeasurementExport {
    let records: [MeasurementRecord]
    let exportDate: Date
    let version: String
}

final class ExportManager {
    static let shared = ExportManager()

    private init() {}

    func exportToJSON(records: [MeasurementRecord]) -> Data? {
        let export = MeasurementExport(
            records: records,
            exportDate: Date(),
            version: "R10"
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func exportToCSV(records: [MeasurementRecord]) -> String {
        var lines = ["timestamp,value,unit,category,notes"]
        let dateFormatter = ISO8601DateFormatter()

        for record in records {
            let date = dateFormatter.string(from: record.timestamp)
            let notes = (record.notes ?? "").replacingOccurrences(of: ",", with: ";")
            lines.append("\(date),\(record.value),\(record.unit),\(record.category),\"\(notes)\"")
        }

        return lines.joined(separator: "\n")
    }

    func saveExport(records: [MeasurementRecord], format: ExportFormat) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let fileName: String
        let data: Data?

        switch format {
        case .json:
            fileName = "Caliber-Export-\(dateStr).json"
            data = exportToJSON(records: records)
        case .csv:
            fileName = "Caliber-Export-\(dateStr).csv"
            data = exportToCSV(records: records).data(using: .utf8)
        }

        guard let exportData = data else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try exportData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
}
