import SwiftUI
import AppKit

struct MeasurementHistoryView: View {

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
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }
            .padding()

            Divider()

            if measurementStore.measurementHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "ruler")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No measurements yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(measurementStore.measurementHistory) { measurement in
                        MeasurementRow(measurement: measurement)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 400, height: 300)
    }
}

struct MeasurementRow: View {

    let measurement: Measurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.formattedPx)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Text(measurement.formattedPt)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(measurement.screenName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(measurement.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: copyToClipboard) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(measurement.shortFormat, forType: .string)
    }
}
