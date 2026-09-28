import Foundation
import Testing
@testable import RookbarCore

@Suite struct ClockTextTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Warsaw")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test func formatsDateWithOrdinalAndTimeWithLeadingZeros() {
        let moment = date(2025, 11, 18, 9, 5)
        #expect(ClockText.date(moment, calendar: calendar) == "Tue 18th Nov at")
        #expect(ClockText.time(moment, calendar: calendar) == "09:05")
    }

    @Test(arguments: [(1, "st"), (2, "nd"), (3, "rd"), (4, "th"), (11, "th"), (12, "th"), (13, "th"),
                      (21, "st"), (22, "nd"), (23, "rd"), (31, "st")])
    func ordinalSuffixes(day: Int, suffix: String) {
        #expect(ClockText.ordinalSuffix(day) == suffix)
    }

    @Test func nextMinuteDelayLandsOnTheBoundary() {
        let moment = date(2025, 11, 18, 9, 5, 45)
        #expect(abs(ClockText.delayUntilNextMinute(from: moment, calendar: calendar) - 15) < 0.001)
    }
}
