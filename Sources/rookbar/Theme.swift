import SwiftUI

enum Theme {
    static let background = Color(hex: 0x1A1B1C)
    static let foreground = Color(hex: 0xFFFFFF)
    static let red = Color(hex: 0xCC6566)
    static let yellow = Color(hex: 0xF0C674)
    static let brightGreen = Color(hex: 0xB9CA4B)
    static let brightMagenta = Color(hex: 0xC397D8)
    static let comment = Color(hex: 0x666666)

    static let barPadding: CGFloat = 8
    static let itemHeight: CGFloat = 24
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
