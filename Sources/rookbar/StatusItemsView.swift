import RookbarCore
import SwiftUI

struct StatusItemsView: View {
    let yabai: YabaiMonitor
    let clock: ClockModel
    let caffeinate: CaffeinateModel

    var body: some View {
        HStack(spacing: 4) {
            StatusItem { LayoutModeView(layout: yabai.layout) }
            StatusItem { CaffeinateView(model: caffeinate) }
            StatusItem { ClockView(clock: clock) }
        }
    }
}

struct StatusItem<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 4)
            .frame(height: Theme.itemHeight)
    }
}

/// An SF Symbol sized to match the Material icons jaybar used.
struct StatusIcon: View {
    let name: String
    var color: Color = Theme.foreground
    var size: CGFloat = 12

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .frame(minWidth: 16)
    }
}

struct StatusText: View {
    let text: String
    var color: Color = Theme.foreground

    var body: some View {
        Text(text)
            .font(Theme.font(size: 12))
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

private struct LayoutModeView: View {
    let layout: String

    var body: some View {
        StatusIcon(name: layout == "stack" ? "square.3.layers.3d" : "square.grid.2x2.fill", size: 13)
    }
}

private struct CaffeinateView: View {
    let model: CaffeinateModel

    var body: some View {
        StatusIcon(
            name: "cup.and.saucer.fill",
            color: model.isActive ? Theme.brightGreen : Theme.foreground.opacity(0.6)
        )
        .frame(width: 20, height: 20)
        .contentShape(Rectangle())
        .onTapGesture { model.toggle() }
    }
}

private struct ClockView: View {
    let clock: ClockModel

    var body: some View {
        HStack(spacing: 8) {
            Text(ClockText.date(clock.now))
                .font(Theme.font(size: 12))
                .foregroundStyle(Theme.foreground.opacity(0.7))
            Text(ClockText.time(clock.now))
                .font(Theme.font(size: 12, weight: .bold))
                .foregroundStyle(Theme.foreground)
        }
        .lineLimit(1)
    }
}
