import SwiftUI
@preconcurrency import Combine
import os.log

@MainActor @Observable
final class DeviceViewModel {
    var device: EarbudDevice
    var connectionState: ConnectionState
    var connectionError: String?
    var lastError: String?
    /// Set to true briefly when earbuds connect — triggers popover flash
    var justConnected: Bool = false

    var isConnected: Bool { connectionState == .connected }

    let bluetoothManager: BluetoothManager
    private(set) var protocol_: XiaomiProtocol?
    private let monitor = DeviceMonitor()

    private var cancellables = Set<AnyCancellable>()
    private var batteryRefreshTask: Task<Void, Never>?
    private var consecutiveFailures = 0
    private var featureVMs: (nc: NoiseControlViewModel, au: AudioViewModel, sa: SpatialAudioViewModel, ge: GestureViewModel, se: SettingsViewModel)?
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "DeviceVM")

    private var noiseControlVM: NoiseControlViewModel?

    init(device: EarbudDevice = EarbudDevice(), connectionState: ConnectionState = .disconnected) {
        self.device = device
        self.connectionState = connectionState
        self.bluetoothManager = BluetoothManager()
    }

    func configureFeatureViewModels(
        noiseControl: NoiseControlViewModel,
        audio: AudioViewModel,
        spatialAudio: SpatialAudioViewModel,
        gesture: GestureViewModel,
        settings: SettingsViewModel
    ) {
        self.noiseControlVM = noiseControl
        self.featureVMs = (noiseControl, audio, spatialAudio, gesture, settings)
    }

    /// Start monitoring Bluetooth for earbuds appearing/disappearing.
    func startMonitoring() {
        monitor.onDeviceConnected = { [weak self] in
            guard let self, !self.isConnected, self.connectionState != .connecting else { return }
            self.logger.info("🔵 Auto-connect triggered by device monitor")
            Task { await self.connectAndLoadState() }
        }
        monitor.onDeviceDisconnected = { [weak self] in
            guard let self, self.isConnected else { return }
            self.logger.info("⚪ Device monitor detected earbuds gone")
            self.stopPeriodicBatteryRefresh()
            Task { await self.protocol_?.stopListening() }
            self.bluetoothManager.classicManager.disconnect()
            self.protocol_ = nil
            self.cancellables.removeAll()
            self.markDisconnected()
        }
        monitor.start()
    }

    // MARK: - Connect

    func connect() async {
        await connectAndLoadState()
    }

    private func connectAndLoadState() async {
        connectionError = nil
        lastError = nil
        connectionState = .connecting
        logger.info("🚀 Connect flow starting…")
        try? await Task.sleep(for: .seconds(1.5))

        for attempt in 1...3 {
            do {
                logger.info("🔄 Connect attempt \(attempt)/3")
                if attempt > 1 { try await Task.sleep(for: .seconds(2)) }

                try bluetoothManager.classicManager.connect()

                let proto = XiaomiProtocol(classicManager: bluetoothManager.classicManager)
                self.protocol_ = proto

                await proto.startListening()
                try await Task.sleep(for: .milliseconds(300))
                try await proto.authenticate()

                connectionState = .connected
                device.isConnected = true
                connectionError = nil
                consecutiveFailures = 0

                let info = try await proto.getDeviceInfo()
                if !info.name.isEmpty { device.internalName = info.name }
                if !info.firmwareVersion.isEmpty { device.firmwareVersion = info.firmwareVersion }
                if let battery = info.battery { device.batteryInfo = battery }

                subscribeToEvents(proto)
                startPeriodicBatteryRefresh()

                logger.info("🎉 Connected! Battery: L=\(self.device.batteryInfo.leftLevel)% R=\(self.device.batteryInfo.rightLevel)% C=\(self.device.batteryInfo.caseLevel)%")

                // Notify + flash popover
                DeviceMonitor.sendNotification(
                    title: "REDMI Buds 8 Pro Connected",
                    body: "🔋 L:\(device.batteryInfo.leftLevel)% R:\(device.batteryInfo.rightLevel)% Case:\(device.batteryInfo.caseLevel)%"
                )
                justConnected = true
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    self.justConnected = false
                }

                // Load feature state
                await loadFeatureState(proto)
                return
            } catch {
                logger.warning("❌ Attempt \(attempt) failed: \(error.localizedDescription)")
                await cleanupAfterFailure()
                if attempt == 3 {
                    connectionError = error.localizedDescription
                    lastError = error.localizedDescription
                    connectionState = .disconnected
                }
            }
        }
    }

    private func loadFeatureState(_ proto: XiaomiProtocol) async {
        guard let vms = featureVMs else { return }
        vms.nc.configure(protocol: proto)
        vms.au.configure(protocol: proto)
        vms.sa.configure(protocol: proto)
        vms.ge.configure(protocol: proto)
        vms.se.configure(protocol: proto)

        async let nc: () = vms.nc.loadFromDevice()
        async let au: () = vms.au.loadFromDevice()
        async let ge: () = vms.ge.loadFromDevice()
        async let se: () = vms.se.loadFromDevice()
        _ = await (nc, au, ge, se)
    }

    func disconnect() async {
        stopPeriodicBatteryRefresh()
        await protocol_?.stopListening()
        bluetoothManager.classicManager.disconnect()
        protocol_ = nil
        cancellables.removeAll()
        markDisconnected()
    }

    private func markDisconnected() {
        guard connectionState != .disconnected else { return }
        logger.warning("📴 Marking as disconnected")
        connectionState = .disconnected
        device.isConnected = false
        device.batteryInfo = .empty
    }

    private func cleanupAfterFailure() async {
        await protocol_?.stopListening()
        bluetoothManager.classicManager.disconnect()
        protocol_ = nil
    }

    // MARK: - Battery heartbeat

    func refreshBattery() async {
        guard isConnected, let proto = protocol_ else { return }
        do {
            device.batteryInfo = try await proto.getBatteryLevels()
            consecutiveFailures = 0
        } catch {
            consecutiveFailures += 1
            logger.warning("Battery heartbeat failed (\(self.consecutiveFailures)/3): \(error.localizedDescription)")
            if consecutiveFailures >= 3 {
                logger.error("💀 3 consecutive heartbeat failures → disconnecting")
                stopPeriodicBatteryRefresh()
                await protocol_?.stopListening()
                bluetoothManager.classicManager.disconnect()
                protocol_ = nil
                cancellables.removeAll()
                markDisconnected()
            }
        }
    }

    func startPeriodicBatteryRefresh() {
        stopPeriodicBatteryRefresh()
        batteryRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard let self, self.isConnected else { break }
                await self.refreshBattery()
            }
        }
    }

    func stopPeriodicBatteryRefresh() {
        batteryRefreshTask?.cancel()
        batteryRefreshTask = nil
    }

    // MARK: - Events

    private func subscribeToEvents(_ proto: XiaomiProtocol) {
        cancellables.removeAll()

        proto.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .battery(let info):
                    self.device.batteryInfo = info
                    self.consecutiveFailures = 0
                case .anc(let mode, let level):
                    self.noiseControlVM?.applyDeviceANC(mode: mode, level: level)
                case .config:
                    break
                }
            }
            .store(in: &cancellables)

        proto.disconnectedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.logger.warning("⚠️ RFCOMM channel closed")
                self.stopPeriodicBatteryRefresh()
                self.protocol_ = nil
                self.cancellables.removeAll()
                self.markDisconnected()
            }
            .store(in: &cancellables)
    }

    static let preview: DeviceViewModel = {
        DeviceViewModel(device: .mock, connectionState: .connected)
    }()
}
