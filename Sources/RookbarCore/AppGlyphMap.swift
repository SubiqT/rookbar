import Foundation

/// Maps yabai app names to sketchybar-app-font ligatures such as ":firefox:".
public struct AppGlyphMap: Sendable {
    public static let fallback = ":default:"

    private let ligatures: [String: String]

    public init(ligatures: [String: String]) {
        self.ligatures = ligatures
    }

    /// Reads the font's `icon_map.json`: an array of `{"iconName": ":x:", "appNames": [...]}`.
    public init(iconMapJSON data: Data) throws {
        struct Entry: Decodable {
            let iconName: String
            let appNames: [String]
        }
        var ligatures: [String: String] = [:]
        for entry in try JSONDecoder().decode([Entry].self, from: data) {
            for name in entry.appNames where ligatures[name] == nil {
                ligatures[name] = entry.iconName
            }
        }
        self.init(ligatures: ligatures)
    }

    public func ligature(for appName: String) -> String {
        ligatures[appName] ?? Self.fallback
    }
}
