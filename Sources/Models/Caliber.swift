import Foundation

// MARK: - Measurement Project

struct MeasurementProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    var measurements: [SavedMeasurement]
    var photos: [MeasurementPhoto]
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        measurements: [SavedMeasurement] = [],
        photos: [MeasurementPhoto] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.measurements = measurements
        self.photos = photos
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.isFavorite = isFavorite
    }
}

struct SavedMeasurement: Identifiable, Codable {
    let id: UUID
    var value: Double
    var unit: MeasurementUnit
    var label: String?
    var pointA: CGPoint?
    var pointB: CGPoint?
    var timestamp: Date
    var confidence: Double?

    init(
        id: UUID = UUID(),
        value: Double,
        unit: MeasurementUnit,
        label: String? = nil,
        pointA: CGPoint? = nil,
        pointB: CGPoint? = nil,
        timestamp: Date = Date(),
        confidence: Double? = nil
    ) {
        self.id = id
        self.value = value
        self.unit = unit
        self.label = label
        self.pointA = pointA
        self.pointB = pointB
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

struct MeasurementPhoto: Identifiable, Codable {
    let id: UUID
    var imagePath: String
    var measurements: [SavedMeasurement]
    var notes: String?
    var takenAt: Date
    var location: String?

    init(
        id: UUID = UUID(),
        imagePath: String,
        measurements: [SavedMeasurement] = [],
        notes: String? = nil,
        takenAt: Date = Date(),
        location: String? = nil
    ) {
        self.id = id
        self.imagePath = imagePath
        self.measurements = measurements
        self.notes = notes
        self.takenAt = takenAt
        self.location = location
    }
}

// Note: MeasurementUnit is defined in MeasurementStore.swift

// MARK: - Ruler Calibration

struct RulerCalibration: Codable {
    var knownDistance: Double
    var knownUnit: MeasurementUnit
    var pixelEquivalent: Double
    var calibrationDate: Date
    var referenceObject: CalibrationReference?

    init(
        knownDistance: Double = 0,
        knownUnit: MeasurementUnit = .inch,
        pixelEquivalent: Double = 0,
        calibrationDate: Date = Date(),
        referenceObject: CalibrationReference? = nil
    ) {
        self.knownDistance = knownDistance
        self.knownUnit = knownUnit
        self.pixelEquivalent = pixelEquivalent
        self.calibrationDate = calibrationDate
        self.referenceObject = referenceObject
    }

    func pixelsToUnit(_ pixels: Double, unit: MeasurementUnit) -> Double {
        // Convert pixels to the calibrated unit
        let basePixels = pixels / pixelEquivalent
        return basePixels * knownDistance
    }
}

enum CalibrationReference: String, Codable, CaseIterable {
    case creditCard = "Credit Card (85.6mm × 53.98mm)"
    case usLetter = "US Letter (8.5in × 11in)"
    case a4Paper = "A4 Paper (210mm × 297mm)"
    case dollarBill = "US Dollar Bill (6.14in × 2.61in)"
    case custom = "Custom"

    var standardSize: (width: Double, height: Double, unit: MeasurementUnit)? {
        switch self {
        case .creditCard:
            return (85.6, 53.98, .mm)
        case .usLetter:
            return (8.5, 11.0, .inch)
        case .a4Paper:
            return (210, 297, .mm)
        case .dollarBill:
            return (6.14, 2.61, .inch)
        case .custom:
            return nil
        }
    }
}

// MARK: - Measurement Intelligence

struct MeasurementInsight: Identifiable, Codable {
    let id: UUID
    var type: InsightType
    var title: String
    var description: String
    var measurements: [UUID]
    var confidence: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        measurements: [UUID] = [],
        confidence: Double = 0.8,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.measurements = measurements
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

enum InsightType: String, Codable {
    case pattern = "Pattern Detected"
    case anomaly = "Anomaly"
    case suggestion = "Suggestion"
    case comparison = "Comparison"
    case trend = "Trend"
}

// MARK: - PDF Report

struct MeasurementReport: Identifiable, Codable {
    let id: UUID
    var projectId: UUID
    var title: String
    var includePhotos: Bool
    var includeDiagrams: Bool
    var includeSummary: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        includePhotos: Bool = true,
        includeDiagrams: Bool = true,
        includeSummary: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.includePhotos = includePhotos
        self.includeDiagrams = includeDiagrams
        self.includeSummary = includeSummary
        self.createdAt = createdAt
    }
}
