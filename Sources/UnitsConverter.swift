import Foundation

struct UnitConverter {
    enum Category: String, CaseIterable {
        case length = "Length"
        case weight = "Weight"
        case temperature = "Temperature"
        case volume = "Volume"
    }

    static func convert(value: Double, from: UnitType, to: UnitType) -> Double {
        guard from.category == to.category else { return 0 }

        switch from.category {
        case .length:
            return convertLength(value: value, from: from, to: to)
        case .weight:
            return convertWeight(value: value, from: from, to: to)
        case .temperature:
            return convertTemperature(value: value, from: from, to: to)
        case .volume:
            return convertVolume(value: value, from: from, to: to)
        }
    }

    private static func convertLength(value: Double, from: UnitType, to: UnitType) -> Double {
        let mm = value * from.toMm
        return mm / to.toMm
    }

    private static func convertWeight(value: Double, from: UnitType, to: UnitType) -> Double {
        let g = value * from.toGrams
        return g / to.toGrams
    }

    private static func convertTemperature(value: Double, from: UnitType, to: UnitType) -> Double {
        var celsius: Double
        switch from {
        case .celsius: celsius = value
        case .fahrenheit: celsius = (value - 32) * 5/9
        case .kelvin: celsius = value - 273.15
        default: celsius = value
        }

        switch to {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9/5 + 32
        case .kelvin: return celsius + 273.15
        default: return celsius
        }
    }

    private static func convertVolume(value: Double, from: UnitType, to: UnitType) -> Double {
        let ml = value * from.toMl
        return ml / to.toMl
    }
}

enum UnitType: String, CaseIterable {
    // Length (in mm)
    case millimeter, centimeter, meter, inch, foot, yard, mile

    // Weight (in grams)
    case milligram, gram, kilogram, ounce, pound

    // Temperature
    case celsius, fahrenheit, kelvin

    // Volume (in ml)
    case milliliter, liter, fluidOunce, gallon

    var category: UnitConverter.Category {
        switch self {
        case .millimeter, .centimeter, .meter, .inch, .foot, .yard, .mile:
            return .length
        case .milligram, .gram, .kilogram, .ounce, .pound:
            return .weight
        case .celsius, .fahrenheit, .kelvin:
            return .temperature
        case .milliliter, .liter, .fluidOunce, .gallon:
            return .volume
        }
    }

    var toMm: Double {
        switch self {
        case .millimeter: return 1
        case .centimeter: return 10
        case .meter: return 1000
        case .inch: return 25.4
        case .foot: return 304.8
        case .yard: return 914.4
        case .mile: return 1609344
        default: return 1
        }
    }

    var toGrams: Double {
        switch self {
        case .milligram: return 0.001
        case .gram: return 1
        case .kilogram: return 1000
        case .ounce: return 28.3495
        case .pound: return 453.592
        default: return 1
        }
    }

    var toMl: Double {
        switch self {
        case .milliliter: return 1
        case .liter: return 1000
        case .fluidOunce: return 29.5735
        case .gallon: return 3785.41
        default: return 1
        }
    }
}
