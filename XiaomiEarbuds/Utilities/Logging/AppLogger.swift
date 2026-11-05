import OSLog

enum AppLogger {
    static let bluetooth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xiaomi.earbuds", category: "bluetooth")
    static let `protocol` = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xiaomi.earbuds", category: "protocol")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xiaomi.earbuds", category: "ui")
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xiaomi.earbuds", category: "general")
}
