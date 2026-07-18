import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the popover's "Launch at Login" toggle
/// can register/unregister the app as a login item. Not registered by
/// default — the user opts in explicitly.
@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var lastError: String?

    public init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            // Reflect the failure back to the caller; isEnabled below is
            // re-read from the real status so the toggle never shows a
            // false "on" state after a failed registration.
            lastError = error.localizedDescription
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    public func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
