import RookbarCore
import SwiftUI

struct SpacesView: View {
    let monitor: YabaiMonitor
    let accent: Color

    var body: some View {
        if monitor.spaces.isEmpty {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.mini)
                    .tint(.white.opacity(0.7))
                Text(monitor.isAvailable ? "Loading spaces..." : "Waiting for yabai...")
                    .font(Theme.font(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
        } else {
            HStack(spacing: 2) {
                ForEach(monitor.spaces) { space in
                    SpaceTile(space: space, accent: accent) { monitor.focusSpace(space.index) }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

/// A space's number followed by icons for the apps on it; empty spaces show just a dimmed number.
private struct SpaceTile: View {
    static let iconLimit = 3
    static let iconStyle = AppIconStyle.current

    let space: SpaceIndicator
    let accent: Color
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var isPulsing = false

    private var numberColor: Color {
        if space.isFocused { return accent }
        return space.isOccupied ? Theme.foreground.opacity(0.75) : Theme.foreground.opacity(0.3)
    }

    private var iconColor: Color {
        space.isFocused ? accent : Theme.foreground.opacity(0.55)
    }

    var body: some View {
        let apps = SpaceIndicator.visibleApps(space.apps, limit: Self.iconLimit)
        HStack(spacing: 4) {
            Text("\(space.index)")
                .font(Theme.font(size: 11, weight: .bold))
                .foregroundStyle(numberColor)
            if !apps.shown.isEmpty || apps.overflow > 0 {
                HStack(spacing: 2) {
                    ForEach(apps.shown) { app in
                        SpaceAppMark(app: app, style: Self.iconStyle, glyphColor: iconColor)
                    }
                    if apps.overflow > 0 {
                        Text("+\(apps.overflow)")
                            .font(Theme.font(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.foreground.opacity(0.6))
                    }
                }
                .opacity(Self.iconStyle == .colour && !space.isFocused ? 0.7 : 1)
                .saturation(Self.iconStyle == .colour && !space.isFocused ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 6)
        .frame(minWidth: 22)
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(isHovered ? 0.08 : (space.isFocused ? 0.05 : 0)))
                .padding(.vertical, 4)
        }
        .overlay(alignment: .bottom) {
            if space.isFocused {
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .scaleEffect(isPulsing ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPulsing)
        .animation(.easeInOut(duration: 0.15), value: space)
        .onHover { isHovered = $0 }
        .onTapGesture {
            isPulsing = true
            onSelect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPulsing = false }
        }
        .help(space.apps.map(\.name).joined(separator: ", "))
    }
}

private struct SpaceAppMark: View {
    let app: SpaceApp
    let style: AppIconStyle
    let glyphColor: Color

    var body: some View {
        if style == .glyph {
            AppGlyph(name: app.name, color: glyphColor)
        } else {
            SpaceAppIcon(pid: app.pid)
        }
    }
}

private struct SpaceAppIcon: View {
    let pid: Int32

    var body: some View {
        if let icon = AppIconCache.icon(for: pid) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 14, height: 14)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.comment.opacity(0.5))
                .frame(width: 12, height: 12)
        }
    }
}
