import Foundation

struct CameraCalibration: Codable {
    var referenceObject: String
    var knownLength: Double
    var pixelsPerUnit: Double

    static func calibrate(referencePixels: Double, knownLength: Double) -> CameraCalibration {
        CameraCalibration(
            referenceObject: "Reference",
            knownLength: knownLength,
            pixelsPerUnit: referencePixels / knownLength
        )
    }

    func measure(pixels: Double) -> Double {
        pixels / pixelsPerUnit
    }
}

final class CameraRulerManager {
    static let shared = CameraRulerManager()

    private let calibrationKey = "cameraCalibration"

    private init() {}

    func saveCalibration(_ calibration: CameraCalibration) {
        do {
            let data = try JSONEncoder().encode(calibration)
            UserDefaults.standard.set(data, forKey: calibrationKey)
        } catch {
            print("Failed to save calibration: \(error)")
        }
    }

    func loadCalibration() -> CameraCalibration? {
        guard let data = UserDefaults.standard.data(forKey: calibrationKey) else { return nil }
        do {
            return try JSONDecoder().decode(CameraCalibration.self, from: data)
        } catch {
            return nil
        }
    }

    func calibrate(referencePixels: Double, knownLength: Double) -> CameraCalibration {
        let calibration = CameraCalibration.calibrate(referencePixels: referencePixels, knownLength: knownLength)
        saveCalibration(calibration)
        return calibration
    }
}
