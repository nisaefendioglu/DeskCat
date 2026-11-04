import Combine
import Foundation
import SwiftUI

@MainActor
final class PresenceController: ObservableObject {
    @Published private(set) var drift: Double = 0
    @Published private(set) var isMonitoring = true
    @Published private(set) var frontmostAppName: String = "—"
    @Published private(set) var idleSeconds: Int = 0
    @Published private(set) var isDistracting = false
    @Published var stickyDeskVisible: Bool {
        didSet { UserDefaults.standard.set(stickyDeskVisible, forKey: "stickyDeskVisible") }
    }

    /// Seconds without input before Pip is fully asleep.
    @Published var idleSleepThreshold: Double {
        didSet { UserDefaults.standard.set(idleSleepThreshold, forKey: "idleSleepThreshold") }
    }

    /// Seconds without input before the away sound / banner.
    @Published var nudgeAfterSeconds: Double {
        didSet { UserDefaults.standard.set(nudgeAfterSeconds, forKey: "nudgeAfterSeconds") }
    }

    @Published var nudgesEnabled: Bool {
        didSet { UserDefaults.standard.set(nudgesEnabled, forKey: "nudgesEnabled") }
    }

    @Published var nudgeSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(nudgeSoundEnabled, forKey: "nudgeSoundEnabled") }
    }

    @Published var snoozeMinutes: Int {
        didSet { UserDefaults.standard.set(snoozeMinutes, forKey: "snoozeMinutes") }
    }

    let monitor = ActivityMonitor()
    let dayStore = FocusDayStore()
    let nudge = NudgeService()

    var onStickyVisibilityChange: ((Bool) -> Void)?

    private var tickTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    /// Published so SwiftUI / menu bar always refresh when Pip changes state.
    @Published private(set) var mood: MascotMood = .focusing
    /// Brief keyboard activity (opening the popover) shouldn't instantly snap Pip awake.
    private var consecutiveActiveTicks = 0

    /// Raw mood from idle / distraction — sleep always wins over "distracted".
    private func rawMood(idle: Int, distracting: Bool, monitoring: Bool) -> MascotMood {
        guard monitoring else { return .sleeping }

        // Sleep lines up with the away timer the user actually notices (meow),
        // while the sleep slider remains a ceiling if set higher.
        let sleepAt = max(30, min(idleSleepThreshold, max(nudgeAfterSeconds, 30)))
        if idle >= Int(sleepAt) { return .sleeping }
        if distracting { return .drowsy }
        if idle >= Int(sleepAt * 0.55) { return .drowsy }
        if idle >= Int(sleepAt * 0.22) { return .slowing }
        return .focusing
    }

    private func applyMood(_ next: MascotMood) {
        let depth: [MascotMood: Int] = [
            .focusing: 0, .slowing: 1, .drowsy: 2, .sleeping: 3
        ]
        let currentDepth = depth[mood] ?? 0
        let nextDepth = depth[next] ?? 0

        if nextDepth >= 2 {
            // Going drowsy/asleep — apply immediately.
            consecutiveActiveTicks = 0
            if mood != next { mood = next }
            return
        }

        // Waking up — require a few seconds of real activity so a glance
        // at the menu bar doesn't yank Pip out of sleep.
        if currentDepth >= 2 {
            consecutiveActiveTicks += 1
            if consecutiveActiveTicks >= 3 {
                consecutiveActiveTicks = 0
                mood = next
            }
            return
        }

        consecutiveActiveTicks = 0
        if mood != next { mood = next }
    }

    var statusLine: String {
        let L = LanguageStore.shared
        if !isMonitoring { return L.t("status.paused") }
        if nudge.isSnoozing { return L.t("status.snoozed") }
        if isDistracting { return L.t("status.distracted", frontmostAppName) }
        if mood == .sleeping {
            return L.t("status.away", formatDuration(idleSeconds))
        }
        if idleSeconds >= 20 { return L.t("status.cooling", frontmostAppName) }
        return L.t("status.present", frontmostAppName)
    }

    var focusedFormatted: String {
        formatDuration(dayStore.totalFocusSeconds)
    }

    var nudgeExplainer: String {
        let L = LanguageStore.shared
        let label = L.minutesLabel(nudgeAfterSeconds)
        return L.t("settings.nudge_explainer", label)
    }

    init() {
        // Default / migrate: Pip sleeps ~1 minute away (aligned with meow).
        let savedSleep = UserDefaults.standard.object(forKey: "idleSleepThreshold") as? Double
        if savedSleep == nil || savedSleep == 90 {
            idleSleepThreshold = 60
            UserDefaults.standard.set(60.0, forKey: "idleSleepThreshold")
        } else {
            idleSleepThreshold = savedSleep ?? 60
        }
        // Default / migrate: meow after ~1 minute away.
        let savedNudge = UserDefaults.standard.object(forKey: "nudgeAfterSeconds") as? Double
        if savedNudge == nil || savedNudge == 180 {
            nudgeAfterSeconds = 60
            UserDefaults.standard.set(60.0, forKey: "nudgeAfterSeconds")
        } else {
            nudgeAfterSeconds = savedNudge ?? 60
        }
        nudgesEnabled = UserDefaults.standard.object(forKey: "nudgesEnabled") as? Bool ?? true
        nudgeSoundEnabled = UserDefaults.standard.object(forKey: "nudgeSoundEnabled") as? Bool ?? true
        snoozeMinutes = UserDefaults.standard.object(forKey: "snoozeMinutes") as? Int ?? 10
        // Off by default — show from menu when you want the floating desk.
        stickyDeskVisible = UserDefaults.standard.object(forKey: "stickyDeskVisible") as? Bool ?? false

        nudge.restoreSnoozeFromDefaults()
        nudge.refreshAuthStatus()

        nudge.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snap in
                self?.frontmostAppName = snap.frontmostAppName
                self?.idleSeconds = Int(snap.idleSeconds)
                self?.isDistracting = snap.isDistracting
            }
            .store(in: &cancellables)
    }

    func start() {
        isMonitoring = true
        if nudgesEnabled { nudge.requestPermission() }
        nudge.refreshAuthStatus()
        monitor.start()
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    func pause() {
        isMonitoring = false
        monitor.stop()
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func toggleMonitoring() {
        if isMonitoring { pause() } else { start() }
    }

    func setStickyVisible(_ visible: Bool) {
        guard stickyDeskVisible != visible else { return }
        stickyDeskVisible = visible
        onStickyVisibilityChange?(visible)
    }

    func toggleSticky() {
        setStickyVisible(!stickyDeskVisible)
    }

    func snoozeReminders() {
        nudge.snooze(minutes: snoozeMinutes)
        objectWillChange.send()
    }

    func clearSnooze() {
        nudge.clearSnooze()
        objectWillChange.send()
    }

    private func tick() {
        guard isMonitoring else { return }

        // Always refresh from monitor so UI idle/mood stay in sync.
        let snap = monitor.snapshot
        let idle = snap.idleSeconds
        let distracting = snap.isDistracting
        let appName = snap.frontmostAppName

        idleSeconds = Int(idle)
        isDistracting = distracting
        frontmostAppName = appName

        let proposed = rawMood(idle: idleSeconds, distracting: distracting, monitoring: isMonitoring)
        applyMood(proposed)

        // Presence bar follows published mood (instant), not a laggy drift climb.
        let target: Double
        switch mood {
        case .focusing: target = 0.05
        case .slowing: target = 0.4
        case .drowsy: target = 0.7
        case .sleeping: target = 1.0
        }
        let step = 0.2
        if abs(drift - target) < step {
            drift = target
        } else if drift < target {
            drift = min(target, drift + step)
        } else {
            drift = max(target, drift - step)
        }

        if idle < 12 {
            if distracting {
                dayStore.creditDistracted(app: appName)
            } else {
                dayStore.creditFocus(app: appName)
            }
        }

        nudge.evaluate(
            idleSeconds: idle,
            thresholdSeconds: nudgeAfterSeconds,
            notificationsEnabled: nudgesEnabled,
            soundEnabled: nudgeSoundEnabled,
            isMonitoring: isMonitoring
        )
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m >= 60 {
            return String(format: "%dh %02dm", m / 60, m % 60)
        }
        return String(format: "%d:%02d", m, s)
    }
}
