import Foundation

/// Formats a bytes-per-second value as an auto-scaling human string
/// (`B/s`, `KB/s`, `MB/s`, `GB/s`), using 1024-based thresholds to match
/// Activity Monitor's convention. One decimal place once scaled above
/// `B/s`; whole numbers for raw `B/s`.
public enum ByteRateFormatter {
    private static let units = ["B/s", "KB/s", "MB/s", "GB/s"]

    public static func string(fromBytesPerSecond value: Double) -> String {
        guard value > 0 else { return "0 B/s" }

        var scaled = value
        var unitIndex = 0
        while scaled >= 1024, unitIndex < units.count - 1 {
            scaled /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(scaled.rounded())) \(units[unitIndex])"
        }
        return String(format: "%.1f %@", scaled, units[unitIndex])
    }

    /// Formats a cumulative byte total (e.g. session data usage) as an
    /// auto-scaling string (`B`, `KB`, `MB`, `GB`), same thresholds as above.
    public static func string(fromTotalBytes value: UInt64) -> String {
        let rateStyle = string(fromBytesPerSecond: Double(value))
        return String(rateStyle.dropLast(2)) // trims the trailing "/s"
    }
}
