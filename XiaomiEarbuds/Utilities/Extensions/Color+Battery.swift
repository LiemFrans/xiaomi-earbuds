import SwiftUI

extension Color {
    static func forBatteryLevel(_ level: Int) -> Color {
        switch level {
        case 0..<10: .red
        case 10..<20: .orange
        case 20..<50: .yellow
        default: .green
        }
    }
}
