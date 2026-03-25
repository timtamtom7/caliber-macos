import Foundation

@MainActor
final class CaliberSyncManager: ObservableObject {
    static let shared = CaliberSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var presets: [MeasurementPreset]
        var selectedUnit: String
        var dpi: Double
        var settings: CaliberSettings

        struct CaliberSettings: Codable {
            var autoStart: Bool
            var showOverlay: Bool
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "caliber.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "caliber.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let store = CaliberState.shared.store!

        let settings = SyncPayload.CaliberSettings(
            autoStart: UserDefaults.standard.bool(forKey: "caliber_autoStart"),
            showOverlay: UserDefaults.standard.bool(forKey: "caliber_showOverlay")
        )

        return SyncPayload(
            presets: store.presets,
            selectedUnit: store.selectedUnit.rawValue,
            dpi: store.dpi,
            settings: settings
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        let store = CaliberState.shared.store!

        store.presets = payload.presets
        if let unit = MeasurementUnit(rawValue: payload.selectedUnit) {
            store.selectedUnit = unit
        }
        store.dpi = payload.dpi

        UserDefaults.standard.set(payload.settings.autoStart, forKey: "caliber_autoStart")
        UserDefaults.standard.set(payload.settings.showOverlay, forKey: "caliber_showOverlay")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
