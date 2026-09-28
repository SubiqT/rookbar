import CoreText
import Foundation
import RookbarCore
import SwiftUI

enum Theme {
    static let background = Color(hex: 0x1A1B1C)
    static let foreground = Color(hex: 0xFFFFFF)
    static let red = Color(hex: 0xCC6566)
    static let yellow = Color(hex: 0xF0C674)
    static let brightGreen = Color(hex: 0xB9CA4B)
    static let comment = Color(hex: 0x666666)

    static let barPadding: CGFloat = 8
    static let itemHeight: CGFloat = 24

    static func font(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        let face: String
        switch weight {
        case .bold, .heavy, .black: face = "Bold"
        case .semibold: face = "SemiBold"
        case .medium: face = "Medium"
        default: face = "Regular"
        }
        return .custom("JetBrainsMono-\(face)", size: size)
    }

    /// Monochrome app logos from sketchybar-app-font, drawn as text so they take the surrounding colour.
    static func appGlyph(size: CGFloat) -> Font {
        .custom("sketchybar-app-font", size: size)
    }

    static let appGlyphs: AppGlyphMap = {
        guard let url = resourcesDirectory?.appendingPathComponent("AppIcons/icon_map.json"),
              let data = try? Data(contentsOf: url),
              let map = try? AppGlyphMap(iconMapJSON: data)
        else { return AppGlyphMap(ligatures: [:]) }
        return map
    }()

    /// Registers the bundled fonts for this process only, so nothing is installed system-wide.
    static func registerBundledFonts() {
        guard let directory = resourcesDirectory?.appendingPathComponent("Fonts"),
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return }
        for file in files where file.pathExtension == "ttf" {
            CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
        }
    }

    /// The app bundle's Resources, or the repository's Resources when run from `swift run`.
    static var resourcesDirectory: URL? {
        if let bundled = Bundle.main.resourceURL,
           FileManager.default.fileExists(atPath: bundled.appendingPathComponent("Fonts").path) {
            return bundled
        }
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repository.appendingPathComponent("Resources")
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
