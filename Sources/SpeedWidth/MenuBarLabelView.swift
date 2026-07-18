import SwiftUI
import SpeedWidthCore

/// The compact, single-line status item content: `↑ 1.2 MB/s   ↓ 3.4 MB/s`.
struct MenuBarLabelView: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                Text(ByteRateFormatter.string(fromBytesPerSecond: monitor.uploadBytesPerSec))
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                Text(ByteRateFormatter.string(fromBytesPerSecond: monitor.downloadBytesPerSec))
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .onAppear { monitor.start() }
    }
}
