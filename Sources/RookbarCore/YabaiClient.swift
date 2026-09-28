import Foundation

public enum YabaiError: Error, Equatable {
    case socketUnavailable(String)
    case commandFailed(String)
}

/// Talks to yabai over its Unix socket instead of spawning a `yabai` process per query.
public struct YabaiClient: Sendable {
    public let socketPath: String

    public init(socketPath: String = YabaiClient.defaultSocketPath) {
        self.socketPath = socketPath
    }

    public static var defaultSocketPath: String {
        let user = ProcessInfo.processInfo.environment["USER"] ?? NSUserName()
        return "/tmp/yabai_\(user).socket"
    }

    /// yabai expects a little-endian Int32 length followed by NUL-terminated arguments and a final NUL.
    public static func encode(_ arguments: [String]) -> Data {
        var payload = Data()
        for argument in arguments {
            payload.append(contentsOf: Array(argument.utf8))
            payload.append(0)
        }
        payload.append(0)

        var length = Int32(payload.count).littleEndian
        var message = Data(bytes: &length, count: MemoryLayout<Int32>.size)
        message.append(payload)
        return message
    }

    /// yabai prefixes error responses with the ASCII BEL byte.
    public static func decodeResponse(_ response: Data) throws -> Data {
        if response.first == 0x07 {
            let text = String(decoding: response.dropFirst(), as: UTF8.self)
            throw YabaiError.commandFailed(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return response
    }

    /// `arguments` are what would follow `yabai -m` on the command line.
    public func send(_ arguments: [String]) throws -> Data {
        let socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketDescriptor >= 0 else { throw YabaiError.socketUnavailable(socketPath) }
        defer { close(socketDescriptor) }

        var timeout = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(socketDescriptor, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(socketDescriptor, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        var noSigPipe: Int32 = 1
        setsockopt(socketDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        guard pathBytes.count < MemoryLayout.size(ofValue: address.sun_path) else {
            throw YabaiError.socketUnavailable(socketPath)
        }
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: pathBytes)
        }
        let connected = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketDescriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard connected == 0 else { throw YabaiError.socketUnavailable(socketPath) }

        let message = Self.encode(arguments)
        let sent = message.withUnsafeBytes { Darwin.send(socketDescriptor, $0.baseAddress, message.count, 0) }
        guard sent == message.count else { throw YabaiError.socketUnavailable(socketPath) }
        shutdown(socketDescriptor, SHUT_WR)

        var response = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let received = recv(socketDescriptor, &buffer, buffer.count, 0)
            if received <= 0 { break }
            response.append(buffer, count: received)
        }
        return try Self.decodeResponse(response)
    }

    public func query<T: Decodable>(_ type: T.Type, _ arguments: [String]) throws -> T {
        try JSONDecoder().decode(T.self, from: send(["query"] + arguments))
    }
}
