import SwiftUI
import AppKit
import SpeedWidthCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct SpeedWidthApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = NetworkMonitor()
    @StateObject private var loginManager = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(monitor: monitor, loginManager: loginManager)
        } label: {
            MenuBarLabelView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
