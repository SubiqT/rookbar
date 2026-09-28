import Testing
@testable import RookbarCore

@Suite struct AccentPaletteTests {
    @Test func hsvMatchesKnownColours() {
        let red = RGB(red: 1, green: 0, blue: 0).hsv
        #expect(red.hue == 0 && red.saturation == 1 && red.value == 1)
        let blue = RGB(red: 0, green: 0, blue: 1).hsv
        #expect(blue.hue == 240)
        let magenta = RGB(red: 1, green: 0, blue: 1).hsv
        #expect(magenta.hue == 300)
    }

    @Test func paletteColourMatchesItself() {
        for colour in AccentPalette.colors {
            #expect(AccentPalette.closest(to: colour) == colour)
        }
    }

    @Test func wallpaperColourMatchesPaletteEntryOfSimilarHue() {
        let deepPurple = RGB(red: 0.35, green: 0.2, blue: 0.45)
        let match = AccentPalette.closest(to: deepPurple)
        #expect([RGB(hex: 0xB294BB), RGB(hex: 0xC397D8)].contains(match))

        let forestGreen = RGB(red: 0.2, green: 0.4, blue: 0.15)
        let greenMatch = AccentPalette.closest(to: forestGreen)
        #expect([RGB(hex: 0xB6BD68), RGB(hex: 0xB9CA4B)].contains(greenMatch))
    }
}
