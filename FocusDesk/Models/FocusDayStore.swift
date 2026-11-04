import Foundation

struct AppTimeRow: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let seconds: Int

    var formatted: String {
        let m = seconds / 60
        let s = seconds % 60
        if m >= 60 {
            return String(format: "%dh %02dm", m / 60, m % 60)
        }
        return String(format: "%d:%02d", m, s)
    }
}

/// Persists today's per-app focus / distraction seconds.
@MainActor
final class FocusDayStore: ObservableObject {
    @Published private(set) var focusByApp: [String: Int] = [:]
    @Published private(set) var distractedByApp: [String: Int] = [:]
    @Published private(set) var totalFocusSeconds: Int = 0
    @Published private(set) var totalDistractedSeconds: Int = 0

    private var day: String

    init() {
        day = Self.dayKey()
        load()
    }

    var topFocusApps: [AppTimeRow] {
        focusByApp
            .map { AppTimeRow(name: $0.key, seconds: $0.value) }
            .sorted { $0.seconds > $1.seconds }
    }

    var topDistractedApps: [AppTimeRow] {
        distractedByApp
            .map { AppTimeRow(name: $0.key, seconds: $0.value) }
            .sorted { $0.seconds > $1.seconds }
    }

    func creditFocus(app: String) {
        rollIfNeeded()
        guard !app.isEmpty, app != "—" else { return }
        focusByApp[app, default: 0] += 1
        totalFocusSeconds += 1
        persist()
    }

    func creditDistracted(app: String) {
        rollIfNeeded()
        guard !app.isEmpty, app != "—" else { return }
        distractedByApp[app, default: 0] += 1
        totalDistractedSeconds += 1
        persist()
    }

    private func rollIfNeeded() {
        let today = Self.dayKey()
        guard today != day else { return }
        day = today
        focusByApp = [:]
        distractedByApp = [:]
        totalFocusSeconds = 0
        totalDistractedSeconds = 0
        persist()
    }

    private func load() {
        let defaults = UserDefaults.standard
        let storedDay = defaults.string(forKey: "statsDay") ?? day
        if storedDay != Self.dayKey() {
            day = Self.dayKey()
            focusByApp = [:]
            distractedByApp = [:]
            totalFocusSeconds = 0
            totalDistractedSeconds = 0
            persist()
            return
        }
        day = storedDay
        focusByApp = defaults.dictionary(forKey: "focusByApp") as? [String: Int] ?? [:]
        distractedByApp = defaults.dictionary(forKey: "distractedByApp") as? [String: Int] ?? [:]
        totalFocusSeconds = defaults.integer(forKey: "totalFocusSeconds")
        totalDistractedSeconds = defaults.integer(forKey: "totalDistractedSeconds")
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(day, forKey: "statsDay")
        defaults.set(focusByApp, forKey: "focusByApp")
        defaults.set(distractedByApp, forKey: "distractedByApp")
        defaults.set(totalFocusSeconds, forKey: "totalFocusSeconds")
        defaults.set(totalDistractedSeconds, forKey: "totalDistractedSeconds")
    }

    private static func dayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
