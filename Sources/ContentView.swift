import SwiftUI

struct ContentView: View {
    @ObservedObject var measurementStore: MeasurementStore
    var onMeasure: () -> Void
    var onQuit: () -> Void
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MeasureTabView(
                measurementStore: measurementStore,
                onMeasure: onMeasure,
                onQuit: onQuit
            )
            .tabItem {
                Label("Measure", systemImage: "ruler")
            }
            .tag(0)

            PresetsTabView(measurementStore: measurementStore)
                .tabItem {
                    Label("Presets", systemImage: "square.grid.2x2")
                }
                .tag(1)

            HistoryTabView(measurementStore: measurementStore)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)

            SettingsTabView(measurementStore: measurementStore)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(width: 360, height: 400)
    }
}

// MARK: - Measure Tab

struct MeasureTabView: View {
    @ObservedObject var measurementStore: MeasurementStore
    var onMeasure: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text("Caliber")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Last measurement display
            if let last = measurementStore.lastMeasurement {
                measurementDisplay(last)
            } else {
                noMeasurementState
            }

            Divider()

            // Action buttons
            actionButtons
        }
    }

    private func measurementDisplay(_ last: Measurement) -> some View {
        VStack(spacing: 8) {
            Text("Last Measurement")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(last.formatted(unit: measurementStore.selectedUnit))
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)

            // Unit picker
            HStack(spacing: 4) {
                ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                    Button(action: { measurementStore.selectedUnit = unit }) {
                        Text(unit.shortName)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(measurementStore.selectedUnit == unit ? Color.accentColor : Color.clear)
                            .foregroundColor(measurementStore.selectedUnit == unit ? .white : .secondary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(last.formattedPt)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)

            Text(last.screenName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var noMeasurementState: some View {
        VStack(spacing: 4) {
            Text("No measurements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Press ⌘⇧M to start")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ActionButton(title: "Measure Again", systemImage: "ruler") {
                    onMeasure()
                }

                if measurementStore.lastMeasurement != nil {
                    ActionButton(title: "Copy", systemImage: "doc.on.doc") {
                        measurementStore.copyLastToClipboard()
                    }
                }
            }

            ActionButton(title: "Quit", systemImage: "xmark.circle", style: .destructive) {
                onQuit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Presets Tab

struct PresetsTabView: View {
    @ObservedObject var measurementStore: MeasurementStore
    @State private var showAddPreset = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Device Presets")
                    .font(.headline)
                Spacer()
                Button(action: { showAddPreset = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(groupedPresets.keys.sorted(), id: \.self) { category in
                        Section {
                            ForEach(groupedPresets[category] ?? []) { preset in
                                presetRow(preset)
                            }
                        } header: {
                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showAddPreset) {
            addPresetSheet
        }
    }

    private var groupedPresets: [String: [MeasurementPreset]] {
        Dictionary(grouping: measurementStore.presets, by: { $0.category })
    }

    private func presetRow(_ preset: MeasurementPreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.system(size: 13, weight: .medium))
                Text("\(preset.widthPt) × \(preset.heightPt) pt")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "ruler")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var addPresetSheet: some View {
        VStack(spacing: 16) {
            Text("New Preset")
                .font(.headline)
            TextField("Preset name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            HStack {
                Button("Cancel") { showAddPreset = false }
                    .buttonStyle(.bordered)
                Button("Add") {
                    let preset = MeasurementPreset(name: newPresetName, widthPt: 800, heightPt: 600)
                    measurementStore.addPreset(preset)
                    newPresetName = ""
                    showAddPreset = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280, height: 160)
    }
}

// MARK: - History Tab

struct HistoryTabView: View {
    @ObservedObject var measurementStore: MeasurementStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Measurement History")
                    .font(.headline)
                Spacer()
                if !measurementStore.measurementHistory.isEmpty {
                    Button("Clear") {
                        measurementStore.clearHistory()
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(12)

            Divider()

            if measurementStore.measurementHistory.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(measurementStore.measurementHistory) { item in
                            historyRow(item)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    private func historyRow(_ item: Measurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.formatted(unit: measurementStore.selectedUnit))
                    .font(.system(size: 13, weight: .medium))
                Text(item.screenName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formattedDate(item.createdAt))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var measurementStore: MeasurementStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // DPI Setting
                VStack(alignment: .leading, spacing: 8) {
                    Text("DISPLAY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.05)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Screen DPI:")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(Int(measurementStore.dpi))")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }

                        Slider(value: $measurementStore.dpi, in: 72...480, step: 1)

                        HStack {
                            Text("72 (iPad)")
                            Spacer()
                            Text("480")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }

                // About
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.05)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Caliber")
                            .font(.system(size: 13, weight: .medium))
                        Text("Screen measurement tool for designers")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let systemImage: String
    var style: ActionButtonStyle = .primary
    let action: () -> Void

    enum ActionButtonStyle {
        case primary, secondary, destructive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.accentColor
        case .secondary:
            return Color(nsColor: .controlBackgroundColor)
        case .destructive:
            return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .red
        }
    }
}
