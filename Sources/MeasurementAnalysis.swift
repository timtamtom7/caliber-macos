import Foundation

struct MeasurementAnalysis {
    var average: Double
    var min: Double
    var max: Double
    var count: Int
    var range: Double

    init(measurements: [Double]) {
        guard !measurements.isEmpty else {
            average = 0
            min = 0
            max = 0
            count = 0
            range = 0
            return
        }

        average = measurements.reduce(0, +) / Double(measurements.count)
        min = measurements.min() ?? 0
        max = measurements.max() ?? 0
        count = measurements.count
        range = max - min
    }
}

final class StatisticsManager {
    static let shared = StatisticsManager()

    private let statsKey = "measurementStats"

    private init() {}

    func analyze(measurements: [Double]) -> MeasurementAnalysis {
        MeasurementAnalysis(measurements: measurements)
    }

    func saveAnalysis(_ analysis: MeasurementAnalysis, for category: String) {
        let data: [String: Any] = [
            "average": analysis.average,
            "min": analysis.min,
            "max": analysis.max,
            "count": analysis.count,
            "range": analysis.range,
            "category": category,
            "timestamp": Date()
        ]
        UserDefaults.standard.set(data, forKey: "\(statsKey)_\(category)")
    }

    func getAnalysis(for category: String) -> [String: Any]? {
        UserDefaults.standard.dictionary(forKey: "\(statsKey)_\(category)")
    }
}
