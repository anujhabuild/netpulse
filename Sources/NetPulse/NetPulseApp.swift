import SwiftUI
import AppKit
import NetPulseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app switcher entry.
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController()
    }
}

@main
struct NetPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No window-bearing scene is needed — the status item and its
        // popover are managed directly by StatusItemController via
        // AppKit. `Settings` is used only because `App` requires at
        // least one Scene; it never opens on its own.
        Settings {
            EmptyView()
        }
    }
}
