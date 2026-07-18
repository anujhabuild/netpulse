import Testing
import Foundation
@testable import NetPulseCore

struct SpeedCalculatorTests {
    private func counts(received: UInt64, sent: UInt64, at seconds: TimeInterval, names: [String] = ["en0"]) -> NetworkByteCounts {
        NetworkByteCounts(bytesReceived: received, bytesSent: sent, interfaceNames: names, timestamp: Date(timeIntervalSince1970: seconds))
    }

    @Test func computesRateFromDeltaOverElapsedTime() {
        let previous = counts(received: 1_000, sent: 500, at: 0)
        let current = counts(received: 3_000, sent: 1_500, at: 1)

        let rate = SpeedCalculator.computeRate(previous: previous, current: current)

        #expect(rate?.downloadBytesPerSec == 2_000)
        #expect(rate?.uploadBytesPerSec == 1_000)
    }

    @Test func dividesByElapsedSecondsWhenTickIsNotExactlyOneSecond() {
        let previous = counts(received: 0, sent: 0, at: 0)
        let current = counts(received: 4_000, sent: 2_000, at: 2)

        let rate = SpeedCalculator.computeRate(previous: previous, current: current)

        #expect(rate?.downloadBytesPerSec == 2_000)
        #expect(rate?.uploadBytesPerSec == 1_000)
    }

    @Test func returnsNilWhenElapsedTimeIsNotPositive() {
        let previous = counts(received: 0, sent: 0, at: 5)
        let sameTimestamp = counts(received: 100, sent: 100, at: 5)
        let earlierTimestamp = counts(received: 100, sent: 100, at: 4)

        #expect(SpeedCalculator.computeRate(previous: previous, current: sameTimestamp) == nil)
        #expect(SpeedCalculator.computeRate(previous: previous, current: earlierTimestamp) == nil)
    }

    @Test func suppressesSpikeWhenCountersResetAcrossSleepWake() {
        // Simulates a Wi-Fi reconnect after sleep: the interface counters
        // restart from a small value even though real elapsed time (and
        // possibly a large stale timestamp gap) is large. Naive unsigned
        // subtraction would underflow into a huge fake spike; the
        // calculator must instead report "no rate" for this tick.
        let beforeSleep = counts(received: 50_000_000, sent: 20_000_000, at: 0)
        let afterWake = counts(received: 1_000, sent: 500, at: 3_600)

        #expect(SpeedCalculator.computeRate(previous: beforeSleep, current: afterWake) == nil)
    }

    @Test func zeroDeltaProducesZeroRateNotNil() {
        let previous = counts(received: 1_000, sent: 500, at: 0)
        let current = counts(received: 1_000, sent: 500, at: 1)

        let rate = SpeedCalculator.computeRate(previous: previous, current: current)

        #expect(rate == SpeedSample.zero)
    }
}
