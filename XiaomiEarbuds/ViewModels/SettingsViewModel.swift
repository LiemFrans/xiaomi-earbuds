import Foundation
import os.log

@MainActor @Observable
final class SettingsViewModel {
    private(set) var dualConnection: Bool = true
    private(set) var autoAnswer: Bool = false
    var deviceName: String = "REDMI Buds 8 Pro"
    var firmwareVersion: String = "—"
    var isFindingDevice: Bool = false
    var lastError: String?

    private var protocol_: XiaomiProtocol?
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "SettingsVM")

    func configure(protocol proto: XiaomiProtocol) { protocol_ = proto }

    // MARK: - UI Actions

    func toggleDualConnection() {
        dualConnection.toggle()
        let enabled = dualConnection
        send("Dual connection") { try await $0.setBool(configID: ProtocolConstants.configIDDualConnection, enabled) }
    }

    func toggleAutoAnswer() {
        autoAnswer.toggle()
        let enabled = autoAnswer
        send("Auto answer") { try await $0.setBool(configID: ProtocolConstants.configIDAutoAnswer, enabled) }
    }

    func rename(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        deviceName = trimmed
    }

    func startFindingDevice() {
        isFindingDevice = true
        send("Find device") { try await $0.findDevice(play: true) }
    }

    func stopFindingDevice() {
        isFindingDevice = false
        send("Stop find") { try await $0.findDevice(play: false) }
    }

    // MARK: - Device → UI

    func loadFromDevice() async {
        guard let protocol_ else { return }
        do {
            let info = try await protocol_.getDeviceInfo()
            if !info.firmwareVersion.isEmpty { firmwareVersion = info.firmwareVersion }

            let configs = try await protocol_.getConfigs([
                ProtocolConstants.configIDDualConnection,
                ProtocolConstants.configIDAutoAnswer,
            ])
            if let byte = configs[ProtocolConstants.configIDDualConnection]?.first { dualConnection = byte != 0 }
            if let byte = configs[ProtocolConstants.configIDAutoAnswer]?.first { autoAnswer = byte != 0 }
            logger.info("Loaded: fw=\(self.firmwareVersion) dual=\(self.dualConnection) autoAnswer=\(self.autoAnswer)")
        } catch {
            logger.warning("loadFromDevice failed: \(error.localizedDescription)")
        }
    }

    private func send(_ what: String, _ op: @escaping @Sendable (XiaomiProtocol) async throws -> Void) {
        guard let protocol_ else { return }
        Task {
            do { try await op(protocol_); lastError = nil }
            catch { lastError = "\(what): \(error.localizedDescription)"; logger.warning("\(what) failed: \(error.localizedDescription)") }
        }
    }

    static let preview = SettingsViewModel()
}
