import SwiftUI

struct ContentView: View {

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
                VStack(spacing: 8) {
                    Text("Last Measurement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(last.formattedPx)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                    Text(last.formattedPt)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(last.screenName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            } else {
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

            Divider()

            // Action buttons
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

                if !measurementStore.measurementHistory.isEmpty {
                    ActionButton(title: "Clear History", systemImage: "trash", style: .secondary) {
                        measurementStore.clearHistory()
                    }
                }

                ActionButton(title: "Quit", systemImage: "xmark.circle", style: .destructive) {
                    onQuit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 320, height: 220)
    }
}

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
