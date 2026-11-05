import Foundation

// MARK: - Connection State

/// Bluetooth connection lifecycle states.
enum ConnectionState: Sendable {
    case disconnected
    case scanning
    case connecting
    case connected
    case disconnecting
}

// MARK: - Discovered Device

/// A Bluetooth device found during scanning.
struct DiscoveredDevice: Identifiable, Sendable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisedServices: [String]
}

// MARK: - Paired Device

/// A previously paired device stored in persistence.
struct PairedDevice: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
    let lastConnected: Date
}

// MARK: - Earbud Side

/// Which earbud a gesture binding applies to.
enum EarbudSide: Sendable {
    case left
    case right
}
