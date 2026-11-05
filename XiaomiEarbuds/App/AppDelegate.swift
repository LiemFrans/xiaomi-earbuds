import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar extra is managed via SwiftUI's MenuBarExtra scene in XiaomiEarbudsApp.
        // No manual NSStatusItem setup needed — environment objects are passed there.
    }
}
