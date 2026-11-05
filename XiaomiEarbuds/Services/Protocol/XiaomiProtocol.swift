import Foundation
@preconcurrency import Combine
import os.log

/// Unsolicited state pushed by the earbuds (REPORT_STATUS / NOTIFY_DEVICE_CONFIG).
enum ProtocolEvent: Sendable {
    case battery(BatteryInfo)
    case anc(mode: ANCMode, level: UInt8)
    case config(id: UInt16, value: [UInt8])
}

/// High-level RCSP protocol service for REDMI Buds 8 Pro.
///
/// Uses `ClassicBTManager` for RFCOMM transport over the MIWEAR channel (ch.28).
/// Requests are serialized and matched to responses by sequence number + opcode.
actor XiaomiProtocol {

    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "Protocol")

    // MARK: - Dependencies

    private let classicManager: ClassicBTManager
    let commandBuilder = CommandBuilder()

    private struct Pending {
        let opcode: UInt8
        let continuation: CheckedContinuation<RCSPFrame, Error>
    }

    private var pendingResponses: [UInt8: Pending] = [:]
    private var listenTask: Task<Void, Never>?
    private var queueTail: Task<Void, Never>?

    /// Unsolicited events from the earbuds.
    nonisolated let events = PassthroughSubject<ProtocolEvent, Never>()

    /// Fires when the RFCOMM frame stream ends (channel closed).
    nonisolated let disconnectedSubject = PassthroughSubject<Void, Never>()

    // MARK: - Init

    init(classicManager: ClassicBTManager) {
        self.classicManager = classicManager
    }

    // MARK: - Listening

    func startListening() async {
        logger.info("📡 Starting frame listener…")
        let stream = await MainActor.run { classicManager.frameStream() }
        listenTask = Task { [weak self] in
            var count = 0
            for await frame in stream {
                count += 1
                await self?.dispatchFrame(frame)
            }
            self?.logger.warning("📡 Frame stream ended after \(count) frames")
            await self?.failAllPending(BluetoothError.notConnected)
            self?.disconnectedSubject.send()
        }
    }

    func stopListening() {
        logger.info("📡 Stopping frame listener (pending: \(self.pendingResponses.count))")
        listenTask?.cancel()
        listenTask = nil
        failAllPending(BluetoothError.notConnected)
    }

    private func failAllPending(_ error: Error) {
        for (_, pending) in pendingResponses {
            pending.continuation.resume(throwing: error)
        }
        pendingResponses.removeAll()
    }

    // MARK: - Authentication

    func authenticate() async throws {
        logger.info("🔐 Starting RCSP authentication…")

        let challenge = CommandBuilder.randomBytes(16)
        let expected = RCSPCrypto.authTransform(
            addr6: ProtocolConstants.authPlaceholderAddr,
            challenge: challenge
        )

        let rsp = try await request(commandBuilder.buildAuthCheck(challenge: challenge), opcode: ProtocolConstants.opAuthCheck)
        let data = rsp.data
        guard data.count >= 17 else {
            logger.error("🔐 AUTH_CHECK response too short: \(data.count) bytes")
            throw BluetoothError.invalidResponse
        }
        guard Array(data[1..<17]) == expected else {
            logger.error("🔐 Auth challenge mismatch")
            throw BluetoothError.connectionFailed(underlying: "Auth challenge mismatch")
        }
        logger.info("🔐 Challenge verified ✅")

        _ = try await request(commandBuilder.buildAuthConfirm(), opcode: ProtocolConstants.opAuthConfirm)
        logger.info("🔐 ✅ Authentication complete!")
    }

    // MARK: - Device Info / Battery

    func getDeviceInfo() async throws -> ResponseParser.DeviceInfo {
        let rsp = try await request(commandBuilder.buildGetBattery(), opcode: ProtocolConstants.opGetTargetInfo)
        let info = ResponseParser.parseDeviceInfo(data: rsp.data)
        logger.info("ℹ️ Device info: name=\(info.name), fw=\(info.firmwareVersion)")
        return info
    }

    func getBatteryLevels() async throws -> BatteryInfo {
        guard let battery = try await getDeviceInfo().battery else {
            throw BluetoothError.invalidResponse
        }
        return battery
    }

    func getFirmwareVersion() async throws -> String {
        let fw = try await getDeviceInfo().firmwareVersion
        return fw.isEmpty ? "Unknown" : fw
    }

    // MARK: - ANC

    /// Switches the audible ANC mode (SET_TARGET_INFO attribute 4).
    func setANCMode(_ mode: ANCMode) async throws {
        logger.info("🔇 Set ANC mode → \(mode.displayName)")
        markWritten(ProtocolConstants.configIDANC)
        _ = try await request(commandBuilder.buildSetANCMode(mode), opcode: ProtocolConstants.opSetTargetInfo)
    }

    /// Sets the ANC level for `mode` (0 = deepest … `ancLevelMax` = lightest).
    func setANCLevel(mode: ANCMode, level: UInt8) async throws {
        logger.info("🔇 Set ANC level → mode=\(mode.displayName) level=\(level)")
        markWritten(ProtocolConstants.configIDANC)
        _ = try await request(commandBuilder.buildSetANCLevel(mode: mode, level: level), opcode: ProtocolConstants.opSetDeviceConfig)
    }

    func getANCState() async throws -> (mode: ANCMode, level: UInt8)? {
        guard let value = try await getConfig(configID: ProtocolConstants.configIDANC) else { return nil }
        return ResponseParser.parseANC(value)
    }

    // MARK: - Device Config (generic)

    /// Reads several config ids at once. Ids the firmware ignores are absent.
    func getConfigs(_ ids: [UInt16]) async throws -> [UInt16: [UInt8]] {
        let rsp = try await request(commandBuilder.buildGetConfig(configIDs: ids), opcode: ProtocolConstants.opGetDeviceConfig)
        return ResponseParser.parseTLVsU16(rsp.data)
    }

    func getConfig(configID: UInt16) async throws -> [UInt8]? {
        try await getConfigs([configID])[configID]
    }

    func setConfig(configID: UInt16, data configData: [UInt8]) async throws {
        logger.info("✏️ Set config \(configID) = \(configData.map { String(format: "%02x", $0) }.joined(separator: " "))")
        markWritten(configID)
        _ = try await request(commandBuilder.buildSetConfig(configID: configID, data: configData), opcode: ProtocolConstants.opSetDeviceConfig)
    }

    func setBool(configID: UInt16, _ enabled: Bool) async throws {
        try await setConfig(configID: configID, data: [enabled ? 0x01 : 0x00])
    }

    // MARK: - Features

    func setSoundMode(_ mode: SoundMode) async throws {
        try await setConfig(configID: ProtocolConstants.configIDEQPreset, data: [mode.wireByte])
    }

    func getGestures() async throws -> [GestureType: GestureBinding] {
        guard let value = try await getConfig(configID: ProtocolConstants.configIDGestures) else { return [:] }
        return ResponseParser.parseGestures(value)
    }

    /// Rebinds one side of one gesture; the other side is left untouched.
    func setGesture(type: GestureType, side: EarbudSide, action: GestureAction) async throws {
        let byte = action.wireByte(for: type)
        let cmd = commandBuilder.buildSetGesture(
            type: type,
            left: side == .left ? byte : nil,
            right: side == .right ? byte : nil
        )
        logger.info("👆 Set gesture \(type.displayName) \(side == .left ? "L" : "R") → \(action.displayName)")
        _ = try await request(cmd, opcode: ProtocolConstants.opSetDeviceConfig)
    }

    func findDevice(play: Bool = true) async throws {
        logger.info("🔔 Find device → \(play ? "ring" : "stop")")
        _ = try await request(commandBuilder.buildFindDevice(ring: play), opcode: ProtocolConstants.opSetDeviceConfig)
    }

    // MARK: - Transport

    /// Serializes requests (the firmware handles one at a time) and checks status.
    private func request(_ command: (data: Data, sn: UInt8), opcode: UInt8) async throws -> RCSPFrame {
        let previous = queueTail
        let task = Task { [weak self] () throws -> RCSPFrame in
            await previous?.value
            guard let self else { throw BluetoothError.notConnected }
            return try await self.sendAndWait(data: command.data, sn: command.sn, opcode: opcode)
        }
        queueTail = Task { _ = try? await task.value }

        let rsp = try await task.value
        guard rsp.status == 0 else {
            logger.error("❌ op=0x\(String(format: "%02x", opcode)) SN=\(command.sn) failed: \(Self.statusName(rsp.status))")
            throw BluetoothError.connectionFailed(underlying: "Earbuds rejected command (\(Self.statusName(rsp.status)))")
        }
        return rsp
    }

    private func sendAndWait(data: Data, sn: UInt8, opcode: UInt8) async throws -> RCSPFrame {
        try await withCheckedThrowingContinuation { continuation in
            // Register before sending so a fast response can't be dispatched first.
            pendingResponses[sn] = Pending(opcode: opcode, continuation: continuation)
            logger.debug("⬆️ SN=\(sn) op=0x\(String(format: "%02x", opcode)) sending \(data.count) bytes")

            Task { [weak self] in
                guard let self else { return }
                do {
                    try await MainActor.run { try self.classicManager.sendData(data) }
                } catch {
                    await self.resolve(sn: sn, with: .failure(error))
                    return
                }
                try? await Task.sleep(for: .seconds(ProtocolConstants.commandTimeout))
                await self.resolve(sn: sn, with: .failure(BluetoothError.timeout))
            }
        }
    }

    private func resolve(sn: UInt8, with result: Result<RCSPFrame, Error>) {
        guard let pending = pendingResponses.removeValue(forKey: sn) else { return }
        if case .failure(let error) = result {
            logger.error("⏰ SN=\(sn) op=0x\(String(format: "%02x", pending.opcode)) failed: \(error.localizedDescription)")
        }
        pending.continuation.resume(with: result)
    }

    // MARK: - Frame Dispatch

    private func dispatchFrame(_ frame: RCSPFrame) {
        let op = String(format: "%02x", frame.opcode)
        let payloadHex = frame.payload.prefix(24).map { String(format: "%02x", $0) }.joined(separator: " ")
        logger.debug("⬇️ \(frame.isCommand ? "CMD" : "RSP") op=0x\(op) payload=\(payloadHex)")

        guard frame.isCommand else {
            // Responses carry `status | sn`; buds-initiated commands must never match here.
            if let pending = pendingResponses[frame.sn], pending.opcode == frame.opcode {
                resolve(sn: frame.sn, with: .success(frame))
            } else {
                logger.debug("⬇️ Unmatched response op=0x\(op) sn=\(frame.sn)")
            }
            return
        }

        switch frame.opcode {
        case ProtocolConstants.opAuthCheck:
            answerDeviceChallenge(frame)
        case ProtocolConstants.opAuthConfirm:
            reply(to: frame, data: [0x01])
        case ProtocolConstants.opReportStatus:
            handleReportStatus(frame.data)
        case ProtocolConstants.opNotifyConfig:
            handleNotifyConfig(frame.data)
        default:
            logger.debug("⬇️ Ignoring buds command op=0x\(op)")
        }
    }

    private func handleReportStatus(_ data: [UInt8]) {
        for (type, value) in ResponseParser.parseTLVsU8(data) {
            switch type {
            case 0x00 where value.count >= 3:
                events.send(.battery(ResponseParser.parseBattery(value)))
            case ProtocolConstants.attrANCMode:
                // Suppress ANC echo if we recently sent an ANC command
                if isRecentWrite(ProtocolConstants.configIDANC) {
                    logger.debug("🔔 Suppressing REPORT_STATUS ANC echo (recent write)")
                } else if let anc = ResponseParser.parseANC(value) {
                    events.send(.anc(mode: anc.mode, level: anc.level))
                }
            default:
                break
            }
        }
    }

    /// Config ids we recently wrote to. NOTIFY_CONFIG echoes within 3 seconds
    /// are suppressed to prevent the UI from reverting to the pre-switch state.
    private var recentWrites: [UInt16: ContinuousClock.Instant] = [:]

    /// Marks a config id as just-written so its NOTIFY echo is suppressed.
    private func markWritten(_ ids: UInt16...) {
        let now = ContinuousClock.now
        for id in ids { recentWrites[id] = now }
    }

    private func isRecentWrite(_ id: UInt16) -> Bool {
        guard let ts = recentWrites[id] else { return false }
        if ContinuousClock.now - ts < .seconds(3) { return true }
        recentWrites.removeValue(forKey: id)
        return false
    }

    private func handleNotifyConfig(_ data: [UInt8]) {
        for (id, value) in ResponseParser.parseTLVsU16(data) {
            let hex = value.map { String(format: "%02x", $0) }.joined(separator: " ")

            // Suppress echoes of our own writes to prevent UI flicker
            if isRecentWrite(id) {
                logger.debug("🔔 Suppressing config \(id) echo (recent write): \(hex)")
                continue
            }

            logger.info("🔔 Config \(id) changed on device: \(hex)")

            if id == ProtocolConstants.configIDANC, let anc = ResponseParser.parseANC(value) {
                events.send(.anc(mode: anc.mode, level: anc.level))
            } else {
                events.send(.config(id: id, value: value))
            }
        }
    }

    // MARK: - Replies to buds-initiated commands

    private func reply(to frame: RCSPFrame, data: [UInt8]) {
        let payload = [0x00, frame.sn] + data
        let reply = CommandBuilder.encodeFrame(flags: frame.targetApp, opcode: frame.opcode, payload: payload)
        send(reply, label: "reply op=0x\(String(format: "%02x", frame.opcode))")
    }

    private func answerDeviceChallenge(_ frame: RCSPFrame) {
        let data = frame.data
        guard data.count >= 17, data[0] == 0x01 else { return }
        let response = RCSPCrypto.authTransform(
            addr6: ProtocolConstants.authPlaceholderAddr,
            challenge: Array(data[1..<17])
        )
        send(commandBuilder.buildAuthChallengeResponse(deviceSN: frame.sn, response: response), label: "device auth challenge answer")
    }

    private func send(_ data: Data, label: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await MainActor.run { try self.classicManager.sendData(data) }
                self.logger.debug("↩️ Sent \(label)")
            } catch {
                self.logger.error("Failed to send \(label): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    static func statusName(_ status: UInt8) -> String {
        switch status {
        case 0: "ok"
        case 1: "fail"
        case 2: "unknown command"
        case 3: "busy"
        case 4: "no resource"
        case 5: "crc"
        case 7: "param error"
        case 9: "not supported"
        default: "status \(status)"
        }
    }
}
