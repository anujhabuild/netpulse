import Testing
@testable import SpeedWidthCore

struct ByteRateFormatterTests {
    @Test func zeroIsFormattedExplicitly() {
        #expect(ByteRateFormatter.string(fromBytesPerSecond: 0) == "0 B/s")
    }

    @Test func subKilobyteStaysInBytes() {
        #expect(ByteRateFormatter.string(fromBytesPerSecond: 512) == "512 B/s")
    }

    @Test func justUnder1024StaysInBytes() {
        #expect(ByteRateFormatter.string(fromBytesPerSecond: 1023) == "1023 B/s")
    }

    @Test func exactly1024ScalesToKilobytes() {
        #expect(ByteRateFormatter.string(fromBytesPerSecond: 1024) == "1.0 KB/s")
    }

    @Test func megabyteScaleWithOneDecimal() {
        #expect(ByteRateFormatter.string(fromBytesPerSecond: 1024 * 1024 * 1.2) == "1.2 MB/s")
    }

    @Test func largeGigabyteScaleValue() {
        let gigabyteScale = 1024.0 * 1024 * 1024 * 3.4
        #expect(ByteRateFormatter.string(fromBytesPerSecond: gigabyteScale) == "3.4 GB/s")
    }

    @Test func doesNotScaleBeyondGigabytes() {
        // Caps at GB/s rather than indexing past the units table.
        let hugeValue = 1024.0 * 1024 * 1024 * 1024 * 5
        #expect(ByteRateFormatter.string(fromBytesPerSecond: hugeValue) == "5120.0 GB/s")
    }

    @Test func totalBytesFormattingDropsRateSuffix() {
        #expect(ByteRateFormatter.string(fromTotalBytes: 0) == "0 B")
        #expect(ByteRateFormatter.string(fromTotalBytes: 1024) == "1.0 KB")
        #expect(ByteRateFormatter.string(fromTotalBytes: UInt64(1024 * 1024 * 250)) == "250.0 MB")
    }
}
