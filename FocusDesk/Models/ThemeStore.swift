import AppKit
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var pickerLabelKey: String {
        switch self {
        case .system: "theme.system"
        case .light: "theme.light"
        case .dark: "theme.dark"
        }
    }
}

/// Appearance for settings + menu popover chrome. System follows macOS Light/Dark.
@MainActor
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var preference: AppAppearance {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: "appAppearance")
            applyAppKitAppearance()
        }
    }

    /// For SwiftUI `.preferredColorScheme`.
    var colorScheme: ColorScheme? {
        switch preference {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// For NSWindow / NSPopover hosting views.
    var nsAppearance: NSAppearance? {
        switch preference {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "appAppearance"),
           let pref = AppAppearance(rawValue: raw) {
            preference = pref
        } else {
            preference = .system
        }
        applyAppKitAppearance()
    }

    func applyAppKitAppearance() {
        // nil = follow system; otherwise force the chosen look app-wide for chrome.
        NSApp.appearance = nsAppearance
    }
}
