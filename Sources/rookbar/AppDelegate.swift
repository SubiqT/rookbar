import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let models = BarModels()
    private var panel: BarPanel?
    private var statusMenu: StatusMenu?
    private var terminationSources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateGracefully(on: [SIGTERM, SIGINT])
        models.start()
        statusMenu = StatusMenu()

        let panel = BarPanel(rootView: BarView(models: models))
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

    func applicationWillTerminate(_ notification: Notification) {
        models.stop()
    }

    /// launchd stops the service with SIGTERM, which would otherwise skip `applicationWillTerminate`.
    private func terminateGracefully(on signals: [Int32]) {
        for signalNumber in signals {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { NSApp.terminate(nil) }
            source.resume()
            terminationSources.append(source)
        }
    }
}
