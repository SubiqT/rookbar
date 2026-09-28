import AppKit
import Observation
import RookbarCore
import SwiftUI

/// The focused-space accent, matched from the primary display's wallpaper whenever the Space changes.
@MainActor
@Observable
final class AccentModel {
    private(set) var color = Color(AccentPalette.defaultAccent)

    @ObservationIgnored private var cache: [String: RGB] = [:]
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private let queue = DispatchQueue(label: "rookbar.wallpaper", qos: .utility)

    func start() {
        update()
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
    }

    private func update() {
        guard let screen = NSScreen.screens.first,
              let url = NSWorkspace.shared.desktopImageURL(for: screen)
        else { return }

        let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        let key = "\(url.path)|\(modified?.timeIntervalSince1970 ?? 0)"
        if let cached = cache[key] {
            apply(cached)
            return
        }

        queue.async { [weak self] in
            guard let average = Self.averageColor(of: url) else { return }
            let accent = AccentPalette.closest(to: average)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.cache[key] = accent
                    self?.apply(accent)
                }
            }
        }
    }

    private func apply(_ accent: RGB) {
        let newColor = Color(accent)
        if color != newColor { color = newColor }
    }

    /// Averages a 32x32 downsample, which is close enough to a full-image mean for picking a palette entry.
    nonisolated private static func averageColor(of url: URL) -> RGB? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 256,
              ] as CFDictionary)
        else { return nil }

        let side = 32
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return nil }

        var totals = (red: 0.0, green: 0.0, blue: 0.0)
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            totals.red += Double(pixels[offset])
            totals.green += Double(pixels[offset + 1])
            totals.blue += Double(pixels[offset + 2])
        }
        let count = Double(side * side) * 255
        return RGB(red: totals.red / count, green: totals.green / count, blue: totals.blue / count)
    }
}

extension Color {
    init(_ rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
