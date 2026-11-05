import Foundation
import os.log

@MainActor @Observable
final class AudioViewModel {
    var absoluteVolume: Bool = true
    private(set) var adaptiveSound: Bool = false
    var codec: AudioCodec = .aac
    var sampleRate: SampleRate = .khz48_0
    private(set) var soundMode: SoundMode = .balanced
    private(set) var lowLatency: Bool = false
    var lastError: String?

    private var protocol_: XiaomiProtocol?
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "AudioVM")

    func configure(protocol proto: XiaomiProtocol) { protocol_ = proto }

    // MARK: - UI Actions

    func selectSoundMode(_ mode: SoundMode) {
        guard mode != soundMode else { return }
        soundMode = mode
        send("Sound mode") { try await $0.setSoundMode(mode) }
    }

    func toggleAdaptiveSound() {
        adaptiveSound.toggle()
        let enabled = adaptiveSound
        send("Adaptive sound") { try await $0.setBool(configID: ProtocolConstants.configIDAdaptiveSound, enabled) }
    }

    func toggleLowLatency() {
        lowLatency.toggle()
        let enabled = lowLatency
        send("Low latency") { try await $0.setBool(configID: ProtocolConstants.configIDLowLatency, enabled) }
    }

    // MARK: - Device → UI

    func loadFromDevice() async {
        guard let protocol_ else { return }
        do {
            let configs = try await protocol_.getConfigs([
                ProtocolConstants.configIDEQPreset,
                ProtocolConstants.configIDAdaptiveSound,
                ProtocolConstants.configIDLowLatency,
            ])
            if let byte = configs[ProtocolConstants.configIDEQPreset]?.first, let mode = SoundMode(wireByte: byte) {
                soundMode = mode
            }
            if let byte = configs[ProtocolConstants.configIDAdaptiveSound]?.first { adaptiveSound = byte != 0 }
            if let byte = configs[ProtocolConstants.configIDLowLatency]?.first { lowLatency = byte != 0 }
            logger.info("Loaded audio: EQ=\(self.soundMode.displayName) adaptive=\(self.adaptiveSound) lowLatency=\(self.lowLatency)")
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

    static let preview: AudioViewModel = {
        let vm = AudioViewModel()
        return vm
    }()
}
