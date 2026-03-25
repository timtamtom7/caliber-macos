import WidgetKit
import SwiftUI

// MARK: - Measurement Entry

struct MeasurementEntry: TimelineEntry {
    let date: Date
    let measurements: [StoredMeasurement]
    let presets: [StoredPreset]
}

struct StoredMeasurement: Codable, Identifiable {
    let id: UUID
    let width: Double
    let height: Double
    let unit: MeasurementUnit
    let timestamp: Date
    let screenName: String?
    
    var displayString: String {
        "\(Int(width)) × \(Int(height)) \(unit.suffix)"
    }
}

struct StoredPreset: Codable, Identifiable {
    let id: UUID
    let name: String
    let width: Double
    let height: Double
    let unit: MeasurementUnit
}

enum MeasurementUnit: String, Codable {
    case pixels = "px"
    case points = "pt"
    case inches = "in"
    case centimeters = "cm"
    
    var suffix: String { rawValue }
}

// MARK: - Timeline Provider

struct CaliberProvider: TimelineProvider {
    func placeholder(in context: Context) -> MeasurementEntry {
        MeasurementEntry(
            date: Date(),
            measurements: [
                StoredMeasurement(id: UUID(), width: 1920, height: 1080, unit: .pixels, timestamp: Date(), screenName: "Display 1"),
                StoredMeasurement(id: UUID(), width: 1440, height: 900, unit: .pixels, timestamp: Date().addingTimeInterval(-3600), screenName: "Display 2")
            ],
            presets: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MeasurementEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MeasurementEntry>) -> Void) {
        let entry = loadCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> MeasurementEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.caliber.mac")
        
        var measurements: [StoredMeasurement] = []
        var presets: [StoredPreset] = []
        
        if let data = userDefaults?.data(forKey: "recentMeasurements"),
           let decoded = try? JSONDecoder().decode([StoredMeasurement].self, from: data) {
            measurements = decoded
        }
        
        if let presetData = userDefaults?.data(forKey: "presets"),
           let decoded = try? JSONDecoder().decode([StoredPreset].self, from: presetData) {
            presets = decoded
        }
        
        return MeasurementEntry(date: Date(), measurements: measurements, presets: presets)
    }
}

// MARK: - Small Widget View

struct CaliberSmallWidgetView: View {
    var entry: MeasurementEntry

    var body: some View {
        if let measurement = entry.measurements.first {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "ruler")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(measurement.displayString)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("Last measured")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding()
            .widgetURL(URL(string: "caliber://measure")!)
        } else {
            VStack {
                Image(systemName: "ruler")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("No measurements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .widgetURL(URL(string: "caliber://measure")!)
        }
    }
}

// MARK: - Medium Widget View

struct CaliberMediumWidgetView: View {
    var entry: MeasurementEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.accentColor)
                Text("Caliber")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button(intent: OpenAppIntent()) {
                    Text("Measure")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if entry.measurements.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "ruler")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("No measurements yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.measurements.prefix(3)) { measurement in
                    Link(destination: URL(string: "caliber://measurement/\(measurement.id)")!) {
                        HStack {
                            Text(measurement.displayString)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                            if let screenName = measurement.screenName {
                                Text(screenName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget View

struct CaliberLargeWidgetView: View {
    var entry: MeasurementEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.accentColor)
                Text("Caliber")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(intent: OpenAppIntent()) {
                    Label("Measure", systemImage: "plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Divider()
            
            if entry.measurements.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "ruler")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No measurements yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Press ⌘⇧M to measure")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(entry.measurements.prefix(6)) { measurement in
                            Link(destination: URL(string: "caliber://measurement/\(measurement.id)")!) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(measurement.displayString)
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.primary)
                                        if let screenName = measurement.screenName {
                                            Text(screenName)
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(measurement.timestamp, style: .relative)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                
                if !entry.presets.isEmpty {
                    Divider()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(entry.presets.prefix(4)) { preset in
                                Link(destination: URL(string: "caliber://preset/\(preset.id)")!) {
                                    Text(preset.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Widget Bundle

@main
struct CaliberWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaliberSmallWidget()
        CaliberMediumWidget()
        CaliberLargeWidget()
    }
}

struct CaliberSmallWidget: Widget {
    let kind: String = "CaliberSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaliberProvider()) { entry in
            CaliberSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Last Measurement")
        .description("Shows your most recent screen measurement.")
        .supportedFamilies([.systemSmall])
    }
}

struct CaliberMediumWidget: Widget {
    let kind: String = "CaliberMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaliberProvider()) { entry in
            CaliberMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Measurements")
        .description("Shows your recent screen measurements.")
        .supportedFamilies([.systemMedium])
    }
}

struct CaliberLargeWidget: Widget {
    let kind: String = "CaliberLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaliberProvider()) { entry in
            CaliberLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Full History")
        .description("Shows your measurement history with preset shortcuts.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - App Intent

import AppIntents

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Caliber"
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
