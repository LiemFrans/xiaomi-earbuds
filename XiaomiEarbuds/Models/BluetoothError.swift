import Foundation

/// Errors that can occur during Bluetooth operations.
enum BluetoothError: Error, LocalizedError, Sendable {
    case notPoweredOn
    case deviceNotFound
    case connectionFailed(underlying: String)
    case disconnectionFailed
    case serviceDiscoveryFailed
    case characteristicNotFound(uuid: String)
    case writeError(underlying: String)
    case readError(underlying: String)
    case notificationError(underlying: String)
    case timeout
    case invalidResponse
    case checksumMismatch
    case rfcommChannelFailed
    case rfcommBusy
    case notConnected
    case alreadyConnected
    case encodingError

    var errorDescription: String? {
        switch self {
        case .notPoweredOn:
            return "Bluetooth is not powered on."
        case .deviceNotFound:
            return "Earbuds not found. Make sure they are in pairing mode."
        case .connectionFailed(let underlying):
            return "Connection failed: \(underlying)"
        case .disconnectionFailed:
            return "Failed to disconnect from the device."
        case .serviceDiscoveryFailed:
            return "Failed to discover Bluetooth services."
        case .characteristicNotFound(let uuid):
            return "Characteristic \(uuid) not found."
        case .writeError(let underlying):
            return "Failed to write data: \(underlying)"
        case .readError(let underlying):
            return "Failed to read data: \(underlying)"
        case .notificationError(let underlying):
            return "Notification subscription failed: \(underlying)"
        case .timeout:
            return "Bluetooth operation timed out."
        case .invalidResponse:
            return "Received an invalid response from the earbuds."
        case .checksumMismatch:
            return "Response checksum verification failed."
        case .rfcommChannelFailed:
            return "Failed to open RFCOMM channel."
        case .rfcommBusy:
            return "Can't open the control channel. Close the Xiaomi Earbuds app on your phone (it holds the channel), make sure the earbuds are out of the case, then tap Connect."
        case .notConnected:
            return "No device is currently connected."
        case .alreadyConnected:
            return "A device is already connected."
        case .encodingError:
            return "Failed to encode command payload."
        }
    }
}
