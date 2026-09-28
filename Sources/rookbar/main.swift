import AppKit
import RookbarCore

guard let instanceLock = InstanceLock(path: InstanceLock.defaultPath, timeout: 2) else {
    FileHandle.standardError.write(Data("rookbar is already running\n".utf8))
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
withExtendedLifetime(instanceLock) {
    app.run()
}
