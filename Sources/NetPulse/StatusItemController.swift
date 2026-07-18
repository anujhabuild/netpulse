import AppKit
import SwiftUI
import Combine
import NetPulseCore

/// Owns a raw `NSStatusItem` + `NSPopover` pair. Built directly on AppKit
/// (rather than SwiftUI's `MenuBarExtra`) for tight, native control over
/// the status item's title/padding — matching system icons like Wi-Fi and
/// Bluetooth instead of the wider click-target padding `MenuBarExtra`'s
/// `.window` style imposes.
@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let monitor: NetworkMonitor
    private let loginManager: LaunchAtLoginManager
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        monitor = NetworkMonitor()
        loginManager = LaunchAtLoginManager()
        popover = NSPopover()

        super.init()

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 240, height: 310)
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView(monitor: monitor, loginManager: loginManager)
        )

        if let button = statusItem.button {
            button.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            button.title = Self.labelString(up: 0, down: 0)
            button.action = #selector(togglePopover)
            button.target = self
        }

        monitor.$uploadBytesPerSec
            .combineLatest(monitor.$downloadBytesPerSec)
            .sink { [weak self] up, down in
                self?.statusItem.button?.title = Self.labelString(up: up, down: down)
            }
            .store(in: &cancellables)

        monitor.start()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private static func labelString(up: Double, down: Double) -> String {
        let upStr = ByteRateFormatter.string(fromBytesPerSecond: up)
        let downStr = ByteRateFormatter.string(fromBytesPerSecond: down)
        return "↑ \(upStr) | ↓ \(downStr)"
    }
}
