import Foundation
import os.log
import UserNotifications
#if canImport(IOBluetooth)
import IOBluetooth
#endif

/// Monitors IOBluetooth for the known earbuds connecting/disconnecting
/// using native IOBluetooth notifications (instant, no polling).
@MainActor
final class DeviceMonitor: NSObject {
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "Monitor")

    var onDeviceConnected: (() -> Void)?
    var onDeviceDisconnected: (() -> Void)?

    #if canImport(IOBluetooth)
    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotification: IOBluetoothUserNotification?
    private var deviceDisconnectNotification: IOBluetoothUserNotification?
    #endif

    private var isStarted = false
    private var debounceTask: Task<Void, Never>?
    private var lastReportedConnected = false

    func start() {
        guard !isStarted else { return }
        isStarted = true
        requestNotificationPermission()

        #if canImport(IOBluetooth)
        // Register for ANY Bluetooth device connection — we filter by address
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceConnected(_:device:))
        )

        // Also register disconnect for the specific known device
        if let device = IOBluetoothDevice(addressString: ProtocolConstants.knownDeviceAddress) {
            disconnectNotification = device.register(
                forDisconnectNotification: self,
                selector: #selector(deviceDisconnected(_:device:))
            )

            // Check if already connected right now
            if device.isConnected() {
                logger.info("🔵 Earbuds already connected on monitor start")
                onDeviceConnected?()
            }
        }

        logger.info("📡 Device monitor started — listening for IOBluetooth notifications")
        #endif
    }

    func stop() {
        #if canImport(IOBluetooth)
        connectNotification?.unregister()
        disconnectNotification?.unregister()
        deviceDisconnectNotification?.unregister()
        connectNotification = nil
        disconnectNotification = nil
        deviceDisconnectNotification = nil
        #endif
        isStarted = false
    }

    // MARK: - IOBluetooth Callbacks

    #if canImport(IOBluetooth)
    @objc private func deviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let address = device.addressString ?? ""
        let name = device.name ?? "Unknown"

        // Only react to our known earbuds
        guard address.lowercased().replacingOccurrences(of: "-", with: ":") ==
              ProtocolConstants.knownDeviceAddress.lowercased().replacingOccurrences(of: "-", with: ":") else {
            return
        }

        logger.info("🔵 IOBluetooth: \(name) connected")

        // Register disconnect notification for this device
        deviceDisconnectNotification = device.register(
            forDisconnectNotification: self,
            selector: #selector(deviceDisconnected(_:device:))
        )

        scheduleDebounce(connected: true)
    }

    @objc private func deviceDisconnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let name = device.name ?? "Unknown"
        logger.info("⚪ IOBluetooth: \(name) disconnected")
        scheduleDebounce(connected: false)
    }

    /// Debounce rapid connect/disconnect events (earbuds create multiple ACL links).
    /// Waits 2 seconds after the last event before firing the callback.
    private func scheduleDebounce(connected: Bool) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled else { return }

            // Check actual device state after debounce
            let actuallyConnected: Bool
            #if canImport(IOBluetooth)
            actuallyConnected = IOBluetoothDevice(addressString: ProtocolConstants.knownDeviceAddress)?.isConnected() ?? false
            #else
            actuallyConnected = connected
            #endif

            guard actuallyConnected != self.lastReportedConnected else { return }
            self.lastReportedConnected = actuallyConnected

            if actuallyConnected {
                self.logger.info("🔵 Debounced: earbuds confirmed connected")
                self.onDeviceConnected?()
            } else {
                self.logger.info("⚪ Debounced: earbuds confirmed disconnected")
                self.onDeviceDisconnected?()
            }
        }
    }
    #endif

    // MARK: - macOS Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
