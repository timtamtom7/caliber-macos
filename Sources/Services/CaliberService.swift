import Foundation
import Network

// MARK: - Project Service

@MainActor
final class ProjectService: ObservableObject {
    static let shared = ProjectService()

    @Published var projects: [MeasurementProject] = []
    @Published var currentProject: MeasurementProject?

    private let projectsKey = "caliber_projects"

    private init() {
        loadProjects()
    }

    func createProject(name: String, description: String? = nil) -> MeasurementProject {
        let project = MeasurementProject(name: name, description: description)
        projects.append(project)
        saveProjects()
        return project
    }

    func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        if currentProject?.id == id {
            currentProject = nil
        }
        saveProjects()
    }

    func updateProject(_ project: MeasurementProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.updatedAt = Date()
            projects[index] = updated
            saveProjects()
        }
    }

    func exportProjectCSV(_ project: MeasurementProject) -> URL? {
        var csv = "Label,Value,Unit,Date\n"
        for measurement in project.measurements {
            csv += "\(measurement.label ?? ""),\(measurement.value),\(measurement.unit.rawValue),\(formatDate(measurement.timestamp))\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(project.name.replacingOccurrences(of: " ", with: "_")).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    func exportProjectPDF(_ project: MeasurementProject) -> URL? {
        // In production, would generate actual PDF
        // For now, create a placeholder
        let content = """
        Caliber Measurement Report
        =========================

        Project: \(project.name)
        Date: \(formatDate(project.createdAt))

        Measurements:
        \(project.measurements.map { "\($0.label ?? "Unnamed"): \($0.value) \($0.unit.rawValue)" }.joined(separator: "\n"))
        """

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(project.name.replacingOccurrences(of: " ", with: "_")).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let saved = try? JSONDecoder().decode([MeasurementProject].self, from: data) {
            projects = saved
        }
    }
}

// MARK: - Caliber REST API Service

@MainActor
final class CaliberAPIService: ObservableObject {
    static let shared = CaliberAPIService()

    @Published var isRunning = false
    @Published var port: UInt16 = 9877
    @Published var apiKey: String?

    private var listener: NWListener?
    private let keychainKey = "caliber_api_key"

    private init() {
        loadAPIKey()
    }

    func start() throws {
        guard !isRunning else { return }

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.isRunning = (state == .ready)
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.handleConnection(connection)
            }
        }

        listener?.start(queue: DispatchQueue(label: "com.caliber.api.listener"))
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    func generateAPIKey() -> String {
        let key = UUID().uuidString + "-" + UUID().uuidString
        saveAPIKey(key)
        return key
    }

    private func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: keychainKey)
    }

    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: keychainKey)
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data, error == nil else { return }
            Task { @MainActor in
                self?.processRequest(data, connection: connection)
            }
        }
    }

    private func processRequest(_ data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendResponse(status: 400, body: "{\"error\":\"Bad Request\"}", connection: connection)
            return
        }

        let lines = request.split(separator: "\r\n")
        guard let requestLine = lines.first else { return }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return }

        let method = String(parts[0])
        let path = String(parts[1])

        routeRequest(method: method, path: path, connection: connection)
    }

    private func routeRequest(method: String, path: String, connection: NWConnection) {
        var responseBody = "{}"
        var status = 200

        let pathComponents = path.split(separator: "/").map(String.init)

        if pathComponents.first == "measurements" {
            if pathComponents.count == 1 && method == "GET" {
                let projectService = ProjectService.shared
                if let data = try? JSONEncoder().encode(projectService.projects) {
                    responseBody = String(data: data, encoding: .utf8) ?? "[]"
                }
            } else if pathComponents.count >= 2 {
                status = 200
                responseBody = "{\"message\":\"Measurement details\"}"
            }
        } else if path == "/calibrate" && method == "POST" {
            status = 201
            responseBody = "{\"message\":\"Calibration updated\"}"
        } else if path == "/openapi.json" {
            responseBody = getOpenAPISpec()
        } else {
            status = 404
            responseBody = "{\"error\":\"Not found\"}"
        }

        sendResponse(status: status, body: responseBody, connection: connection)
    }

    private func sendResponse(status: Int, body: String, connection: NWConnection) {
        let statusText: String
        switch status {
        case 200: statusText = "OK"
        case 201: statusText = "Created"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        default: statusText = "Unknown"
        }

        let headers = """
        HTTP/1.1 \(status) \(statusText)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r

        """

        let response = headers + body
        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func getOpenAPISpec() -> String {
        return """
        {
          "openapi": "3.0.0",
          "info": {"title": "Caliber API", "version": "1.0.0"},
          "servers": [{"url": "http://localhost:\(port)"}],
          "paths": {
            "/measurements": {
              "get": {"summary": "Get all measurements", "responses": {"200": {}}}
            },
            "/measurements/:id": {
              "get": {"summary": "Get measurement", "responses": {"200": {}}}
            },
            "/calibrate": {
              "post": {"summary": "Update calibration", "responses": {"201": {}}}
            }
          }
        }
        """
    }
}
