import AppKit
import RookbarCore

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.first == "--render-preview" {
    let path = arguments.count > 1 ? arguments[1] : "rookbar-preview.png"
    let width = NSScreen.screens.first?.frame.width ?? 1728
    exit(MainActor.assumeIsolated { PreviewRenderer.render(to: path, width: width) })
}

if let status = CommandLineInterface.run(arguments) {
    exit(status)
}

guard let instanceLock = InstanceLock(path: InstanceLock.defaultPath, timeout: 2) else {
    FileHandle.standardError.write(Data("rookbar is already running\n".utf8))
    exit(0)
}

Theme.registerBundledFonts()
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
withExtendedLifetime(instanceLock) {
    app.run()
}
