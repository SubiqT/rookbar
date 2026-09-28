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
    public let isMinimized: Bool
    public let isHidden: Bool

    enum CodingKeys: String, CodingKey {
        case id, pid, app, space
        case hasFocus = "has-focus"
        case isMinimized = "is-minimized"
        case isHidden = "is-hidden"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        pid = try container.decode(Int32.self, forKey: .pid)
        app = try container.decode(String.self, forKey: .app)
        space = try container.decode(Int.self, forKey: .space)
        hasFocus = try container.decodeIfPresent(Bool.self, forKey: .hasFocus) ?? false
        isMinimized = try container.decodeIfPresent(Bool.self, forKey: .isMinimized) ?? false
        isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
    }
}

/// An app with at least one visible window on a space.
public struct SpaceApp: Hashable, Sendable, Identifiable {
    public let pid: Int32
    public let name: String
    public var id: Int32 { pid }

    public init(pid: Int32, name: String) {
        self.pid = pid
        self.name = name
    }
}

/// What the bar shows for one yabai space.
public struct SpaceIndicator: Equatable, Sendable, Identifiable {
    public let index: Int
    public let isFocused: Bool
    public let isOccupied: Bool
    public let apps: [SpaceApp]
    public var id: Int { index }

    public init(index: Int, isFocused: Bool, isOccupied: Bool, apps: [SpaceApp] = []) {
        self.index = index
        self.isFocused = isFocused
        self.isOccupied = isOccupied
        self.apps = apps
    }

    public init(_ space: YabaiSpace) {
        self.init(index: space.index, isFocused: space.hasFocus, isOccupied: !space.windows.isEmpty)
    }

    /// Lists each space's apps once, in yabai's window order, skipping minimised and hidden windows.
    public static func build(spaces: [YabaiSpace], windows: [YabaiWindow]) -> [SpaceIndicator] {
        let windowsByID = Dictionary(windows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return spaces.map { space in
            var seen = Set<Int32>()
            let apps = space.windows
                .compactMap { windowsByID[$0] }
                .filter { !$0.isMinimized && !$0.isHidden }
                .compactMap { window in
                    seen.insert(window.pid).inserted ? SpaceApp(pid: window.pid, name: window.app) : nil
                }
            return SpaceIndicator(
                index: space.index,
                isFocused: space.hasFocus,
                isOccupied: !space.windows.isEmpty,
                apps: apps
            )
        }
    }

    /// Splits apps into the icons to draw and how many are left over for a "+N" badge.
    public static func visibleApps(_ apps: [SpaceApp], limit: Int) -> (shown: [SpaceApp], overflow: Int) {
        guard apps.count > limit else { return (apps, 0) }
        let shown = Array(apps.prefix(max(0, limit - 1)))
        return (shown, apps.count - shown.count)
    }

    /// Spaces are shown in groups of three separated by a divider.
    public static func hasDivider(after position: Int, count: Int) -> Bool {
        (position + 1) % 3 == 0 && position < count - 1
    }
}

/// The application shown in the centre of the bar; nil `pid` means the focused space has no focused window.
public struct FocusedApp: Hashable, Sendable {
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
