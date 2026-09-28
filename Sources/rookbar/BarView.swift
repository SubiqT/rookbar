import SwiftUI

/// Everything the bar observes, created once and started by the app delegate.
@MainActor
final class BarModels {
    let yabai = YabaiMonitor()
    let clock = ClockModel()
    let caffeinate = CaffeinateModel()
    let volume = VolumeModel()
    let battery = BatteryModel()
    let network = NetworkModel()
    let accent = AccentModel()

    func start() {
        yabai.start()
        clock.start()
        volume.start()
        battery.start()
        network.start()
        accent.start()
    }

    func stop() {
        yabai.stop()
    }
}

struct BarView: View {
    let models: BarModels

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SpacesView(monitor: models.yabai, accent: models.accent.color)
                Spacer(minLength: 0)
                StatusItemsView(models: models)
            }
            FocusedAppView(app: models.yabai.focusedApp)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, Theme.barPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
    }
}
