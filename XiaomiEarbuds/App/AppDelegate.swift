import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Monitoring and auto-connect must not depend on a window being open,
        // which is why this runs from the delegate rather than a SwiftUI task.
        AppModel.shared.start()
    }
}
