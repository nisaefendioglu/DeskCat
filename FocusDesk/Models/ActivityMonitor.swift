import AppKit
import CoreGraphics
import Foundation

/// Snapshot of what similar menu-bar trackers observe each second.
struct ActivitySnapshot: Equatable {
    var idleSeconds: CFTimeInterval
    var frontmostAppName: String
    var frontmostBundleID: String?
    var isDistracting: Bool
}

@MainActor
final class ActivityMonitor: ObservableObject {
    @Published private(set) var snapshot = ActivitySnapshot(
        idleSeconds: 0,
        frontmostAppName: "—",
        frontmostBundleID: nil,
        isDistracting: false
    )

    /// Apps that count as distraction even while the user is clicking around.
    var distractorBundleIDs: Set<String> = [
        "com.apple.TV",
        "com.netflix.Netflix",
        "com.hnc.Discord",
        "com.tinyspeck.slackmacgap",
        "com.apple.MobileSMS",
        "net.whatsapp.WhatsApp",
        "ru.keepcoder.Telegram",
        "com.apple.AppStore",
        "com.apple.Music",
        "com.apple.podcasts",
        "com.spotify.client"
    ]

    var distractorNameHints: [String] = [
        "TikTok", "YouTube", "Twitch", "Instagram",
        "Twitter", "Reddit", "Netflix", "Disney+", "Prime Video"
    ]

    private var timer: Timer?
    private var workspaceObserver: NSObjectProtocol?

    func start() {
        stop()
        refresh()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
    }

    private func refresh() {
        let idle = Self.systemIdleSeconds()
        let app = NSWorkspace.shared.frontmostApplication
        let name = app?.localizedName ?? "Unknown"
        let bundleID = app?.bundleIdentifier

        snapshot = ActivitySnapshot(
            idleSeconds: idle,
            frontmostAppName: name,
            frontmostBundleID: bundleID,
            isDistracting: isDistracting(name: name, bundleID: bundleID)
        )
    }

    private func isDistracting(name: String, bundleID: String?) -> Bool {
        if bundleID == "com.nisaefendioglu.deskcat" || bundleID == "com.nisaefendioglu.focusdesk" {
            return false
        }
        if let bundleID, distractorBundleIDs.contains(bundleID) { return true }
        let lowered = name.lowercased()
        return distractorNameHints.contains { lowered.contains($0.lowercased()) }
    }

    /// Keyboard/mouse idle for the whole Mac. No Accessibility permission needed.
    nonisolated static func systemIdleSeconds() -> CFTimeInterval {
        let types: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .keyDown, .scrollWheel, .flagsChanged
        ]
        return types
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }
}
