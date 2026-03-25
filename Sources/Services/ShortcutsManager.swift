import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct CaliberShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLastMeasurementIntent(),
            phrases: [
                "Get last \(.applicationName) measurement",
                "What was the last measurement in \(.applicationName)"
            ],
            shortTitle: "Last Measurement",
            systemImageName: "ruler"
        )

        AppShortcut(
            intent: StartMeasuringIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Measure with \(.applicationName)"
            ],
            shortTitle: "Start Measuring",
            systemImageName: "plus.magnifyingglass"
        )
    }
}

// MARK: - Get Last Measurement Intent

struct GetLastMeasurementIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Last Measurement"
    static var description = IntentDescription("Returns the most recent measurement from Caliber")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let measurement = await CaliberState.shared.store?.lastMeasurement

        guard let m = measurement else {
            return .result(dialog: "No measurements yet. Start Caliber to measure.")
        }

        return .result(dialog: "Last: \(m.formattedPx). Screen: \(m.screenName). At \(m.createdAt.formatted(date: .omitted, time: .shortened))")
    }
}

// MARK: - Start Measuring Intent

struct StartMeasuringIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Measuring"
    static var description = IntentDescription("Starts a new measurement in Caliber")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await CaliberState.shared.store?.startMeasuring()
        return .result(dialog: "Caliber measuring mode started")
    }
}
