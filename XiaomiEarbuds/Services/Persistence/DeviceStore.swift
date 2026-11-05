import Foundation

/// Manages a persistent list of previously paired Bluetooth devices.
///
/// Uses `UserDefaults` with `Codable` serialisation for v1 simplicity.
final class DeviceStore: ObservableObject, @unchecked Sendable {

    private static let storageKey = "pairedDevices"

    /// The list of paired devices, ordered by most-recently connected first.
    @Published private(set) var devices: [PairedDevice] = []

    // MARK: - Initialisation

    init() {
        devices = Self.loadDevices()
    }

    // MARK: - Public API

    /// Adds or updates a paired device record.
    /// - Parameters:
    ///   - name: The device name.
    ///   - address: The Bluetooth address (e.g. `B8:53:84:6B:BD:88`).
    func addOrUpdate(name: String, address: String) {
        let device = PairedDevice(
            id: address,
            name: name,
            address: address,
            lastConnected: Date()
        )

        var current = devices
        current.removeAll { $0.address == address }
        current.insert(device, at: 0)
        devices = current
        save(current)
    }

    /// Removes a paired device by address.
    /// - Parameter address: The Bluetooth address to remove.
    func remove(address: String) {
        var current = devices
        current.removeAll { $0.address == address }
        devices = current
        save(current)
    }

    /// Returns the most recently connected device, if any.
    func mostRecent() -> PairedDevice? {
        devices.first
    }

    /// Clears all paired device records.
    func removeAll() {
        devices = []
        save([])
    }

    // MARK: - Private

    private static func loadDevices() -> [PairedDevice] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([PairedDevice].self, from: data)) ?? []
    }

    private func save(_ devices: [PairedDevice]) {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
