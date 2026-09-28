import AppKit
import SwiftUI

/// `defaults write com.rookbar AppIconStyle colour` switches back to full-colour app icons.
enum AppIconStyle: String {
    case glyph, colour

    static let current = UserDefaults.standard.string(forKey: "AppIconStyle").flatMap(AppIconStyle.init) ?? .glyph
}

/// A monochrome app logo from sketchybar-app-font, coloured like surrounding text.
struct AppGlyph: View {
    let name: String
    let color: Color
    var size: CGFloat = 13

    var body: some View {
        Text(Theme.appGlyphs.ligature(for: name))
            .font(Theme.appGlyph(size: size))
            .foregroundStyle(color)
            // A ligature is one glyph, so any narrower proposal truncates it to nothing.
            .fixedSize()
    }
}

@MainActor
enum AppIconCache {
    private static var icons: [String: NSImage] = [:]

    static func icon(for pid: Int32) -> NSImage? {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        let key = app.bundleIdentifier ?? app.bundleURL?.path ?? String(pid)
        if let cached = icons[key] { return cached }
        guard let icon = app.icon else { return nil }
        icons[key] = icon
        return icon
    }
}
