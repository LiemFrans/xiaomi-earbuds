import Foundation
import os.log
#if canImport(IOBluetooth)
import IOBluetooth
#endif

/// Manages Classic Bluetooth RFCOMM communication with Xiaomi earbuds
/// over the MIWEAR proprietary service (channel resolved from SDP).
///
/// Receives raw bytes, buffers them, extracts complete RCSP frames,
/// and delivers them via an `AsyncStream<RCSPFrame>`.
/// Uses @MainActor to avoid deadlocks with IOBluetooth delegate callbacks.
@MainActor
final class ClassicBTManager: NSObject {

    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "ClassicBT")

    // MARK: - State

    private(set) var isChannelOpen = false

    /// Whether the earbuds are still connected at the ACL/audio level, even
    /// when our control channel is not open.
    var isDeviceLinkConnected: Bool {
        #if canImport(IOBluetooth)
        return IOBluetoothDevice(addressString: ProtocolConstants.knownDeviceAddress)?.isConnected() ?? false
        #else
        return false
        #endif
    }

    /// True while we deliberately bounce the ACL link to clear a stale
    /// firmware session. Link events during this window are ours, not the user's.
    private(set) var isResettingLink = false

    /// The Bluetooth display name of the connected device (from IOBluetooth, not RCSP).
    var connectedDeviceName: String? {
        #if canImport(IOBluetooth)
        return device?.name
        #else
        return nil
        #endif
    }

    #if canImport(IOBluetooth)
    private var rfcommChannel: IOBluetoothRFCOMMChannel?
    private var device: IOBluetoothDevice?
    private var channelDelegate: RFCOMMChannelDelegate?
    #endif

    /// Raw receive buffer for frame extraction.
    private var rxBuffer: [UInt8] = []

    /// Stream continuation for delivering parsed frames to the protocol layer.
    private var frameStreamContinuation: AsyncStream<RCSPFrame>.Continuation?

    /// Continuation for the one-shot open-channel call.
    private var openContinuation: CheckedContinuation<Void, Error>?

    /// Frames that arrived before a listener attached. The firmware starts
    /// pushing state the instant the channel opens, so they must be replayed
    /// rather than dropped — dropping them loses the auth response.
    private var pendingFrames: [RCSPFrame] = []
    private static let pendingFrameLimit = 128

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - Connection

    func connect(
        address: String = ProtocolConstants.knownDeviceAddress,
        channelID: UInt8 = ProtocolConstants.miwearRFCOMMChannel
    ) throws {
        guard !isChannelOpen else {
            logger.info("RFCOMM channel already open")
            return
        }

        #if canImport(IOBluetooth)
        guard let btDevice = IOBluetoothDevice(addressString: address) else {
            logger.error("IOBluetoothDevice init failed for \(address)")
            throw BluetoothError.deviceNotFound
        }

        device = btDevice
        let delegate = RFCOMMChannelDelegate(manager: self)
        channelDelegate = delegate
        rxBuffer = []
        pendingFrames.removeAll()

        // The MIWEAR channel number can move between sessions, so resolve it
        // from the SDP record by UUID and fall back to the configured default.
        let resolvedChannel = Self.miwearChannel(for: btDevice) ?? channelID
        if resolvedChannel != channelID {
            logger.info("SDP reports MIWEAR on channel \(resolvedChannel) (config had \(channelID))")
        }

        // RFCOMM needs the ACL link. macOS sometimes keeps the device paired but
        // drops the link, and every channel open then fails with "not permitted".
        if !btDevice.isConnected() {
            logger.info("ACL link is down — bringing it up before opening RFCOMM…")
            _ = btDevice.openConnection()
            pumpRunLoop(3.0)
        }

        logger.info("Opening RFCOMM channel \(resolvedChannel) to \(address)…")
        logger.debug("Device paired: \(btDevice.isPaired()), connected: \(btDevice.isConnected())")

        var channel: IOBluetoothRFCOMMChannel?
        var result = btDevice.openRFCOMMChannelSync(
            &channel,
            withChannelID: resolvedChannel,
            delegate: delegate
        )

        // Firmware keeps the old control session for a while after an abrupt
        // close. Tearing the ACL link down once clears it; macOS reconnects
        // audio automatically.
        if result != kIOReturnSuccess {
            logger.warning("First RFCOMM open failed (\(result)) — resetting ACL link and retrying")
            isResettingLink = true
            defer { isResettingLink = false }
            _ = btDevice.closeConnection()
            pumpRunLoop(1.0)
            _ = btDevice.openConnection()
            pumpRunLoop(1.5)

            let retryChannel = Self.miwearChannel(for: btDevice) ?? resolvedChannel
            result = btDevice.openRFCOMMChannelSync(
                &channel,
                withChannelID: retryChannel,
                delegate: delegate
            )
            if result == kIOReturnSuccess {
                logger.info("✅ RFCOMM opened after ACL reset (channel \(retryChannel))")
            }
        }

        if result != kIOReturnSuccess {
            logger.error("openRFCOMMChannelSync failed: IOReturn=\(result) (0x\(String(format: "%08x", UInt32(bitPattern: Int32(result)))))")
            logger.error("Device state — paired: \(btDevice.isPaired()), connected: \(btDevice.isConnected()), name: \(btDevice.name ?? "nil")")

            // Any refusal here means another host (phone) owns the control
            // channel, or the earbuds are asleep. Both are fixed on the phone
            // side — keep a long cooldown rather than hammering the device.
            //   -536870186 kIOReturnExclusiveAccess
            //   -536870212 kIOReturnNotPermitted
            let exclusiveAccess = -536870186
            let notPermitted = -536870212
            if result == exclusiveAccess || result == notPermitted {
                throw BluetoothError.rfcommBusy
            }
            throw BluetoothError.rfcommChannelFailed
        }

        self.rfcommChannel = channel
        self.isChannelOpen = true
        logger.info("✅ RFCOMM channel \(channelID) opened successfully (MTU: \(channel?.getMTU() ?? 0))")

        #else
        throw BluetoothError.rfcommChannelFailed
        #endif
    }



    /// Waits without blocking IOBluetooth's delegate delivery, which needs the
    /// main run loop to keep turning while we sit inside a synchronous call.
    private func pumpRunLoop(_ seconds: TimeInterval) {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
    }

    /// Resolves the MIWEAR RFCOMM channel from the device's SDP records.
    private static func miwearChannel(for device: IOBluetoothDevice) -> UInt8? {
        let target = ProtocolConstants.miwearServiceUUID.lowercased()
        guard let services = device.services as? [IOBluetoothSDPServiceRecord] else {
            _ = device.performSDPQuery(nil)
            return nil
        }
        for service in services {
            let uuid = (service.attributes as? [NSNumber: Any])?[0x0001 as NSNumber]
            let uuidText = uuid.map { "\($0)" }?.lowercased() ?? ""
            let isMiwear = uuidText.contains("fd2d") || uuidText == target
            var channel: BluetoothRFCOMMChannelID = 0
            if isMiwear, service.getRFCOMMChannelID(&channel) == kIOReturnSuccess {
                return channel
            }
        }
        return nil
    }

    func disconnect() {
        logger.info("Disconnecting RFCOMM…")
        #if canImport(IOBluetooth)
        if let channel = rfcommChannel {
            logger.debug("Closing RFCOMM channel object")
            channel.close()
        }
        rfcommChannel = nil
        // Do NOT call device?.closeConnection() — that kills the audio BT link too
        device = nil
        channelDelegate = nil
        #endif
        isChannelOpen = false
        rxBuffer = []
        frameStreamContinuation?.finish()
        frameStreamContinuation = nil
        logger.info("RFCOMM disconnected, buffers cleared")
    }

    // MARK: - Data Transfer

    /// Serialises RFCOMM writes off the main thread. `writeSync` blocks while
    /// the earbuds' receive buffer is full — on the main actor that also stalls
    /// IOBluetooth's delegate delivery, so the responses we are waiting for can
    /// never be parsed.
    private static let writeQueue = DispatchQueue(label: "com.xiaomi.earbuds.rfcomm.write")

    func sendData(_ data: Data) async throws {
        #if canImport(IOBluetooth)
        guard let channel = rfcommChannel, isChannelOpen else {
            logger.error("TX failed — channel not open (isChannelOpen=\(self.isChannelOpen), channel=\(self.rfcommChannel == nil ? "nil" : "exists"))")
            throw BluetoothError.notConnected
        }

        let hex = data.map { String(format: "%02x", $0) }.joined(separator: " ")
        logger.debug("TX [\(data.count) bytes]: \(hex)")

        let result: IOReturn = await withCheckedContinuation { continuation in
            Self.writeQueue.async {
                var mutableBytes = Array(data)
                let status = channel.writeSync(&mutableBytes, length: UInt16(mutableBytes.count))
                continuation.resume(returning: status)
            }
        }

        guard result == kIOReturnSuccess else {
            logger.error("TX writeSync failed: IOReturn=\(result)")
            throw BluetoothError.writeError(underlying: "RFCOMM writeSync failed: \(result)")
        }
        logger.debug("TX complete ✓")
        #else
        throw BluetoothError.notConnected
        #endif
    }

    // MARK: - Frame Stream

    /// Returns an `AsyncStream` of parsed RCSP frames received over RFCOMM.
    /// Must be called BEFORE any data arrives — typically right after connect().
    func frameStream() -> AsyncStream<RCSPFrame> {
        // If there's already a stream, finish the old one
        frameStreamContinuation?.finish()

        let buffered = pendingFrames
        pendingFrames.removeAll()

        return AsyncStream<RCSPFrame>(bufferingPolicy: .bufferingNewest(64)) { continuation in
            self.frameStreamContinuation = continuation
            for frame in buffered {
                continuation.yield(frame)
            }
            continuation.onTermination = { @Sendable _ in }
        }
    }

    // MARK: - Internal Callbacks

    func handleDataReceived(_ data: Data) {
        let bytes = Array(data)
        let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
        logger.debug("RX raw [\(bytes.count) bytes]: \(hex)")
        rxBuffer.append(contentsOf: bytes)
        logger.debug("RX buffer now \(self.rxBuffer.count) bytes")

        var frameCount = 0
        while let frame = ResponseParser.extractFrame(from: &rxBuffer) {
            frameCount += 1
            let payloadHex = frame.payload.map { String(format: "%02x", $0) }.joined(separator: " ")
            logger.info("RX frame #\(frameCount) [\(frame.isCommand ? "CMD" : "RSP") op=0x\(String(format: "%02x", frame.opcode)) flags=0x\(String(format: "%02x", frame.flags)) payload=\(payloadHex)]")

            if let cont = frameStreamContinuation {
                cont.yield(frame)
                logger.debug("Frame yielded to stream ✓")
            } else {
                // No listener yet — keep it so the first request can still match.
                pendingFrames.append(frame)
                if pendingFrames.count > Self.pendingFrameLimit {
                    pendingFrames.removeFirst()
                }
                logger.debug("Frame buffered until a listener attaches (op=0x\(String(format: "%02x", frame.opcode)))")
            }
        }

        if frameCount == 0 && rxBuffer.count > 0 {
            logger.debug("No complete frames yet, \(self.rxBuffer.count) bytes buffered")
        }
    }

    func handleChannelClosed() {
        logger.warning("⚠️ RFCOMM channel closed by remote — isChannelOpen was \(self.isChannelOpen)")
        isChannelOpen = false
        frameStreamContinuation?.finish()
        frameStreamContinuation = nil
    }
}

// MARK: - RFCOMM Channel Delegate

#if canImport(IOBluetooth)
private final class RFCOMMChannelDelegate: NSObject, IOBluetoothRFCOMMChannelDelegate, @unchecked Sendable {
    private let _manager: ClassicBTManager

    init(manager: ClassicBTManager) {
        _manager = manager
    }

    func rfcommChannelData(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!,
        data dataPointer: UnsafeMutableRawPointer!,
        length dataLength: Int
    ) {
        guard let pointer = dataPointer else { return }
        let data = Data(bytes: pointer, count: dataLength)
        let manager = _manager
        Task { @MainActor in manager.handleDataReceived(data) }
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        let manager = _manager
        Task { @MainActor in manager.handleChannelClosed() }
    }
}
#endif
