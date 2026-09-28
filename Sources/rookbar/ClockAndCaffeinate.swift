import AppKit
import IOKit.pwr_mgt
import Observation
import RookbarCore

@MainActor
@Observable
final class ClockModel {
    private(set) var now = Date()

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    func start() {
        scheduleNextTick()
        let resync: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleNextTick() }
        }
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: resync))
        observers.append(NotificationCenter.default.addObserver(
            forName: .NSSystemClockDidChange, object: nil, queue: .main, using: resync))
        observers.append(NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main, using: resync))
    }

    private func scheduleNextTick() {
        timer?.invalidate()
        now = Date()
        timer = Timer.scheduledTimer(
            withTimeInterval: ClockText.delayUntilNextMinute(from: now),
            repeats: false
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleNextTick() }
        }
        timer?.tolerance = 0.1
    }
}

/// Keeps the display awake like `caffeinate -d` while active, without a child process.
@MainActor
@Observable
final class CaffeinateModel {
    private(set) var isActive = false

    @ObservationIgnored private var assertion: IOPMAssertionID = 0

    func toggle() {
        if isActive {
            IOPMAssertionRelease(assertion)
            isActive = false
        } else {
            let status = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "rookbar caffeinate" as CFString,
                &assertion
            )
            isActive = status == kIOReturnSuccess
        }
    }
}
