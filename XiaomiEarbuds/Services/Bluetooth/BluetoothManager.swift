import Foundation
@preconcurrency import CoreBluetooth
@preconcurrency import Combine
import os.log

/// Main entry point for Bluetooth operations with REDMI Buds 8 Pro.
///
/// Uses Classic Bluetooth RFCOMM (IOBluetooth) as primary transport for the
/// MIWEAR proprietary protocol, with BLE scanning as a fallback for discovery.
@MainActor
final class BluetoothManager: NSObject {

    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "BTManager")

    // MARK: - Published State

    private(set) var connectionState: ConnectionState = .disconnected {
        didSet { connectionStateSubject.send(connectionState) }
    }

    private(set) var discoveredDevices: [DiscoveredDevice] = [] {
        didSet { discoveredDevicesSubject.send(discoveredDevices) }
    }

    // MARK: - Combine Publishers (for SwiftUI)

    nonisolated let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    nonisolated let discoveredDevicesSubject = CurrentValueSubject<[DiscoveredDevice], Never>([])

    // MARK: - Transport

    let classicManager = ClassicBTManager()

    private var autoReconnectEnabled = true

    /// BLE central manager for discovery fallback.
    private var centralManager: CBCentralManager!
    private var delegateHandler: CentralManagerDelegate!

    // MARK: - Initialisation

    override init() {
        super.init()
        delegateHandler = CentralManagerDelegate(manager: self)
        centralManager = CBCentralManager(delegate: delegateHandler, queue: nil)
    }

    // MARK: - Connect via RFCOMM (Primary)

    func connect() async throws {
        guard connectionState != .connected else {
            logger.info("Already connected")
            return
        }

        connectionState = .connecting
        logger.info("Connecting via RFCOMM to \(ProtocolConstants.knownDeviceAddress)…")

        do {
            try classicManager.connect(
                address: ProtocolConstants.knownDeviceAddress,
                channelID: ProtocolConstants.miwearRFCOMMChannel
            )
            connectionState = .connected
            logger.info("Connected via RFCOMM")
        } catch {
            connectionState = .disconnected
            logger.error("RFCOMM connection failed: \(error.localizedDescription)")
            throw error
        }
    }

    func disconnect() async {
        autoReconnectEnabled = false
        connectionState = .disconnecting
        classicManager.disconnect()
        connectionState = .disconnected
        logger.info("Disconnected")
    }

    var isConnected: Bool {
        classicManager.isChannelOpen
    }

    // MARK: - Auto-Reconnection

    func enableAutoReconnect() {
        autoReconnectEnabled = true
    }

    func disableAutoReconnect() {
        autoReconnectEnabled = false
    }

    func handleUnexpectedDisconnect() {
        connectionState = .disconnected
        logger.warning("Unexpected disconnect detected")

        guard autoReconnectEnabled else { return }

        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(ProtocolConstants.reconnectDelay * 1_000_000_000))
            let state = await self.connectionState
            guard state == .disconnected else { return }
            self.logger.info("Attempting auto-reconnect…")
            try? await self.connect()
        }
    }

    // MARK: - BLE Scanning (Discovery fallback)

    func startScanning() async throws {
        guard centralManager.state == .poweredOn else {
            throw BluetoothError.notPoweredOn
        }

        connectionState = .scanning
        discoveredDevices = []

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ProtocolConstants.scanTimeout * 1_000_000_000))
            await self?.stopScanning()
        }
    }

    func stopScanning() {
        guard centralManager.isScanning else { return }
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    // MARK: - Internal BLE Delegate Callbacks

    private var connectInProgress = false

    func handlePoweredOn() {
        logger.info("Bluetooth powered on")
        // Don't auto-connect here — DeviceViewModel.connect() handles retries
    }

    func handleDiscoveredPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        let name = peripheral.name ?? "Unknown"
        guard name.uppercased().contains(ProtocolConstants.deviceNameFilter) else { return }

        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []

        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: name,
            rssi: rssi.intValue,
            advertisedServices: services
        )

        if !discoveredDevices.contains(where: { $0.id == device.id }) {
            discoveredDevices.append(device)
        }
    }
}

// MARK: - CBCentralManagerDelegate Handler

private final class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    private weak var _manager: BluetoothManager?

    init(manager: BluetoothManager) {
        _manager = manager
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let manager = _manager else { return }
        if central.state == .poweredOn {
            Task { await manager.handlePoweredOn() }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let manager = _manager else { return }
        nonisolated(unsafe) let adData = advertisementData
        Task { await manager.handleDiscoveredPeripheral(peripheral, rssi: RSSI, advertisementData: adData) }
    }
}
