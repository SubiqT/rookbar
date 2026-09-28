import AppKit
import SwiftUI

/// Renders the bar with live data to a PNG, for checking the layout without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func render(to path: String, width: CGFloat) -> Int32 {
        Theme.registerBundledFonts()
        let yabai = YabaiMonitor()
        yabai.refresh()
        RunLoop.main.run(until: Date().addingTimeInterval(1))

        let renderer = ImageRenderer(
            content: BarView(yabai: yabai)
                .frame(width: width, height: BarPanel.height)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else {
            FileHandle.standardError.write(Data("failed to render preview\n".utf8))
            return 1
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print(path)
            return 0
        } catch {
            FileHandle.standardError.write(Data("failed to write \(path): \(error)\n".utf8))
            return 1
        }
    }
}
