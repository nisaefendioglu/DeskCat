import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case turkish

    var id: String { rawValue }

    var pickerLabelKey: String {
        switch self {
        case .system: "lang.system"
        case .english: "lang.english"
        case .turkish: "lang.turkish"
        }
    }
}

/// Locale-aware copy. System → Turkish if device language is TR, otherwise English.
/// Settings can override to English / Turkish.
@MainActor
final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    @Published var preference: AppLanguage {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: "appLanguage") }
    }

    /// Effective language code used for copy: "tr" or "en".
    var code: String {
        switch preference {
        case .english: return "en"
        case .turkish: return "tr"
        case .system:
            let id = Locale.current.language.languageCode?.identifier ?? "en"
            return id == "tr" ? "tr" : "en"
        }
    }

    var isTurkish: Bool { code == "tr" }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "appLanguage"),
           let pref = AppLanguage(rawValue: raw) {
            preference = pref
        } else {
            preference = .system
        }
    }

    func t(_ key: String) -> String {
        let table = isTurkish ? Self.tr : Self.en
        return table[key] ?? Self.en[key] ?? key
    }

    func t(_ key: String, _ args: CVarArg...) -> String {
        let format = t(key)
        switch args.count {
        case 0: return format
        case 1: return String(format: format, args[0])
        case 2: return String(format: format, args[0], args[1])
        case 3: return String(format: format, args[0], args[1], args[2])
        default: return String(format: format, arguments: args)
        }
    }

    func minutesLabel(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        if s == 0 {
            return t("time.minutes_only", m)
        }
        return t("time.minutes_seconds", m, s)
    }

    func shortDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return t("time.seconds_short", seconds)
        }
        return minutesLabel(Double(seconds))
    }

    // MARK: - Dictionaries

    private static let en: [String: String] = [
        "lang.system": "System",
        "lang.english": "English",
        "lang.turkish": "Turkish",
        "lang.section": "Language",
        "lang.subtitle": "System follows your Mac language. Turkish Macs default to Turkish.",

        "theme.section": "Appearance",
        "theme.system": "System",
        "theme.light": "Light",
        "theme.dark": "Dark",
        "theme.subtitle": "Applies to Settings and the menu popover frame around Pip. System follows macOS Light/Dark.",

        "app.settings": "Settings",
        "mood.focusing": "In the zone",
        "mood.slowing": "Drifting",
        "mood.drowsy": "Nodding off",
        "mood.sleeping": "Asleep on the desk",

        "status.paused": "Paused — Pip is offline",
        "status.snoozed": "Snoozed · reminders paused",
        "status.distracted": "Distracted · %@",
        "status.away": "Away · no input for %@",
        "status.cooling": "Cooling down · %@",
        "status.present": "Present · %@",

        "popover.focus_today": "focus today",
        "popover.pause": "Pause",
        "popover.resume": "Resume",
        "popover.details": "Details",
        "popover.hide": "Hide",
        "popover.snooze": "Snooze",
        "popover.snooze_help": "Silence meow for %d min",

        "detail.empty": "Keep working — Pip will log where your focus goes today.",
        "detail.focus": "Focus",
        "detail.distracted": "Distracted",
        "detail.focused_on": "Focused on",
        "detail.distracted_by": "Distracted by",

        "settings.pip_sleep": "Pip sleep",
        "settings.pip_sleep_slider": "Lies down after %@ without keyboard/mouse",
        "settings.pip_sleep_note": "Visual only — Pip’s mood on the desk.",
        "settings.away": "Away meow",
        "settings.nudge_explainer": "When you’re idle for %@, Pip meows once (even if the menu is closed). Optional banner if notifications are allowed.",
        "settings.meow_once_note": "Not every minute: one meow per away stretch. Pip meows again only after you return to the keyboard, then leave again.",
        "settings.play_meow": "Play meow",
        "settings.play_meow_sub": "One meow when idle hits your set time — not repeating every minute.",
        "settings.show_notification": "Also show notification",
        "settings.meow_after": "Meow after %@ idle",
        "settings.snooze_length": "Snooze length",
        "settings.snooze_explainer": "“Remind later” pauses meows for the snooze length (e.g. 10 min) — handy when you’re intentionally away.",
        "settings.remind_later": "Remind later",
        "settings.snoozing": "Snoozing…",
        "settings.cancel_snooze": "Cancel snooze",
        "settings.live_signals": "Live signals",
        "settings.idle": "Idle",
        "settings.frontmost": "Frontmost",
        "settings.distracting": "Distracting",
        "settings.yes": "Yes",
        "settings.no": "No",
        "settings.perm_allowed": "Permission: Allowed",
        "settings.perm_blocked": "Permission: Blocked — open System Settings",
        "settings.perm_not_asked": "Permission: Not asked yet — tap Allow",
        "settings.perm_checking": "Permission: Checking…",
        "settings.auth_allowed": "Allowed",
        "settings.auth_denied": "Blocked in System Settings",
        "settings.auth_not_asked": "Not asked yet",
        "settings.auth_unknown": "Unknown",
        "settings.allow": "Allow",
        "settings.system_settings": "System Settings",
        "settings.refresh": "Refresh",

        "time.minutes_only": "%d min",
        "time.minutes_seconds": "%d min %ds",
        "time.seconds_short": "%ds",
        "time.min_5": "5 min",
        "time.min_10": "10 min",
        "time.min_15": "15 min",
        "time.min_30": "30 min",

        "notif.title": "Pip meowed",
        "notif.body_minute": "You’ve been away about a minute. Pip wants you back.",
        "notif.body_minutes": "No input for about %d min. Pip dozed off — come back when you’re ready.",

        "tooltip.base": "DeskCat — Pip",
        "tooltip.mood": "DeskCat — %@",
    ]

    private static let tr: [String: String] = [
        "lang.system": "Sistem",
        "lang.english": "İngilizce",
        "lang.turkish": "Türkçe",
        "lang.section": "Dil",
        "lang.subtitle": "Sistem, Mac dilini takip eder. Türkçe Mac’te varsayılan Türkçe’dir.",

        "theme.section": "Görünüm",
        "theme.system": "Sistem",
        "theme.light": "Açık",
        "theme.dark": "Koyu",
        "theme.subtitle": "Ayarlar ve menüdeki Pip çerçevesine uygulanır. Sistem, macOS Açık/Koyu ayarını takip eder.",

        "app.settings": "Ayarlar",
        "mood.focusing": "Akıştasın",
        "mood.slowing": "Dağılıyor",
        "mood.drowsy": "Uyukluyor",
        "mood.sleeping": "Masada uyuyor",

        "status.paused": "Duraklatıldı — Pip çevrimdışı",
        "status.snoozed": "Ertelendi · hatırlatmalar kapalı",
        "status.distracted": "Dikkat dağıldı · %@",
        "status.away": "Uzakta · %@dir dokunulmadı",
        "status.cooling": "Yavaşlıyor · %@",
        "status.present": "Burada · %@",

        "popover.focus_today": "bugünkü odak",
        "popover.pause": "Duraklat",
        "popover.resume": "Devam",
        "popover.details": "Detay",
        "popover.hide": "Gizle",
        "popover.snooze": "Ertele",
        "popover.snooze_help": "Miyavı %d dk sustur",

        "detail.empty": "Çalışmaya devam — Pip bugün nereye odaklandığını kaydedecek.",
        "detail.focus": "Odak",
        "detail.distracted": "Dağınıklık",
        "detail.focused_on": "Odaklanılan",
        "detail.distracted_by": "Dikkat dağıtan",

        "settings.pip_sleep": "Pip uykusu",
        "settings.pip_sleep_slider": "Klavye/mouse olmadan %@ sonra uykuya yatar",
        "settings.pip_sleep_note": "Sadece görsel — masadaki Pip’in hali.",
        "settings.away": "Uzakta miyav",
        "settings.nudge_explainer": "%@ boyunca boşta kalırsan Pip bir kez miyavlar (menü kapalı olsa da). Bildirim izni varsa isteğe bağlı banner.",
        "settings.meow_once_note": "Her dakika değil: her uzaklaşmada yalnızca bir miyav. Tekrar miyavlaması için klavyeye dönüp sonra yeniden uzaklaşman gerekir.",
        "settings.play_meow": "Miyav çal",
        "settings.play_meow_sub": "Boşta kalma süren dolunca bir kez miyavlar — her dakika tekrar etmez.",
        "settings.show_notification": "Bildirim de göster",
        "settings.meow_after": "%@ boşta kalınca miyavla",
        "settings.snooze_length": "Erteleme süresi",
        "settings.snooze_explainer": "“Sonra hatırlat”, miyavları erteleme süresi kadar (ör. 10 dk) susturur — bilerek uzaktayken işe yarar.",
        "settings.remind_later": "Sonra hatırlat",
        "settings.snoozing": "Ertelendi…",
        "settings.cancel_snooze": "Ertelemeyi iptal et",
        "settings.live_signals": "Canlı sinyaller",
        "settings.idle": "Boşta",
        "settings.frontmost": "Öndeki uygulama",
        "settings.distracting": "Dikkat dağıtıcı",
        "settings.yes": "Evet",
        "settings.no": "Hayır",
        "settings.perm_allowed": "İzin: Verildi",
        "settings.perm_blocked": "İzin: Engelli — Sistem Ayarları’nı aç",
        "settings.perm_not_asked": "İzin: Henüz sorulmadı — İzin Ver’e bas",
        "settings.perm_checking": "İzin: Kontrol ediliyor…",
        "settings.auth_allowed": "Verildi",
        "settings.auth_denied": "Sistem Ayarları’nda engelli",
        "settings.auth_not_asked": "Henüz sorulmadı",
        "settings.auth_unknown": "Bilinmiyor",
        "settings.allow": "İzin Ver",
        "settings.system_settings": "Sistem Ayarları",
        "settings.refresh": "Yenile",

        "time.minutes_only": "%d dk",
        "time.minutes_seconds": "%d dk %dsn",
        "time.seconds_short": "%dsn",
        "time.min_5": "5 dk",
        "time.min_10": "10 dk",
        "time.min_15": "15 dk",
        "time.min_30": "30 dk",

        "notif.title": "Pip miyavladı",
        "notif.body_minute": "Yaklaşık bir dakikadır uzaktasın. Pip seni bekliyor.",
        "notif.body_minutes": "Yaklaşık %d dk dokunulmadı. Pip uyukladı — hazır olunca dön.",

        "tooltip.base": "DeskCat — Pip",
        "tooltip.mood": "DeskCat — %@",
    ]
}
