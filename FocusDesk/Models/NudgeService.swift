import AppKit
import AVFoundation
import Foundation
import UserNotifications

enum NotificationAuthStatus: String {
    case notDetermined
    case denied
    case authorized
    case provisional
    case unknown

    @MainActor
    var label: String {
        let L = LanguageStore.shared
        switch self {
        case .notDetermined: return L.t("settings.auth_not_asked")
        case .denied: return L.t("settings.auth_denied")
        case .authorized, .provisional: return L.t("settings.auth_allowed")
        case .unknown: return L.t("settings.auth_unknown")
        }
    }

    var isGranted: Bool {
        self == .authorized || self == .provisional
    }
}

/// Away reminder: after your chosen idle minutes, play a sound (and optional banner).
/// Works while DeskCat is running in the background — menu bar popover does not need to be open.
@MainActor
final class NudgeService: ObservableObject {
    @Published private(set) var authStatus: NotificationAuthStatus = .unknown
    @Published private(set) var snoozedUntil: Date?

    private var didNudgeThisAway = false
    /// Retained for the duration of playback (AVAudioPlayer + NSSound fallback).
    private var audioPlayer: AVAudioPlayer?
    private var playingSound: NSSound?

    var isSnoozing: Bool {
        guard let snoozedUntil else { return false }
        return snoozedUntil > Date()
    }

    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .notDetermined: self.authStatus = .notDetermined
                case .denied: self.authStatus = .denied
                case .authorized: self.authStatus = .authorized
                case .provisional: self.authStatus = .provisional
                @unknown default: self.authStatus = .unknown
                }
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            Task { @MainActor in
                self.refreshAuthStatus()
            }
        }
    }

    func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    func snooze(minutes: Int) {
        snoozedUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        UserDefaults.standard.set(snoozedUntil?.timeIntervalSince1970, forKey: "snoozedUntil")
        didNudgeThisAway = true
    }

    func clearSnooze() {
        snoozedUntil = nil
        UserDefaults.standard.removeObject(forKey: "snoozedUntil")
    }

    func restoreSnoozeFromDefaults() {
        let raw = UserDefaults.standard.double(forKey: "snoozedUntil")
        guard raw > 0 else { return }
        let date = Date(timeIntervalSince1970: raw)
        if date > Date() {
            snoozedUntil = date
        } else {
            UserDefaults.standard.removeObject(forKey: "snoozedUntil")
        }
    }

    /// Once per away stretch, when idle ≥ threshold. Skipped while snoozed.
    func evaluate(
        idleSeconds: CFTimeInterval,
        thresholdSeconds: Double,
        notificationsEnabled: Bool,
        soundEnabled: Bool,
        isMonitoring: Bool
    ) {
        guard isMonitoring else {
            didNudgeThisAway = false
            return
        }

        if let snoozedUntil, snoozedUntil > Date() {
            return
        }
        if snoozedUntil != nil, snoozedUntil! <= Date() {
            clearSnooze()
        }

        // Back at the keyboard → allow a future nudge.
        if idleSeconds < 8 {
            didNudgeThisAway = false
            return
        }

        guard idleSeconds >= thresholdSeconds, !didNudgeThisAway else { return }
        didNudgeThisAway = true

        if soundEnabled {
            playMeow()
        }

        if notificationsEnabled, authStatus.isGranted {
            postNotification(idleSeconds: Int(idleSeconds))
        }
    }

    private func playMeow() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingSound?.stop()
        playingSound = nil

        guard let url = Bundle.main.url(forResource: "meow", withExtension: "wav") else {
            NSLog("DeskCat: meow.wav missing from bundle")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()
            audioPlayer = player
            player.play()
        } catch {
            // Rare fallback — still the real wav, never a system chime.
            if let sound = NSSound(contentsOf: url, byReference: false) {
                sound.volume = 1.0
                playingSound = sound
                sound.play()
            } else {
                NSLog("DeskCat: failed to play meow — \(error.localizedDescription)")
            }
        }
    }

    private func postNotification(idleSeconds: Int) {
        let L = LanguageStore.shared
        let content = UNMutableNotificationContent()
        content.title = L.t("notif.title")
        let mins = max(1, idleSeconds / 60)
        content.body = idleSeconds < 90
            ? L.t("notif.body_minute")
            : L.t("notif.body_minutes", mins)
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "deskcat.away.\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
