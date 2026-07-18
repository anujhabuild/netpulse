import Foundation

/// A single point-in-time reading of cumulative network byte counters,
/// summed across all active, non-loopback interfaces.
public struct NetworkByteCounts: Equatable {
    public let bytesReceived: UInt64
    public let bytesSent: UInt64
    public let interfaceNames: [String]
    public let timestamp: Date

    public init(bytesReceived: UInt64, bytesSent: UInt64, interfaceNames: [String], timestamp: Date) {
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.interfaceNames = interfaceNames
        self.timestamp = timestamp
    }
}
