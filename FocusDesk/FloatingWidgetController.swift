import AppKit
import SwiftUI

/// Stable sticky desk panel — stays put once shown. No resize / recreate loop.
@MainActor
final class FloatingWidgetController {
    private var panel: NSPanel?
    private weak var presence: PresenceController?
    var onRequestPopover: (() -> Void)?
    var onHiddenByUser: (() -> Void)?

    private let widgetSize = NSSize(width: 220, height: 148)

    var isVisible: Bool { panel?.isVisible == true }

    func attach(presence: PresenceController) {
        self.presence = presence
    }

    func show() {
        if panel == nil {
            panel = makePanel()
            placeDefaultBottomRightIfNeeded()
        }
        guard let panel else { return }
        // Only order front — never recreate or re-animate the window.
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func setVisible(_ visible: Bool) {
        if visible { show() } else { hide() }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: widgetSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.animationBehavior = .none

        guard let presence else { return panel }

        let root = FloatingDeskWidget(
            onClose: { [weak self] in
                self?.hide()
                self?.onHiddenByUser?()
            },
            onOpenPopoverHint: { [weak self] in
                self?.onRequestPopover?()
            }
        )
        .environmentObject(presence)
        .transaction { $0.animation = nil }

        // Fixed-size hosting — intrinsic sizing was resizing the panel every mood tick.
        let hosting = NSHostingController(rootView: root)
        hosting.view.frame = NSRect(origin: .zero, size: widgetSize)
        panel.contentView = hosting.view
        panel.setContentSize(widgetSize)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak panel] _ in
            guard let panel else { return }
            UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "stickyDeskFrame")
        }

        return panel
    }

    private func placeDefaultBottomRightIfNeeded() {
        guard let panel else { return }
        if let saved = UserDefaults.standard.string(forKey: "stickyDeskFrame") {
            let rect = NSRectFromString(saved)
            if rect.width > 40, rect.height > 40,
               NSScreen.screens.contains(where: { $0.visibleFrame.intersects(rect) }) {
                panel.setFrame(NSRect(origin: rect.origin, size: widgetSize), display: false)
                return
            }
        }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.maxX - widgetSize.width - 24,
            y: visible.minY + 24
        )
        panel.setFrame(NSRect(origin: origin, size: widgetSize), display: false)
    }
}
