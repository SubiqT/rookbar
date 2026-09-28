import Foundation
import Testing
@testable import RookbarCore

@Suite struct InstanceLockTests {
    private func temporaryLockPath() -> String {
        NSTemporaryDirectory() + "rookbar-test-\(UUID().uuidString)/rookbar.lock"
    }

    @Test func secondLockOnSamePathIsRefused() {
        let path = temporaryLockPath()
        let first = InstanceLock(path: path)
        #expect(first != nil)
        #expect(InstanceLock(path: path) == nil)
        withExtendedLifetime(first) {}
    }

    @Test func lockIsAvailableAgainAfterRelease() {
        let path = temporaryLockPath()
        var first = InstanceLock(path: path)
        #expect(first != nil)
        first = nil
        #expect(InstanceLock(path: path) != nil)
    }
}
