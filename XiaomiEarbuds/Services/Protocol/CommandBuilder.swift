import Foundation
import Security

/// Builds RCSP binary command frames for the JieLi protocol.
///
/// Frame format: `[FE DC BA] [flags:1] [opcode:1] [length:2 BE] [payload:N] [EF]`
struct CommandBuilder: Sendable {

    /// Thread-safe sequence number managed via atomic-like pattern.
    /// Each instance has its own counter; shared via the protocol actor.
    private let _sn = LockedValue<UInt8>(0)

    func nextSN() -> UInt8 {
        _sn.withLock { value in
            value &+= 1
            return value
        }
    }

    // MARK: - Raw Frame Encoder

    static func encodeFrame(flags: UInt8, opcode: UInt8, payload: [UInt8]) -> Data {
        var frame: [UInt8] = ProtocolConstants.magic
        frame.append(flags)
        frame.append(opcode)
        let len = UInt16(payload.count)
        frame.append(UInt8(len >> 8))
        frame.append(UInt8(len & 0xFF))
        frame.append(contentsOf: payload)
        frame.append(ProtocolConstants.trailer)
        return Data(frame)
    }

    /// Builds a command frame with auto-incrementing sequence number.
    private func buildCommand(opcode: UInt8, params: [UInt8], app: UInt8) -> (data: Data, sn: UInt8) {
        let sn = nextSN()
        var payload: [UInt8] = [sn]
        payload.append(contentsOf: params)
        let flags: UInt8 = 0x80 | 0x40 | app
        let data = Self.encodeFrame(flags: flags, opcode: opcode, payload: payload)
        return (data, sn)
    }

    // MARK: - Authentication

    func buildAuthCheck(challenge: [UInt8]) -> (data: Data, sn: UInt8) {
        var params: [UInt8] = [0x01]
        params.append(contentsOf: challenge)
        return buildCommand(opcode: ProtocolConstants.opAuthCheck, params: params, app: ProtocolConstants.appMIUI)
    }

    func buildAuthConfirm() -> (data: Data, sn: UInt8) {
        buildCommand(opcode: ProtocolConstants.opAuthConfirm, params: [0x01, 0x00], app: ProtocolConstants.appMIUI)
    }

    /// Builds a response to a device-initiated auth challenge.
    func buildAuthChallengeResponse(deviceSN: UInt8, response: [UInt8]) -> Data {
        var payload: [UInt8] = [0x00, deviceSN, 0x01]
        payload.append(contentsOf: response)
        return Self.encodeFrame(flags: ProtocolConstants.appMIUI, opcode: ProtocolConstants.opAuthCheck, payload: payload)
    }

    // MARK: - Battery / Device Info

    func buildGetBattery() -> (data: Data, sn: UInt8) {
        buildCommand(
            opcode: ProtocolConstants.opGetTargetInfo,
            params: [0xFF, 0xFF, 0xFF, 0xFF],
            app: ProtocolConstants.appEarphone
        )
    }

    func buildGetRunInfo() -> (data: Data, sn: UInt8) {
        buildCommand(
            opcode: ProtocolConstants.opGetRunInfo,
            params: [0xFF, 0xFF, 0xFF, 0xFF],
            app: ProtocolConstants.appEarphone
        )
    }

    // MARK: - Config Get/Set

    /// GET_DEVICE_CONFIG params: a list of `u16 BE` config ids.
    func buildGetConfig(configIDs: [UInt16]) -> (data: Data, sn: UInt8) {
        let params = configIDs.flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] }
        return buildCommand(opcode: ProtocolConstants.opGetDeviceConfig, params: params, app: ProtocolConstants.appEarphone)
    }

    func buildGetConfig(configID: UInt16) -> (data: Data, sn: UInt8) {
        buildGetConfig(configIDs: [configID])
    }

    /// SET_DEVICE_CONFIG params: one TLV `len(u8, = 2 + value) | id(u16 BE) | value`.
    func buildSetConfig(configID: UInt16, data configData: [UInt8]) -> (data: Data, sn: UInt8) {
        var params: [UInt8] = [UInt8(2 + configData.count), UInt8(configID >> 8), UInt8(configID & 0xFF)]
        params.append(contentsOf: configData)
        return buildCommand(opcode: ProtocolConstants.opSetDeviceConfig, params: params, app: ProtocolConstants.appEarphone)
    }

    // MARK: - ANC

    /// Switches the ANC DSP path via SET_TARGET_INFO attribute 4 (`02 04 <mode>`).
    /// A config-11 write alone is stored but never becomes audible.
    func buildSetANCMode(_ mode: ANCMode) -> (data: Data, sn: UInt8) {
        buildCommand(
            opcode: ProtocolConstants.opSetTargetInfo,
            params: [0x02, ProtocolConstants.attrANCMode, mode.wireByte],
            app: ProtocolConstants.appEarphone
        )
    }

    /// Sets the ANC level for the current mode (config 11 = `[mode, level]`).
    func buildSetANCLevel(mode: ANCMode, level: UInt8) -> (data: Data, sn: UInt8) {
        buildSetConfig(configID: ProtocolConstants.configIDANC, data: [mode.wireByte, level])
    }

    // MARK: - Gestures

    /// Rebinds one gesture; `0xFF` leaves that side untouched.
    func buildSetGesture(type: GestureType, left: UInt8?, right: UInt8?) -> (data: Data, sn: UInt8) {
        buildSetConfig(
            configID: ProtocolConstants.configIDGestures,
            data: [type.rawValue, left ?? 0xFF, right ?? 0xFF]
        )
    }

    // MARK: - Find Device

    /// Config 9 `[state, mask]`; mask 1 left, 2 right, 3 both.
    func buildFindDevice(ring: Bool, mask: UInt8 = 0x03) -> (data: Data, sn: UInt8) {
        buildSetConfig(configID: ProtocolConstants.configIDFindDevice, data: [ring ? 0x01 : 0x00, mask])
    }

    // MARK: - Convenience Helpers

    static func randomBytes(_ count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return bytes
    }
}

// MARK: - Thread-safe locked value

/// Minimal lock wrapper for a mutable value, usable from Sendable contexts.
final class LockedValue<T>: @unchecked Sendable {
    private var _value: T
    private let _lock = NSLock()

    init(_ value: T) { _value = value }

    func withLock<R>(_ body: (inout T) -> R) -> R {
        _lock.lock()
        defer { _lock.unlock() }
        return body(&_value)
    }
}
