import Foundation
import Darwin

/// Abstracts "read current cumulative network byte counters" so
/// `NetworkMonitor` can be driven by a real syscall-backed sampler in
/// production and by a scripted fake in tests.
public protocol InterfaceSampling {
    func sampleCounts(at timestamp: Date) -> NetworkByteCounts
}

/// Reads cumulative rx/tx byte counters via `getifaddrs()`, summing across
/// every active (`IFF_UP` + `IFF_RUNNING`), non-loopback interface. This is
/// the same BSD API used by Activity Monitor and menu bar tools like Stats.
public struct GetifaddrsInterfaceSampler: InterfaceSampling {
    public init() {}

    public func sampleCounts(at timestamp: Date) -> NetworkByteCounts {
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0
        var names: Set<String> = []

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return NetworkByteCounts(bytesReceived: 0, bytesSent: 0, interfaceNames: [], timestamp: timestamp)
        }
        defer { freeifaddrs(ifaddrPtr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = pointer {
            defer { pointer = addr.pointee.ifa_next }

            let flags = Int32(addr.pointee.ifa_flags)
            guard flags & IFF_UP != 0,
                  flags & IFF_RUNNING != 0,
                  flags & IFF_LOOPBACK == 0 else {
                continue
            }

            guard let ifaAddr = addr.pointee.ifa_addr,
                  ifaAddr.pointee.sa_family == UInt8(AF_LINK),
                  let dataPtr = addr.pointee.ifa_data else {
                continue
            }

            let networkData = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            totalReceived += UInt64(networkData.ifi_ibytes)
            totalSent += UInt64(networkData.ifi_obytes)
            names.insert(String(cString: addr.pointee.ifa_name))
        }

        return NetworkByteCounts(
            bytesReceived: totalReceived,
            bytesSent: totalSent,
            interfaceNames: names.sorted(),
            timestamp: timestamp
        )
    }
}
