import Foundation
import os.log
#if canImport(IOBluetooth)
import IOBluetooth
#endif

/// Manages Classic Bluetooth RFCOMM communication with the REDMI Buds 8 Pro
/// over the MIWEAR proprietary service (channel 28).
///
/// Receives raw bytes, buffers them, extracts complete RCSP frames,
/// and delivers them via an `AsyncStream<RCSPFrame>`.
/// Uses @MainActor to avoid deadlocks with IOBluetooth delegate callbacks.
@MainActor
final class ClassicBTManager: NSObject {

    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "ClassicBT")

    // MARK: - State

    private(set) var isChannelOpen = false

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

        logger.info("Opening RFCOMM channel \(channelID) to \(address)…")
        logger.debug("Device paired: \(btDevice.isPaired()), connected: \(btDevice.isConnected())")

        var channel: IOBluetoothRFCOMMChannel?
        let result = btDevice.openRFCOMMChannelSync(
            &channel,
            withChannelID: channelID,
            delegate: delegate
        )

        if result != kIOReturnSuccess {
            logger.error("openRFCOMMChannelSync failed: IOReturn=\(result) (0x\(String(format: "%08x", UInt32(bitPattern: Int32(result)))))")
            logger.error("Device state — paired: \(btDevice.isPaired()), connected: \(btDevice.isConnected()), name: \(btDevice.name ?? "nil")")

            // -536870186 = kIOReturnExclusiveAccess: another host (phone) holds
            // the MIWEAR control channel. Do not keep retrying.
            if result == kIOReturnExclusiveAccess {
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

    func sendData(_ data: Data) throws {
        #if canImport(IOBluetooth)
        guard let channel = rfcommChannel, isChannelOpen else {
            logger.error("TX failed — channel not open (isChannelOpen=\(self.isChannelOpen), channel=\(self.rfcommChannel == nil ? "nil" : "exists"))")
            throw BluetoothError.notConnected
        }

        let hex = data.map { String(format: "%02x", $0) }.joined(separator: " ")
        logger.debug("TX [\(data.count) bytes]: \(hex)")

        var mutableBytes = Array(data)
        let result = channel.writeSync(&mutableBytes, length: UInt16(mutableBytes.count))

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

        return AsyncStream<RCSPFrame>(bufferingPolicy: .bufferingNewest(64)) { continuation in
            self.frameStreamContinuation = continuation
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
                logger.error("⚠️ Frame received but NO stream continuation — frame DROPPED! (op=0x\(String(format: "%02x", frame.opcode)))")
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
