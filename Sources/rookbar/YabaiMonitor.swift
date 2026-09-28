import AppKit
import Observation
import notify
import RookbarCore

/// Mirrors the yabai state the bar displays, refreshed on yabai signals, workspace notifications
/// and a slow poll that catches layout changes, which yabai does not signal.
@MainActor
@Observable
final class YabaiMonitor {
    private(set) var spaces: [SpaceIndicator] = []
    private(set) var focusedApp: FocusedApp?
    private(set) var layout = "bsp"
    private(set) var isAvailable = false

    @ObservationIgnored private let client = YabaiClient()
    @ObservationIgnored private let queue = DispatchQueue(label: "rookbar.yabai", qos: .userInitiated)
    @ObservationIgnored private var notifyToken: Int32?
    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private var needsRefresh = false
    @ObservationIgnored private var workspaceObservers: [NSObjectProtocol] = []

    func start() {
        let client = client
        queue.async { YabaiSignals.register(with: client) }

        var token: Int32 = 0
        let status = notify_register_dispatch(YabaiSignals.notificationName, &token, DispatchQueue.main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        if status == NOTIFY_STATUS_OK { notifyToken = token }

        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        pollTimer?.tolerance = 0.25
        refresh()
    }

    func stop() {
        pollTimer?.invalidate()
        if let notifyToken { notify_cancel(notifyToken) }
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers.removeAll()
        let client = client
        queue.sync { YabaiSignals.unregister(with: client) }
    }

    func focusSpace(_ index: Int) {
        let client = client
        queue.async {
            _ = try? client.send(["space", "--focus", String(index)])
        }
    }

    /// Collapses bursts of signals into at most one query in flight plus one queued behind it.
    func refresh() {
        guard !isRefreshing else {
            needsRefresh = true
            return
        }
        isRefreshing = true
        let client = client
        queue.async { [weak self] in
            let snapshot = Snapshot.load(from: client)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.apply(snapshot)
                    self.isRefreshing = false
                    if self.needsRefresh {
                        self.needsRefresh = false
                        self.refresh()
                    }
                }
            }
        }
    }

    private func apply(_ snapshot: Snapshot?) {
        guard let snapshot else {
            if isAvailable { isAvailable = false }
            return
        }
        if !isAvailable { isAvailable = true }
        if spaces != snapshot.spaces { spaces = snapshot.spaces }
        if focusedApp != snapshot.focusedApp { focusedApp = snapshot.focusedApp }
        if layout != snapshot.layout { layout = snapshot.layout }
    }

    private struct Snapshot: Sendable {
        let spaces: [SpaceIndicator]
        let focusedApp: FocusedApp
        let layout: String

        static func load(from client: YabaiClient) -> Snapshot? {
            guard let spaces = try? client.query([YabaiSpace].self, ["--spaces"]) else { return nil }
            let focusedSpace = spaces.first(where: \.hasFocus)
            let focusedWindow = try? client.query(YabaiWindow.self, ["--windows", "--window"])
            return Snapshot(
                spaces: spaces.map(SpaceIndicator.init),
                focusedApp: FocusedApp.resolve(focusedSpace: focusedSpace, focusedWindow: focusedWindow),
                layout: focusedSpace?.type ?? "bsp"
            )
        }
    }
}
