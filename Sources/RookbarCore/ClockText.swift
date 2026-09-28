import Foundation

/// Formats the clock as "Tue 18th Nov at" followed by "23:39".
public enum ClockText {
    public static func date(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.weekday, .day, .month], from: date)
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let day = components.day ?? 1
        let weekday = weekdays[(components.weekday ?? 1) - 1]
        let month = months[(components.month ?? 1) - 1]
        return "\(weekday) \(day)\(ordinalSuffix(day)) \(month) at"
    }

    public static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    public static func ordinalSuffix(_ day: Int) -> String {
        if (11...13).contains(day % 100) { return "th" }
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    /// Seconds until the next minute boundary, so the clock changes exactly when the minute does.
    public static func delayUntilNextMinute(from date: Date, calendar: Calendar = .current) -> TimeInterval {
        let second = calendar.component(.second, from: date)
        let fraction = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
        return max(0.05, 60 - Double(second) - fraction)
    }
}
