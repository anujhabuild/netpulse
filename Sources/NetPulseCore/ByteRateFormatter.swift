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

    // "By/s" (not the usual "B/s") so every tier's unit label is the same
    // 4-character width as "KB/s"/"MB/s"/"GB/s" — see fixedWidthString.
    private static let fixedWidthUnits = ["By/s", "KB/s", "MB/s", "GB/s"]

    /// Formats a bytes-per-second value with a fixed-width, zero-padded
    /// number (3 integer digits + 2 decimals, e.g. `009.23`, `512.34`)
    /// and a unit label that's always 4 characters wide, so the rendered
    /// width never changes as the value changes — unlike
    /// `string(fromBytesPerSecond:)`, whose length varies with both the
    /// digit count and the unit. Intended for UI spots (like a menu bar
    /// status item) where a changing width would resize/reposition the
    /// surrounding layout (and can crowd out other menu bar items).
    public static func fixedWidthString(fromBytesPerSecond value: Double) -> String {
        var scaled = max(value, 0)
        var unitIndex = 0
        // Roll over to the next unit once display would need a 4th
        // integer digit, even though the underlying conversion is /1024 —
        // this keeps the integer part capped at 3 digits (max 999.99).
        while scaled >= 1000, unitIndex < fixedWidthUnits.count - 1 {
            scaled /= 1024
            unitIndex += 1
        }
        return String(format: "%06.2f %@", scaled, fixedWidthUnits[unitIndex])
    }

    /// Formats a cumulative byte total (e.g. session data usage) as an
    /// auto-scaling string (`B`, `KB`, `MB`, `GB`), same thresholds as above.
    public static func string(fromTotalBytes value: UInt64) -> String {
        let rateStyle = string(fromBytesPerSecond: Double(value))
        return String(rateStyle.dropLast(2)) // trims the trailing "/s"
    }
}
