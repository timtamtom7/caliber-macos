import Foundation

struct Measurement: Identifiable, Equatable {
    let id = UUID()
    let widthPx: Int
    let heightPx: Int
    let widthPt: Int
    let heightPt: Int
    let screenName: String
    let createdAt: Date = Date()

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
}
