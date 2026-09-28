import Foundation
import RookbarCore

enum CommandLineInterface {
    static let usage = """
        rookbar - a native status bar for yabai

        Usage:
          rookbar                         Start the status bar
          rookbar --enable-service        Install and load the launch agent
          rookbar --disable-service       Unload and remove the launch agent
          rookbar --start-service         Start the launch agent
          rookbar --stop-service          Stop the launch agent
          rookbar --restart-service       Restart the launch agent
          rookbar --render-preview [PATH] Render the bar with live data to a PNG
          rookbar --help                  Show this help message
        """

    /// Returns an exit status for a CLI command, or nil when the bar itself should run.
    static func run(_ arguments: [String]) -> Int32? {
        guard let command = arguments.first else { return nil }
        switch command {
        case "--enable-service": return enableService()
        case "--disable-service": return disableService()
        case "--start-service": return launchctl(["kickstart", LaunchAgent.serviceTarget], success: "rookbar service started")
        case "--stop-service": return launchctl(["kill", "SIGTERM", LaunchAgent.serviceTarget], success: "rookbar service stopped")
        case "--restart-service": return restartService()
        case "--help", "-h":
            print(usage)
            return 0
        default:
            FileHandle.standardError.write(Data("Unknown command: \(command)\n\n\(usage)\n".utf8))
            return 64
        }
    }

    private static func enableService() -> Int32 {
        let path = LaunchAgent.plistPath
        do {
            try FileManager.default.createDirectory(
                atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            let executable = Bundle.main.executableURL?.resolvingSymlinksInPath().path ?? CommandLine.arguments[0]
            try LaunchAgent.plist(executablePath: executable).write(to: URL(fileURLWithPath: path))
        } catch {
            FileHandle.standardError.write(Data("Failed to write \(path): \(error)\n".utf8))
            return 1
        }
        _ = launchctl(["bootout", LaunchAgent.serviceTarget], quiet: true)
        return launchctl(["bootstrap", "gui/\(getuid())", path], success: "rookbar service enabled")
    }

    private static func disableService() -> Int32 {
        let path = LaunchAgent.plistPath
        guard FileManager.default.fileExists(atPath: path) else {
            print("rookbar service is not enabled")
            return 0
        }
        _ = launchctl(["bootout", LaunchAgent.serviceTarget], quiet: true)
        try? FileManager.default.removeItem(atPath: path)
        print("rookbar service disabled")
        return 0
    }

    @discardableResult
    static func restartService() -> Int32 {
        launchctl(["kickstart", "-k", LaunchAgent.serviceTarget], success: "rookbar service restarted")
    }

    @discardableResult
    static func launchctl(_ arguments: [String], success: String? = nil, quiet: Bool = false) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        if quiet {
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
        }
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            FileHandle.standardError.write(Data("Failed to run launchctl: \(error)\n".utf8))
            return 1
        }
        if process.terminationStatus == 0, let success { print(success) }
        return process.terminationStatus
    }
}
