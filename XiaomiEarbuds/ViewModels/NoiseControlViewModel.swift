import Foundation
import os.log

@MainActor @Observable
final class NoiseControlViewModel {
    private(set) var ancMode: ANCMode = .off
    private(set) var smartANC: Bool = false
    var ancDepth: Double = 0.5
    var immersiveCommute: Bool = false
    var lastError: String?

    private var protocol_: XiaomiProtocol?
    private var isSyncing = false
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "NoiseControlVM")

    func configure(protocol proto: XiaomiProtocol) { protocol_ = proto }

    // MARK: - UI Actions

    func selectANCMode(_ mode: ANCMode) {
        guard mode != ancMode else { return }
        ancMode = mode
        send("ANC mode") { try await $0.setANCMode(mode) }
    }

    func toggleSmartANC() {
        smartANC.toggle()
        let enabled = smartANC
        send("Smart ANC") { try await $0.setBool(configID: ProtocolConstants.configIDAdaptiveANC, enabled) }
    }

    func commitDepth() {
        guard ancMode == .noiseCancellation else { return }
        let level = Self.level(fromDepth: ancDepth)
        let mode = ancMode
        send("ANC depth") { try await $0.setANCLevel(mode: mode, level: level) }
    }

    // MARK: - Device → UI

    func loadFromDevice() async {
        guard let protocol_ else { return }
        do {
            let configs = try await protocol_.getConfigs([
                ProtocolConstants.configIDANC,
                ProtocolConstants.configIDAdaptiveANC,
            ])
            if let value = configs[ProtocolConstants.configIDANC],
               let anc = ResponseParser.parseANC(value) {
                ancMode = anc.mode
                ancDepth = Self.depth(fromLevel: anc.level)
            }
            if let byte = configs[ProtocolConstants.configIDAdaptiveANC]?.first {
                smartANC = byte != 0
            }
            logger.info("Loaded ANC: mode=\(self.ancMode.displayName) smart=\(self.smartANC)")
        } catch {
            logger.warning("loadFromDevice failed: \(error.localizedDescription)")
        }
    }

    func applyDeviceANC(mode: ANCMode, level: UInt8) {
        ancMode = mode
        if mode == .noiseCancellation { ancDepth = Self.depth(fromLevel: level) }
    }

    // MARK: - Helpers

    private func send(_ what: String, _ op: @escaping @Sendable (XiaomiProtocol) async throws -> Void) {
        guard let protocol_ else { return }
        Task {
            do { try await op(protocol_); lastError = nil }
            catch { lastError = "\(what): \(error.localizedDescription)"; logger.warning("\(what) failed: \(error.localizedDescription)") }
        }
    }

    static func level(fromDepth depth: Double) -> UInt8 {
        let max = Double(ProtocolConstants.ancLevelMax)
        return UInt8((max - (min(1, Swift.max(0, depth)) * max)).rounded())
    }

    static func depth(fromLevel level: UInt8) -> Double {
        1 - min(Double(level), Double(ProtocolConstants.ancLevelMax)) / Double(ProtocolConstants.ancLevelMax)
    }

    static let preview = NoiseControlViewModel()
}
