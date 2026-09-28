import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: BarPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = BarPanel(rootView: BarView())
        panel.orderFrontRegardless()
        self.panel = panel

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.panel?.positionOnPrimaryScreen() }
        }
    }
}
