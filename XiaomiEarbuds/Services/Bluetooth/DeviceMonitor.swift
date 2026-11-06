import Foundation
import os.log
import UserNotifications
#if canImport(IOBluetooth)
import IOBluetooth
#endif

/// Monitors IOBluetooth for the known earbuds connecting/disconnecting at the
/// system level (Classic BT ACL). When the earbuds appear, fires `onDeviceConnected`.
@MainActor
final class DeviceMonitor {
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "Monitor")

    var onDeviceConnected: (() -> Void)?
    var onDeviceDisconnected: (() -> Void)?

    private var pollTask: Task<Void, Never>?
    private var wasConnected = false

    func start() {
        logger.info("📡 Device monitor started — polling for REDMI Buds 8 Pro")
        requestNotificationPermission()

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { break }
                self.checkDevice()
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func checkDevice() {
        #if canImport(IOBluetooth)
        let device = IOBluetoothDevice(addressString: ProtocolConstants.knownDeviceAddress)
        let isNowConnected = device?.isConnected() ?? false

        if isNowConnected && !wasConnected {
            logger.info("🔵 Earbuds appeared on Bluetooth!")
            wasConnected = true
            onDeviceConnected?()
        } else if !isNowConnected && wasConnected {
            logger.info("⚪ Earbuds disappeared from Bluetooth")
            wasConnected = false
            onDeviceDisconnected?()
        }
        #endif
    }

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
