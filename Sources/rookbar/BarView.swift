import SwiftUI

struct BarView: View {
    let yabai: YabaiMonitor

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SpacesView(monitor: yabai, accent: Theme.defaultAccent)
                Spacer(minLength: 0)
            }
            FocusedAppView(app: yabai.focusedApp)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, Theme.barPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
    }
}
