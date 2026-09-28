import AppKit
import SwiftUI

/// A borderless panel pinned to the top of the primary display on every Space.
final class BarPanel: NSPanel {
    static let height: CGFloat = 32

    init<Content: View>(rootView: Content) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovable = false
        hidesOnDeactivate = false
        contentView = NSHostingView(rootView: rootView)
        positionOnPrimaryScreen()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func positionOnPrimaryScreen() {
        guard let screen = NSScreen.screens.first else { return }
        let frame = screen.frame
        setFrame(
            NSRect(x: frame.minX, y: frame.maxY - Self.height, width: frame.width, height: Self.height),
            display: true
        )
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
