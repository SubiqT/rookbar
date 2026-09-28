import Foundation
import Testing
@testable import RookbarCore

@Suite struct SpaceAppsTests {
    private func space(_ index: Int, windows: [Int], focused: Bool = false) -> YabaiSpace {
        let json = #"{"index":\#(index),"type":"bsp","display":1,"windows":\#(windows),"has-focus":\#(focused)}"#
        return try! JSONDecoder().decode(YabaiSpace.self, from: Data(json.utf8))
    }

    private func window(_ id: Int, pid: Int32, app: String, space: Int, minimized: Bool = false, hidden: Bool = false) -> YabaiWindow {
        let json = """
            {"id":\(id),"pid":\(pid),"app":"\(app)","space":\(space),"has-focus":false,
             "is-minimized":\(minimized),"is-hidden":\(hidden)}
            """
        return try! JSONDecoder().decode(YabaiWindow.self, from: Data(json.utf8))
    }

    @Test func appsAreListedOncePerSpaceInWindowOrder() {
        let spaces = [space(1, windows: [3, 1, 2]), space(2, windows: [])]
        let windows = [
            window(1, pid: 10, app: "Firefox", space: 1),
            window(2, pid: 20, app: "Slack", space: 1),
            window(3, pid: 20, app: "Slack", space: 1),
        ]
        let indicators = SpaceIndicator.build(spaces: spaces, windows: windows)
        #expect(indicators[0].apps == [SpaceApp(pid: 20, name: "Slack"), SpaceApp(pid: 10, name: "Firefox")])
        #expect(indicators[1].apps.isEmpty && !indicators[1].isOccupied)
    }

    @Test func minimisedAndHiddenWindowsAreLeftOutButStillCountAsOccupied() {
        let spaces = [space(1, windows: [1, 2])]
        let windows = [
            window(1, pid: 10, app: "Firefox", space: 1, minimized: true),
            window(2, pid: 20, app: "Slack", space: 1, hidden: true),
        ]
        let indicator = SpaceIndicator.build(spaces: spaces, windows: windows)[0]
        #expect(indicator.apps.isEmpty)
        #expect(indicator.isOccupied)
    }

    @Test func overflowBadgeTakesTheLastSlot() {
        let apps = (1...5).map { SpaceApp(pid: Int32($0), name: "App\($0)") }
        let three = SpaceIndicator.visibleApps(Array(apps.prefix(3)), limit: 3)
        #expect(three.shown.count == 3 && three.overflow == 0)

        let five = SpaceIndicator.visibleApps(apps, limit: 3)
        #expect(five.shown.map(\.pid) == [1, 2])
        #expect(five.overflow == 3)
    }
}
