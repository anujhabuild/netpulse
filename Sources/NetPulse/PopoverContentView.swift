import SwiftUI
import AppKit
import NetPulseCore

/// Detail panel shown when the menu bar item is clicked.
struct PopoverContentView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var loginManager: LaunchAtLoginManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                speedRow(label: "Upload", systemImage: "arrow.up.circle.fill", value: monitor.uploadBytesPerSec, color: .orange)
                speedRow(label: "Download", systemImage: "arrow.down.circle.fill", value: monitor.downloadBytesPerSec, color: .blue)
            }

            SpeedSparklineView(downloadHistory: monitor.downloadHistory, uploadHistory: monitor.uploadHistory)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Session total: \(ByteRateFormatter.string(fromTotalBytes: monitor.sessionTotalBytes))")
                Text("Interface: \(interfaceSummary)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { loginManager.isEnabled },
                set: { loginManager.setEnabled($0) }
            ))

            if let error = loginManager.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 240)
        // Semantic system material (not a hardcoded color) so this always
        // matches the current macOS appearance/vibrancy, light or dark.
        .background(.regularMaterial)
    }

    private var interfaceSummary: String {
        monitor.activeInterfaceNames.isEmpty ? "None" : monitor.activeInterfaceNames.joined(separator: ", ")
    }

    private func speedRow(label: String, systemImage: String, value: Double, color: Color) -> some View {
        HStack {
            Image(systemName: systemImage).foregroundStyle(color)
            Text(label)
            Spacer()
            Text(ByteRateFormatter.string(fromBytesPerSecond: value))
                .font(.system(.body, design: .monospaced))
                .bold()
        }
    }
}
