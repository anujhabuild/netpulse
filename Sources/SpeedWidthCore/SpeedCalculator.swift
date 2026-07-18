import Foundation

/// Computed upload/download throughput between two samples.
public struct SpeedSample: Equatable {
    public let uploadBytesPerSec: Double
    public let downloadBytesPerSec: Double

    public init(uploadBytesPerSec: Double, downloadBytesPerSec: Double) {
        self.uploadBytesPerSec = uploadBytesPerSec
        self.downloadBytesPerSec = downloadBytesPerSec
    }

    public static let zero = SpeedSample(uploadBytesPerSec: 0, downloadBytesPerSec: 0)
}

/// Pure delta-computation logic, kept free of I/O and timers so it can be
/// unit tested with synthetic byte-counter sequences.
public enum SpeedCalculator {
    /// Computes throughput between two counter readings.
    ///
    /// Returns `nil` when the reading pair can't produce a meaningful rate:
    /// non-positive elapsed time, or counters that went backwards (an
    /// interface counter reset, e.g. after a sleep/wake Wi-Fi reconnect).
    /// Callers should treat `nil` as "no delta this tick" and adopt
    /// `current` as the new baseline, rather than showing a fabricated
    /// spike from an unsigned-subtraction underflow.
    public static func computeRate(
        previous: NetworkByteCounts,
        current: NetworkByteCounts
    ) -> SpeedSample? {
        let elapsed = current.timestamp.timeIntervalSince(previous.timestamp)
        guard elapsed > 0 else { return nil }

        guard current.bytesReceived >= previous.bytesReceived,
              current.bytesSent >= previous.bytesSent else {
            return nil
        }

        let downBytes = current.bytesReceived - previous.bytesReceived
        let upBytes = current.bytesSent - previous.bytesSent

        return SpeedSample(
            uploadBytesPerSec: Double(upBytes) / elapsed,
            downloadBytesPerSec: Double(downBytes) / elapsed
        )
    }
}
