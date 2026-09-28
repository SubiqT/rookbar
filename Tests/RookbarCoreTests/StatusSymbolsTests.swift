import Testing
@testable import RookbarCore

@Suite struct StatusSymbolsTests {
    @Test func batteryOnACShowsChargingRegardlessOfLevel() {
        #expect(StatusSymbols.battery(level: 5, isOnAC: true) == "battery.100percent.bolt")
        #expect(StatusSymbols.battery(level: 100, isOnAC: true) == "battery.100percent.bolt")
    }

    @Test func batteryIconDropsWithLevel() {
        let levels = [100, 75, 45, 15, 5].map { StatusSymbols.battery(level: $0, isOnAC: false) }
        #expect(levels == [
            "battery.100percent", "battery.75percent", "battery.50percent", "battery.25percent", "battery.0percent",
        ])
    }

    @Test func batteryTintWarnsBelowHalfAndIsCriticalBelowFifth() {
        #expect(StatusSymbols.batteryTint(level: 50) == .normal)
        #expect(StatusSymbols.batteryTint(level: 49) == .warning)
        #expect(StatusSymbols.batteryTint(level: 19) == .critical)
    }

    @Test func mutedOrSilentVolumeShowsSlash() {
        #expect(StatusSymbols.volume(level: 60, isMuted: true) == "speaker.slash.fill")
        #expect(StatusSymbols.volume(level: 0, isMuted: false) == "speaker.slash.fill")
        #expect(StatusSymbols.volume(level: 6, isMuted: false) == "speaker.wave.1.fill")
        #expect(StatusSymbols.volume(level: 90, isMuted: false) == "speaker.wave.3.fill")
    }
}
