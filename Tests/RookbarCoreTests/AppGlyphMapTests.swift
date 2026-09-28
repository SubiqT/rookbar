import Foundation
import Testing
@testable import RookbarCore

@Suite struct AppGlyphMapTests {
    private let json = Data("""
        [{"iconName": ":firefox:", "appNames": ["Firefox", "Firefox Developer Edition"]},
         {"iconName": ":zoom:", "appNames": ["zoom.us", "Zoom"]},
         {"iconName": ":other_zoom:", "appNames": ["Zoom"]}]
        """.utf8)

    @Test func everyListedAppNameMapsToItsLigature() throws {
        let map = try AppGlyphMap(iconMapJSON: json)
        #expect(map.ligature(for: "Firefox") == ":firefox:")
        #expect(map.ligature(for: "Firefox Developer Edition") == ":firefox:")
        #expect(map.ligature(for: "zoom.us") == ":zoom:")
    }

    @Test func firstEntryWinsWhenAnAppNameIsListedTwice() throws {
        #expect(try AppGlyphMap(iconMapJSON: json).ligature(for: "Zoom") == ":zoom:")
    }

    @Test func unknownAppsUseTheDefaultGlyph() throws {
        #expect(try AppGlyphMap(iconMapJSON: json).ligature(for: "OpenSuperWhisper") == AppGlyphMap.fallback)
    }
}
