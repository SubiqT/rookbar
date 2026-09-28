/// Maps system readings to the SF Symbol names and colour tiers the status items show.
public enum StatusSymbols {
    public enum Tint: Equatable, Sendable {
        case normal, warning, critical
    }

    public static func battery(level: Int, isOnAC: Bool) -> String {
        if isOnAC { return "battery.100percent.bolt" }
        switch level {
        case 90...: return "battery.100percent"
        case 60..<90: return "battery.75percent"
        case 30..<60: return "battery.50percent"
        case 10..<30: return "battery.25percent"
        default: return "battery.0percent"
        }
    }

    public static func batteryTint(level: Int) -> Tint {
        if level < 20 { return .critical }
        if level < 50 { return .warning }
        return .normal
    }

    public static func volume(level: Int, isMuted: Bool) -> String {
        if isMuted || level == 0 { return "speaker.slash.fill" }
        if level < 30 { return "speaker.wave.1.fill" }
        if level < 70 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    public enum Connection: Equatable, Sendable {
        case offline, wifi, ethernet, other
    }

    public static func network(_ connection: Connection) -> String {
        switch connection {
        case .offline: return "wifi.slash"
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        }
    }
}
