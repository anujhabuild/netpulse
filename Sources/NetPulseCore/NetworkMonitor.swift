import Foundation
import AppKit
import Combine

/// Polls network throughput once per second and publishes it for SwiftUI.
///
/// The actual delta math lives in `SpeedCalculator` (pure, unit-testable);
/// this class is the I/O/timer/lifecycle shell around it.
@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let historyLimit = 60

    @Published public private(set) var uploadBytesPerSec: Double = 0
    @Published public private(set) var downloadBytesPerSec: Double = 0
    @Published public private(set) var sessionTotalBytes: UInt64 = 0
    @Published public private(set) var activeInterfaceNames: [String] = []
    @Published public private(set) var downloadHistory: [Double] = []
    @Published public private(set) var uploadHistory: [Double] = []

    private let sampler: InterfaceSampling
    private let now: () -> Date
    private var timer: Timer?
    private var previousSample: NetworkByteCounts?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    public init(sampler: InterfaceSampling = GetifaddrsInterfaceSampler(), now: @escaping () -> Date = Date.init) {
        self.sampler = sampler
        self.now = now
    }

    deinit {
        timer?.invalidate()
        let center = NSWorkspace.shared.notificationCenter
        if let sleepObserver { center.removeObserver(sleepObserver) }
        if let wakeObserver { center.removeObserver(wakeObserver) }
    }

    public func start() {
        guard timer == nil else { return }
        previousSample = sampler.sampleCounts(at: now())
        startTimer()
        registerForSleepWakeNotifications()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func registerForSleepWakeNotifications() {
        let center = NSWorkspace.shared.notificationCenter
        sleepObserver = center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.timer?.invalidate()
                self?.timer = nil
            }
        }
        wakeObserver = center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Discard the stale pre-sleep baseline so the next tick
                // doesn't compute a rate across the sleep duration (which
                // often also coincides with an interface counter reset on
                // Wi-Fi reconnect).
                self.previousSample = self.sampler.sampleCounts(at: self.now())
                self.startTimer()
            }
        }
    }

    private func tick() {
        let current = sampler.sampleCounts(at: now())

        guard !current.interfaceNames.isEmpty else {
            // getifaddrs returned nothing usable this tick (transient).
            // Hold last-known published values and retry next tick without
            // disturbing the baseline.
            return
        }

        activeInterfaceNames = current.interfaceNames
        defer { previousSample = current }

        guard let previous = previousSample,
              let rate = SpeedCalculator.computeRate(previous: previous, current: current) else {
            return
        }

        uploadBytesPerSec = rate.uploadBytesPerSec
        downloadBytesPerSec = rate.downloadBytesPerSec

        let upDelta = current.bytesSent - previous.bytesSent
        let downDelta = current.bytesReceived - previous.bytesReceived
        sessionTotalBytes += upDelta + downDelta

        appendHistory(&downloadHistory, value: rate.downloadBytesPerSec)
        appendHistory(&uploadHistory, value: rate.uploadBytesPerSec)
    }

    private func appendHistory(_ history: inout [Double], value: Double) {
        history.append(value)
        if history.count > Self.historyLimit {
            history.removeFirst(history.count - Self.historyLimit)
        }
    }
}
