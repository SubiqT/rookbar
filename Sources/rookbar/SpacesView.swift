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
            HStack(spacing: 0) {
                ForEach(Array(monitor.spaces.enumerated()), id: \.element.id) { position, space in
                    SpaceDot(space: space, accent: accent) { monitor.focusSpace(space.index) }
                    if SpaceIndicator.hasDivider(after: position, count: monitor.spaces.count) {
                        Rectangle()
                            .fill(.white.opacity(0.24))
                            .frame(width: 1, height: 12)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

private struct SpaceDot: View {
    let space: SpaceIndicator
    let accent: Color
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var isPulsing = false

    private var dotColor: Color {
        if space.isFocused { return accent }
        return space.isOccupied ? Theme.foreground : Theme.foreground.opacity(0.3)
    }

    var body: some View {
        let diameter: CGFloat = space.isFocused ? 12 : 8
        ZStack(alignment: .bottom) {
            Circle()
                .fill(dotColor)
                .frame(width: diameter, height: diameter)
                .padding(.top, space.isFocused ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if space.isFocused {
                Rectangle()
                    .fill(accent)
                    .frame(height: 2)
            }
        }
        .frame(width: 24)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(isPulsing ? 1.2 : (isHovered ? 1.1 : 1.0))
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPulsing)
        .onHover { isHovered = $0 }
        .onTapGesture {
            isPulsing = true
            onSelect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPulsing = false }
        }
    }
}
