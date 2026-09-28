import SwiftUI

struct BarView: View {
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Theme.barPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
    }
}
