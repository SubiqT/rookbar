import SwiftUI

/// Everything the bar observes, created once and started by the app delegate.
@MainActor
final class BarModels {
    let yabai = YabaiMonitor()
    let clock = ClockModel()
    let caffeinate = CaffeinateModel()

    func start() {
        yabai.start()
        clock.start()
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
                SpacesView(monitor: models.yabai, accent: Theme.defaultAccent)
                Spacer(minLength: 0)
                StatusItemsView(yabai: models.yabai, clock: models.clock, caffeinate: models.caffeinate)
            }
            FocusedAppView(app: models.yabai.focusedApp)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, Theme.barPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
    }
}
