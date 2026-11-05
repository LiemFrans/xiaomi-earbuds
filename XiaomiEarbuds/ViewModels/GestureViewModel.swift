import Foundation
import os.log

@MainActor @Observable
final class GestureViewModel {
    private(set) var gestureConfig: GestureConfig
    var lastError: String?

    private var protocol_: XiaomiProtocol?
    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "GestureVM")

    init(gestureConfig: GestureConfig = .default) {
        self.gestureConfig = gestureConfig
    }

    func configure(protocol proto: XiaomiProtocol) {
        self.protocol_ = proto
    }

    func action(for type: GestureType, side: EarbudSide) -> GestureAction {
        side == .left ? gestureConfig[type].left : gestureConfig[type].right
    }

    func setGesture(type: GestureType, side: EarbudSide, action: GestureAction) {
        guard self.action(for: type, side: side) != action else { return }
        switch side {
        case .left: gestureConfig[type].left = action
        case .right: gestureConfig[type].right = action
        }
        guard let protocol_ else {
            logger.warning("Gesture changed but earbuds are not connected")
            return
        }
        Task {
            do {
                try await protocol_.setGesture(type: type, side: side, action: action)
                self.lastError = nil
            } catch {
                self.lastError = "Gesture: \(error.localizedDescription)"
                self.logger.warning("setGesture failed: \(error.localizedDescription)")
                await self.loadFromDevice()
            }
        }
    }

    func loadFromDevice() async {
        guard let protocol_ else { return }
        do {
            let bindings = try await protocol_.getGestures()
            for (type, binding) in bindings {
                gestureConfig[type] = binding
            }
            logger.info("Loaded \(bindings.count) gesture bindings from earbuds")
        } catch {
            logger.warning("loadFromDevice failed: \(error.localizedDescription)")
        }
    }

    static let preview: GestureViewModel = GestureViewModel(gestureConfig: .mock)
}
