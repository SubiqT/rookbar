import Foundation
import Testing
@testable import RookbarCore

@Suite struct YabaiClientTests {
    @Test func encodesLengthPrefixedNulTerminatedArguments() {
        let message = YabaiClient.encode(["query", "--spaces"])
        let payload = Array("query\0--spaces\0\0".utf8)
        let length = Int32(payload.count).littleEndian
        let expected = withUnsafeBytes(of: length) { Array($0) } + payload
        #expect(Array(message) == expected)
    }

    @Test func errorResponseThrowsWithMessage() {
        let response = Data([0x07] + Array("unknown command '--bogus'\n".utf8))
        #expect(throws: YabaiError.commandFailed("unknown command '--bogus'")) {
            try YabaiClient.decodeResponse(response)
        }
    }

    @Test func successResponseIsReturnedUnchanged() throws {
        let response = Data("[]".utf8)
        #expect(try YabaiClient.decodeResponse(response) == response)
    }

    @Test func missingSocketIsReportedAsUnavailable() {
        let client = YabaiClient(socketPath: NSTemporaryDirectory() + "missing-\(UUID().uuidString).socket")
        #expect(throws: YabaiError.self) { try client.send(["query", "--spaces"]) }
    }
}

@Suite struct YabaiModelTests {
    private let spacesJSON = """
        [{"id":1,"uuid":"","index":1,"label":"","type":"bsp","display":1,"windows":[112,4203],
          "first-window":112,"last-window":112,"has-focus":false,"is-visible":false,"is-native-fullscreen":false},
         {"id":2,"uuid":"","index":2,"label":"","type":"stack","display":1,"windows":[],
          "first-window":0,"last-window":0,"has-focus":true,"is-visible":true,"is-native-fullscreen":false}]
        """

    private func window(space: Int, hasFocus: Bool = true) -> YabaiWindow {
        let json = #"{"id":364,"pid":7767,"app":"Slack","space":\#(space),"has-focus":\#(hasFocus)}"#
        return try! JSONDecoder().decode(YabaiWindow.self, from: Data(json.utf8))
    }

    @Test func spacesBecomeIndicators() throws {
        let spaces = try JSONDecoder().decode([YabaiSpace].self, from: Data(spacesJSON.utf8))
        #expect(spaces.map(SpaceIndicator.init) == [
            SpaceIndicator(index: 1, isFocused: false, isOccupied: true),
            SpaceIndicator(index: 2, isFocused: true, isOccupied: false),
        ])
        #expect(spaces[1].type == "stack")
    }

    @Test func focusedWindowOnFocusedSpaceIsShown() throws {
        let spaces = try JSONDecoder().decode([YabaiSpace].self, from: Data(spacesJSON.utf8))
        let app = FocusedApp.resolve(focusedSpace: spaces[1], focusedWindow: window(space: 2))
        #expect(app == FocusedApp(name: "Slack", pid: 7767))
    }

    @Test func focusedWindowOnAnotherSpaceShowsDesktop() throws {
        let spaces = try JSONDecoder().decode([YabaiSpace].self, from: Data(spacesJSON.utf8))
        #expect(FocusedApp.resolve(focusedSpace: spaces[1], focusedWindow: window(space: 1)) == .desktop)
        #expect(FocusedApp.resolve(focusedSpace: spaces[1], focusedWindow: nil) == .desktop)
    }

    @Test func dividersSeparateGroupsOfThreeButNotTheEnd() {
        let dividers = (0..<9).filter { SpaceIndicator.hasDivider(after: $0, count: 9) }
        #expect(dividers == [2, 5])
        #expect(!SpaceIndicator.hasDivider(after: 2, count: 3))
    }
}
