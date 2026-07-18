import SwiftUI
import Charts

/// Mini live sparklines of the last ~60 seconds of upload and download
/// speed. Rendered as two independently-scaled charts (rather than one
/// shared-scale overlay) so a large download spike doesn't squash the
/// upload line flat and make it invisible.
struct SpeedSparklineView: View {
    let downloadHistory: [Double]
    let uploadHistory: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            singleSparkline(title: "Upload", color: .orange, history: uploadHistory)
            singleSparkline(title: "Download", color: .blue, history: downloadHistory)
        }
    }

    private func singleSparkline(title: String, color: Color, history: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Chart {
                ForEach(Array(history.enumerated()), id: \.offset) { index, value in
                    AreaMark(x: .value("Tick", index), y: .value(title, value))
                        .foregroundStyle(color.opacity(0.15))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Tick", index), y: .value(title, value))
                        .foregroundStyle(color)
                        .interpolationMethod(.monotone)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 32)
        }
    }
}
