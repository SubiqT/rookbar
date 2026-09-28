import Foundation

public struct YabaiSpace: Decodable, Equatable, Sendable {
    public let index: Int
    public let type: String
    public let display: Int
    public let windows: [Int]
    public let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case index, type, display, windows
        case hasFocus = "has-focus"
    }
}

public struct YabaiWindow: Decodable, Equatable, Sendable {
    public let id: Int
    public let pid: Int32
    public let app: String
    public let space: Int
    public let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case id, pid, app, space
        case hasFocus = "has-focus"
    }
}

/// What the bar shows for one yabai space.
public struct SpaceIndicator: Equatable, Sendable, Identifiable {
    public let index: Int
    public let isFocused: Bool
    public let isOccupied: Bool
    public var id: Int { index }

    public init(index: Int, isFocused: Bool, isOccupied: Bool) {
        self.index = index
        self.isFocused = isFocused
        self.isOccupied = isOccupied
    }

    public init(_ space: YabaiSpace) {
        self.init(index: space.index, isFocused: space.hasFocus, isOccupied: !space.windows.isEmpty)
    }

    /// Spaces are shown in groups of three separated by a divider.
    public static func hasDivider(after position: Int, count: Int) -> Bool {
        (position + 1) % 3 == 0 && position < count - 1
    }
}

/// The application shown in the centre of the bar; nil `pid` means the focused space has no focused window.
public struct FocusedApp: Equatable, Sendable {
    public static let desktop = FocusedApp(name: "Desktop", pid: nil)

    public let name: String
    public let pid: Int32?

    public init(name: String, pid: Int32?) {
        self.name = name
        self.pid = pid
    }

    public static func resolve(focusedSpace: YabaiSpace?, focusedWindow: YabaiWindow?) -> FocusedApp {
        guard let window = focusedWindow, window.hasFocus, window.space == focusedSpace?.index else {
            return .desktop
        }
        return FocusedApp(name: window.app, pid: window.pid)
    }
}
