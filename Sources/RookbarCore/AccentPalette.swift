/// Picks the palette colour closest to the wallpaper, weighting hue so the accent keeps its character.
public struct RGB: Equatable, Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Hue in degrees, saturation and value in 0...1.
    public var hsv: (hue: Double, saturation: Double, value: Double) {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        var hue = 0.0
        if delta > 0 {
            if maximum == red {
                hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maximum == green {
                hue = 60 * ((blue - red) / delta + 2)
            } else {
                hue = 60 * ((red - green) / delta + 4)
            }
        }
        if hue < 0 { hue += 360 }
        return (hue, maximum == 0 ? 0 : delta / maximum, maximum)
    }
}

public enum AccentPalette {
    public static let defaultAccent = RGB(hex: 0xC397D8)

    public static let colors: [RGB] = [
        0xCC6566, 0xD54E53, 0xB6BD68, 0xB9CA4B, 0xF0C674, 0x82A2BE,
        0x7AA6DA, 0xB294BB, 0xC397D8, 0x8ABEB7, 0x70C0B1,
    ].map(RGB.init(hex:))

    public static func closest(to target: RGB) -> RGB {
        colors.min { distance(target, $0) < distance(target, $1) } ?? defaultAccent
    }

    static func distance(_ first: RGB, _ second: RGB) -> Double {
        let a = first.hsv
        let b = second.hsv
        let rawHue = abs(a.hue - b.hue)
        let hue = rawHue > 180 ? 360 - rawHue : rawHue
        return hue * 2 + abs(a.saturation - b.saturation) * 100 + abs(a.value - b.value) * 100
    }
}
