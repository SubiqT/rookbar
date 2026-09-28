import AppKit
import RookbarCore

/// Menu bar item with Restart and Quit, matching jaybar's tray menu.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    override init() {
        super.init()
        item.button?.image = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "rookbar")
        item.button?.toolTip = "rookbar - Status Bar"

        let menu = NSMenu()
        let title = NSMenuItem(title: "rookbar", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        menu.addItem(makeItem("Restart rookbar", #selector(restart)))
        menu.addItem(makeItem("Quit rookbar", #selector(quit)))
        item.menu = menu
    }

    private func makeItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    /// launchd restarts the service itself; a manually started copy launches its replacement, which waits for the lock.
    @objc private func restart() {
        if LaunchAgent.isCurrentProcessTheService {
            CommandLineInterface.restartService()
            return
        }
        guard let executable = Bundle.main.executableURL else { return }
        let replacement = Process()
        replacement.executableURL = executable
        try? replacement.run()
        NSApp.terminate(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
