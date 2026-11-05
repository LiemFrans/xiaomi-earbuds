import Foundation
@preconcurrency import CoreBluetooth

/// Handles BLE GATT operations (service/characteristic discovery, read, write, notify)
/// after a peripheral connection has been established.
actor BLEManager: NSObject {

    // MARK: - Properties

    private var peripheral: CBPeripheral?
    private var delegateHandler: PeripheralDelegateHandler!
    private var discoveredCharacteristics: [CBUUID: CBCharacteristic] = [:]

    // Continuations for async/await bridging
    private var serviceDiscoveryContinuation: CheckedContinuation<[CBService], Error>?
    private var readContinuation: CheckedContinuation<Data, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var notificationStream: AsyncStream<Data>.Continuation?

    // MARK: - Initialisation

    override init() {
        super.init()
        delegateHandler = PeripheralDelegateHandler(manager: self)
    }

    // MARK: - Configuration

    /// Sets the connected peripheral to manage.
    /// - Parameter peripheral: The `CBPeripheral` returned from `BluetoothManager.connect(to:)`.
    func configure(with peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = delegateHandler
        discoveredCharacteristics = [:]
    }

    // MARK: - Service Discovery

    /// Discovers all services and their characteristics on the connected peripheral.
    /// - Returns: The list of discovered `CBService` objects.
    @discardableResult
    func discoverServices() async throws -> [CBService] {
        guard let peripheral else { throw BluetoothError.notConnected }

        return try await withCheckedThrowingContinuation { continuation in
            serviceDiscoveryContinuation = continuation
            peripheral.discoverServices(nil)
        }
    }

    // MARK: - Read

    /// Reads the current value of a characteristic.
    /// - Parameter uuid: The CBUUID of the characteristic to read.
    /// - Returns: The characteristic's value.
    func readCharacteristic(uuid: CBUUID) async throws -> Data {
        guard let peripheral else { throw BluetoothError.notConnected }
        guard let characteristic = discoveredCharacteristics[uuid] else {
            throw BluetoothError.characteristicNotFound(uuid: uuid.uuidString)
        }

        return try await withCheckedThrowingContinuation { continuation in
            readContinuation = continuation
            peripheral.readValue(for: characteristic)

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(ProtocolConstants.commandTimeout * 1_000_000_000))
                await self?.handleReadTimeout()
            }
        }
    }

    // MARK: - Write

    /// Writes data to a characteristic.
    /// - Parameters:
    ///   - uuid: The CBUUID of the characteristic to write to.
    ///   - data: The data to write.
    ///   - withResponse: Whether to request a write-with-response (`true`) or write-without-response (`false`).
    func writeCharacteristic(uuid: CBUUID, data: Data, withResponse: Bool = true) async throws {
        guard let peripheral else { throw BluetoothError.notConnected }
        guard let characteristic = discoveredCharacteristics[uuid] else {
            throw BluetoothError.characteristicNotFound(uuid: uuid.uuidString)
        }

        let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse

        if withResponse {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                writeContinuation = continuation
                peripheral.writeValue(data, for: characteristic, type: type)

                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(ProtocolConstants.commandTimeout * 1_000_000_000))
                    await self?.handleWriteTimeout()
                }
            }
        } else {
            peripheral.writeValue(data, for: characteristic, type: type)
        }
    }

    // MARK: - Notifications

    /// Subscribes to value-change notifications for a characteristic.
    /// - Parameter uuid: The CBUUID of the characteristic to observe.
    /// - Returns: An `AsyncStream` that yields `Data` on each notification.
    func subscribeToNotifications(uuid: CBUUID) async throws -> AsyncStream<Data> {
        guard let peripheral else { throw BluetoothError.notConnected }
        guard let characteristic = discoveredCharacteristics[uuid] else {
            throw BluetoothError.characteristicNotFound(uuid: uuid.uuidString)
        }

        let stream = AsyncStream<Data> { continuation in
            self.notificationStream = continuation
        }

        peripheral.setNotifyValue(true, for: characteristic)
        return stream
    }

    /// Unsubscribes from notifications for a characteristic.
    /// - Parameter uuid: The CBUUID of the characteristic.
    func unsubscribeFromNotifications(uuid: CBUUID) {
        guard let peripheral, let characteristic = discoveredCharacteristics[uuid] else { return }
        peripheral.setNotifyValue(false, for: characteristic)
        notificationStream?.finish()
        notificationStream = nil
    }

    // MARK: - Internal Delegate Callbacks

    func handleServicesDiscovered(services: [CBService]?, error: Error?) {
        if let error {
            serviceDiscoveryContinuation?.resume(throwing: BluetoothError.writeError(underlying: error.localizedDescription))
            serviceDiscoveryContinuation = nil
            return
        }

        guard let services, let peripheral else {
            serviceDiscoveryContinuation?.resume(throwing: BluetoothError.serviceDiscoveryFailed)
            serviceDiscoveryContinuation = nil
            return
        }

        // Discover characteristics for each service
        let group = services
        let pendingServiceCount = group.count

        if pendingServiceCount == 0 {
            serviceDiscoveryContinuation?.resume(returning: services)
            serviceDiscoveryContinuation = nil
            return
        }

        // Store callback for characteristic discovery completion
        characteristicDiscoveryCounter = pendingServiceCount
        pendingServices = services

        for service in group {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    private var characteristicDiscoveryCounter = 0
    private var pendingServices: [CBService] = []

    func handleCharacteristicsDiscovered(service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                discoveredCharacteristics[characteristic.uuid] = characteristic
            }
        }

        characteristicDiscoveryCounter -= 1
        if characteristicDiscoveryCounter <= 0 {
            serviceDiscoveryContinuation?.resume(returning: pendingServices)
            serviceDiscoveryContinuation = nil
            pendingServices = []
        }
    }

    func handleCharacteristicValueUpdated(characteristic: CBCharacteristic, error: Error?) {
        if let error {
            readContinuation?.resume(throwing: BluetoothError.readError(underlying: error.localizedDescription))
            readContinuation = nil
            return
        }

        guard let value = characteristic.value else {
            readContinuation?.resume(throwing: BluetoothError.readError(underlying: "No data"))
            readContinuation = nil
            return
        }

        // If there's a pending read, fulfil it
        if let continuation = readContinuation {
            continuation.resume(returning: value)
            readContinuation = nil
        } else {
            // Otherwise it's a notification
            notificationStream?.yield(value)
        }
    }

    func handleCharacteristicWriteCompleted(characteristic: CBCharacteristic, error: Error?) {
        if let error {
            writeContinuation?.resume(throwing: BluetoothError.writeError(underlying: error.localizedDescription))
        } else {
            writeContinuation?.resume()
        }
        writeContinuation = nil
    }

    private func handleReadTimeout() {
        guard readContinuation != nil else { return }
        readContinuation?.resume(throwing: BluetoothError.timeout)
        readContinuation = nil
    }

    private func handleWriteTimeout() {
        guard writeContinuation != nil else { return }
        writeContinuation?.resume(throwing: BluetoothError.timeout)
        writeContinuation = nil
    }
}

// MARK: - CBPeripheralDelegate Handler

/// Bridges CBPeripheralDelegate callbacks to the actor.
private final class PeripheralDelegateHandler: NSObject, CBPeripheralDelegate {
    private weak var _manager: BLEManager?

    init(manager: BLEManager) {
        _manager = manager
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let manager = _manager else { return }
        Task { await manager.handleServicesDiscovered(services: peripheral.services, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let manager = _manager else { return }
        Task { await manager.handleCharacteristicsDiscovered(service: service, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let manager = _manager else { return }
        Task { await manager.handleCharacteristicValueUpdated(characteristic: characteristic, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let manager = _manager else { return }
        Task { await manager.handleCharacteristicWriteCompleted(characteristic: characteristic, error: error) }
    }
}
