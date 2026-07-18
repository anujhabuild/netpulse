import SwiftUI
import Charts

/// Mini live sparkline of the last ~60 seconds of upload/download speed,
/// distinguished by color.
struct SpeedSparklineView: View {
    let downloadHistory: [Double]
    let uploadHistory: [Double]

    var body: some View {
        Chart {
            ForEach(Array(downloadHistory.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Tick", index), y: .value("Down", value))
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)
            }
            ForEach(Array(uploadHistory.enumerated()), id: \.offset) { index, value in
                LineMark(x: .value("Tick", index), y: .value("Up", value))
                    .foregroundStyle(.orange)
                    .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
