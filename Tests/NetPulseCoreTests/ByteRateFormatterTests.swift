import Testing
@testable import NetPulseCore

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

    @Test func fixedWidthZeroIsZeroPadded() {
        #expect(ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 0) == "000.00 By/s")
    }

    @Test func fixedWidthSmallValueIsZeroPadded() {
        #expect(ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 9.234) == "009.23 By/s")
    }

    @Test func fixedWidthLargeValueKeepsThreeIntegerDigits() {
        #expect(ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 1024 * 512.345) == "512.35 KB/s")
    }

    @Test func fixedWidthRollsOverBeforeReachingFourDigits() {
        // Rolls to the next unit once display would need a 4th integer
        // digit (>= 1000), even though the underlying factor is /1024.
        #expect(ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 999) == "999.00 By/s")
        #expect(ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 1000) == "000.98 KB/s")
    }

    @Test func fixedWidthOutputHasConstantTotalWidth() {
        // Every tier's unit label ("By/s", "KB/s", "MB/s", "GB/s") is the
        // same 4 characters, and the number is always 6, so the total
        // rendered width never changes and the menu bar never reflows.
        let bytesTier = ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 3)
        let kilobytesTier = ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 1024 * 999.9)
        let megabytesTier = ByteRateFormatter.fixedWidthString(fromBytesPerSecond: 1024 * 1024 * 42)
        #expect(bytesTier.count == kilobytesTier.count)
        #expect(kilobytesTier.count == megabytesTier.count)
    }
}
