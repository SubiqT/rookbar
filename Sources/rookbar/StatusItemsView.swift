import RookbarCore
import SwiftUI

struct StatusItemsView: View {
    let models: BarModels

    var body: some View {
        HStack(spacing: 4) {
            StatusItem { LayoutModeView(layout: models.yabai.layout) }
            StatusItem { CaffeinateView(model: models.caffeinate) }
            StatusItem { VolumeView(model: models.volume) }
            if models.battery.level != nil {
                StatusItem { BatteryView(model: models.battery) }
            }
            StatusItem { NetworkView(model: models.network) }
            StatusItem { ClockView(clock: models.clock) }
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

private struct VolumeView: View {
    let model: VolumeModel

    var body: some View {
        let level = model.level ?? 0
        let color = model.isMuted ? Theme.red : Theme.foreground
        HStack(spacing: 4) {
            StatusIcon(name: StatusSymbols.volume(level: level, isMuted: model.isMuted), color: color)
            if model.isMuted {
                StatusText(text: "Muted", color: color)
            } else if let modelLevel = model.level {
                StatusText(text: "\(modelLevel)%")
            }
        }
    }
}

private struct BatteryView: View {
    let model: BatteryModel

    var body: some View {
        let level = model.level ?? 0
        let color: Color = switch StatusSymbols.batteryTint(level: level) {
        case .critical: Theme.red
        case .warning: Theme.yellow
        case .normal: Theme.foreground
        }
        HStack(spacing: 4) {
            StatusIcon(name: StatusSymbols.battery(level: level, isOnAC: model.isOnAC), color: color, size: 13)
            StatusText(text: "\(level)%", color: color)
        }
    }
}

private struct NetworkView: View {
    let model: NetworkModel
    @State private var showsName = false

    var body: some View {
        HStack(spacing: 4) {
            StatusIcon(
                name: StatusSymbols.network(model.connection),
                color: model.connection == .offline ? Theme.red : Theme.foreground
            )
            if showsName && !model.name.isEmpty {
                StatusText(text: model.name)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { showsName.toggle() }
        }
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
