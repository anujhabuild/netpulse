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
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        monitor = NetworkMonitor()
        loginManager = LaunchAtLoginManager()
        popover = NSPopover()

        super.init()

        // `.transient` hands dismissal entirely to AppKit's heuristics,
        // which can misfire on clicks inside SwiftUI content (e.g. the
        // Chart's own gesture recognizers) and close the popover even
        // though the click never left it. `.applicationDefined` disables
        // that, and outside-click dismissal is handled explicitly below
        // by checking the clicked window's identity.
        popover.behavior = .applicationDefined
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
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startWatchingForOutsideClicks()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        stopWatchingForOutsideClicks()
    }

    // Closes the popover only for clicks whose window isn't the
    // popover's own — clicks inside it (graph, toggle, buttons) pass
    // through untouched.
    private func startWatchingForOutsideClicks() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.closePopover()
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self else { return event }
            let popoverWindow = self.popover.contentViewController?.view.window
            // Clicking the status item button itself is already handled
            // by its own target/action (togglePopover) — closing it here
            // too would cause a close-then-immediately-reopen flicker.
            let statusItemWindow = self.statusItem.button?.window
            if event.window !== popoverWindow, event.window !== statusItemWindow {
                self.closePopover()
            }
            return event
        }
    }

    private func stopWatchingForOutsideClicks() {
        if let globalClickMonitor { NSEvent.removeMonitor(globalClickMonitor) }
        if let localClickMonitor { NSEvent.removeMonitor(localClickMonitor) }
        globalClickMonitor = nil
        localClickMonitor = nil
    }

    // Fixed-width numeric format (e.g. "0009.23 KB/s") so the button's
    // rendered title width never changes tick to tick — otherwise the
    // NSStatusItem (.variableLength) resizes on every update, shifting
    // every icon to its right (and the popover's anchor point) sideways.
    private static func labelString(up: Double, down: Double) -> String {
        let upStr = ByteRateFormatter.fixedWidthString(fromBytesPerSecond: up)
        let downStr = ByteRateFormatter.fixedWidthString(fromBytesPerSecond: down)
        return "↑ \(upStr) | ↓ \(downStr)"
    }
}
