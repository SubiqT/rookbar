import AppKit
import RookbarCore
import SwiftUI

struct FocusedAppView: View {
    let app: FocusedApp?

    var body: some View {
        let app = app ?? FocusedApp(name: "Loading...", pid: nil)
        ZStack {
            HStack(spacing: 6) {
                AppIcon(pid: app.pid)
                    .frame(width: 16, height: 16)
                Text(app.name)
                    .font(Theme.font(size: 12))
                    .foregroundStyle(Theme.foreground.opacity(0.7))
                    .lineLimit(1)
            }
            .id(app)
            .transition(.opacity)
        }
        .padding(.horizontal, 8)
        .frame(height: Theme.itemHeight)
        .animation(.easeInOut(duration: 0.15), value: app)
    }
}

private struct AppIcon: View {
    let pid: Int32?

    var body: some View {
        if let pid, let icon = AppIconCache.icon(for: pid) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.comment.opacity(0.3))
        }
    }
}

@MainActor
enum AppIconCache {
    private static var icons: [String: NSImage] = [:]

    static func icon(for pid: Int32) -> NSImage? {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        let key = app.bundleIdentifier ?? app.bundleURL?.path ?? String(pid)
        if let cached = icons[key] { return cached }
        guard let icon = app.icon else { return nil }
        icons[key] = icon
        return icon
    }
}
