import Foundation

/// Holds an exclusive `flock` for the life of the process; the kernel releases it on exit or crash.
public final class InstanceLock {
    public static var defaultPath: String {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("rookbar/rookbar.lock").path
    }

    private let descriptor: Int32

    /// Returns nil if another process holds the lock after `timeout` seconds.
    public init?(path: String, timeout: TimeInterval = 0) {
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        let descriptor = open(path, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else { return nil }

        let deadline = Date().addingTimeInterval(timeout)
        while flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
            guard Date() < deadline else {
                close(descriptor)
                return nil
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        self.descriptor = descriptor

        let pid = Array("\(getpid())\n".utf8)
        ftruncate(descriptor, 0)
        _ = pid.withUnsafeBufferPointer { pwrite(descriptor, $0.baseAddress, $0.count, 0) }
    }

    deinit {
        close(descriptor)
    }
}
