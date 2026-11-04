import AppKit
import SwiftUI

/// Menu bar Pip uses the same 3D kitten art, scaled tiny.
struct MenuBarPipIcon {
    @MainActor
    static func nsImage(mood: MascotMood) -> NSImage {
        let name: String
        switch mood {
        case .focusing, .slowing: name = "PipAwake"
        case .drowsy: name = "PipDrowsy"
        case .sleeping: name = "PipSleep"
        }

        guard let base = NSImage(named: name) else {
            return placeholder()
        }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        base.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: base.size),
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func placeholder() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor(red: 0.96, green: 0.91, blue: 0.84, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14)).fill()
        image.unlockFocus()
        return image
    }
}
