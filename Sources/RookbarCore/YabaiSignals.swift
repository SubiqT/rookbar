import Foundation

/// yabai signals that change what the bar shows. Each posts a Darwin notification, which never blocks
/// yabai even when rookbar is not running.
public enum YabaiSignals {
    public static let notificationName = "com.rookbar.yabai.changed"
    public static let labelPrefix = "rookbar_"

    public static let events = [
        "space_changed",
        "space_created",
        "space_destroyed",
        "display_changed",
        "display_added",
        "display_removed",
        "window_focused",
        "window_created",
        "window_destroyed",
        "window_moved",
        "window_minimized",
        "window_deminimized",
        "application_front_switched",
        "application_terminated",
        "application_hidden",
        "application_visible",
        "mission_control_exit",
    ]

    public static func addCommand(for event: String) -> [String] {
        [
            "signal", "--add",
            "event=\(event)",
            "label=\(labelPrefix)\(event)",
            "action=/usr/bin/notifyutil -p \(notificationName)",
        ]
    }

    public static func removeCommand(for event: String) -> [String] {
        ["signal", "--remove", "\(labelPrefix)\(event)"]
    }

    /// Re-adding a label replaces the existing signal, so registration is idempotent.
    public static func register(with client: YabaiClient) {
        for event in events {
            _ = try? client.send(addCommand(for: event))
        }
    }

    public static func unregister(with client: YabaiClient) {
        for event in events {
            _ = try? client.send(removeCommand(for: event))
        }
    }
}
