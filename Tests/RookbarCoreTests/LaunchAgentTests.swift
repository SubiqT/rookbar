import Foundation
import Testing
@testable import RookbarCore

@Suite struct LaunchAgentTests {
    @Test func plistRunsTheExecutableAndRestartsOnlyAfterCrashes() throws {
        let data = try LaunchAgent.plist(executablePath: "/Applications/rookbar.app/Contents/MacOS/rookbar")
        let plist = try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        #expect(plist["Label"] as? String == "com.rookbar")
        #expect(plist["ProgramArguments"] as? [String] == ["/Applications/rookbar.app/Contents/MacOS/rookbar"])
        #expect(plist["RunAtLoad"] as? Bool == true)
        #expect((plist["KeepAlive"] as? [String: Bool])?["SuccessfulExit"] == false)
    }
}
