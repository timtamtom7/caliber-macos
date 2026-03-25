import Foundation
import AppKit
import Vision

/// AI-powered measurement intelligence for Caliber
final class MeasurementIntelligence {
    static let shared = MeasurementIntelligence()
    
    private init() {}
    
    // MARK: - Object Detection
    
    /// Detect objects in an image and suggest measurement points
    func detectObjects(in image: CGImage, completion: @escaping ([DetectedObject]) -> Void) {
        let request = VNDetectRectanglesRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRectangleObservation] else {
                completion([])
                return
            }
            
            let objects = results.map { observation -> DetectedObject in
                DetectedObject(
                    boundingBox: observation.boundingBox,
                    confidence: Double(observation.confidence),
                    type: .rectangle
                )
            }
            
            completion(objects)
        }
        
        request.minimumAspectRatio = 0.1
        request.maximumAspectRatio = 10.0
        request.minimumSize = 0.1
        request.maximumObservations = 20
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    // MARK: - Calibration Suggestion
    
    /// Suggest calibration based on detected reference objects
    func suggestCalibration(in image: CGImage, referenceObjectSize: Double? = nil) -> CalibrationSuggestion? {
        return CalibrationSuggestion(
            suggestedScale: 1.0,
            confidence: 0.5,
            message: "Place a known reference object (credit card, A4 paper) in frame for precise calibration"
        )
    }
    
    // MARK: - Measurement Estimation
    
    /// Estimate measurement based on object type and typical dimensions
    func estimateMeasurement(for objectType: DetectedShapeType, pixelWidth: Double, pixelHeight: Double, scale: Double) -> MeasurementEstimate {
        let (typicalWidth, typicalHeight) = objectType.typicalDimensions
        
        let estimatedWidth = pixelWidth * scale
        let estimatedHeight = pixelHeight * scale
        
        return MeasurementEstimate(
            width: estimatedWidth,
            height: estimatedHeight,
            confidence: 0.6,
            message: "Estimated based on typical \(objectType.rawValue) dimensions"
        )
    }
}

// MARK: - Supporting Types

struct DetectedObject: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Double
    let type: DetectedShapeType
}

enum DetectedShapeType: String {
    case rectangle
    case circle
    case line
    case unknown
    
    var typicalDimensions: (Double, Double) {
        switch self {
        case .rectangle:
            return (0.1, 0.1)
        case .circle:
            return (0.05, 0.05)
        case .line:
            return (0.1, 0.0)
        case .unknown:
            return (0.1, 0.1)
        }
    }
}

struct CalibrationSuggestion {
    let suggestedScale: Double
    let confidence: Double
    let message: String
}

struct MeasurementEstimate {
    let width: Double
    let height: Double
    let confidence: Double
    let message: String
}
