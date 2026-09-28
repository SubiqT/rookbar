import Foundation

/// The per-user launchd agent that keeps rookbar running.
public enum LaunchAgent {
    public static let label = "com.rookbar"

    public static var plistPath: String {
        NSHomeDirectory() + "/Library/LaunchAgents/\(label).plist"
    }

    public static var serviceTarget: String {
        "gui/\(getuid())/\(label)"
    }

    /// Relaunches after a crash but not after a deliberate quit, which exits successfully.
    public static func plist(executablePath: String) throws -> Data {
        let contents: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": ["SuccessfulExit": false],
            "ProcessType": "Interactive",
            "StandardOutPath": logPath,
            "StandardErrorPath": logPath,
        ]
        return try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
    }

    public static var logPath: String {
        NSHomeDirectory() + "/Library/Logs/rookbar.log"
    }

    public static var isCurrentProcessTheService: Bool {
        ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == label
    }
}
