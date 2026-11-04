import AppKit
import SwiftUI

extension Notification.Name {
    static let deskcatOpenSettings = Notification.Name("deskcatOpenSettings")
}

@main
struct DeskcatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Keep Settings scene for Cmd+, / system hooks; primary open path is AppDelegate window.
        Settings {
            SettingsView()
                .environmentObject(appDelegate.presence)
                .environmentObject(appDelegate.language)
                .environmentObject(appDelegate.theme)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let presence = PresenceController()
    let language = LanguageStore.shared
    let theme = ThemeStore.shared
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var statusIconTimer: Timer?
    private var lastMenuMood: MascotMood?
    private var languageObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !ensureSingleInstance() {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        theme.applyAppKitAppearance()
        presence.stickyDeskVisible = false
        presence.start()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        let hosting = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(presence)
                .environmentObject(language)
                .environmentObject(theme)
        )
        hosting.sizingOptions = [.intrinsicContentSize]
        popover.contentViewController = hosting
        self.popover = popover

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = MenuBarPipIcon.nsImage(mood: presence.mood)
            button.imagePosition = .imageOnly
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.toolTip = language.t("tooltip.base")
        }
        self.statusItem = statusItem
        lastMenuMood = presence.mood

        statusIconTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMenuIconIfNeeded()
            }
        }
        RunLoop.main.add(statusIconTimer!, forMode: .common)

        // Refresh tooltips / popover root when language preference changes.
        languageObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.statusItem?.button?.toolTip = LanguageStore.shared.t("tooltip.base")
            }
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .deskcatOpenSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.openSettingsWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        presence.pause()
        statusIconTimer?.invalidate()
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Reliable settings open for menu-bar (.accessory) apps — SettingsLink often no-ops from popovers.
    func openSettingsWindow() {
        popover?.performClose(nil)

        if settingsWindow == nil {
            let hosting = NSHostingController(
                rootView: SettingsView()
                    .environmentObject(presence)
                    .environmentObject(language)
                    .environmentObject(theme)
            )
            let window = NSWindow(contentViewController: hosting)
            window.title = "DeskCat"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setContentSize(NSSize(width: 420, height: 660))
            window.center()
            settingsWindow = window
        }

        // Accessory apps need a brief regular policy or the window stays behind everything.
        NSApp.setActivationPolicy(.regular)
        settingsWindow?.appearance = theme.nsAppearance
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else { return }
        // Drop Dock icon again once settings is gone.
        NSApp.setActivationPolicy(.accessory)
    }

    private func refreshMenuIconIfNeeded() {
        let mood = presence.mood
        guard mood != lastMenuMood else { return }
        lastMenuMood = mood
        statusItem?.button?.image = MenuBarPipIcon.nsImage(mood: mood)
        statusItem?.button?.toolTip = language.t("tooltip.mood", mood.title)
    }

    private func ensureSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.nisaefendioglu.deskcat"
        let mine = ProcessInfo.processInfo.processIdentifier
        // Also quit legacy FocusDesk bundle if still running.
        let ids = [bundleID, "com.nisaefendioglu.focusdesk"]
        for id in ids {
            let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
                .filter { $0.processIdentifier != mine }
            for app in others {
                kill(app.processIdentifier, SIGKILL)
            }
        }
        usleep(150_000)
        return true
    }
}
