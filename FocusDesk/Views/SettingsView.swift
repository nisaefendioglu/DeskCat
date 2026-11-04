import SwiftUI

/// Adaptive settings — follows System / Light / Dark (ThemeStore). Semantic colors only.
struct SettingsView: View {
    @EnvironmentObject private var presence: PresenceController
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                card(title: language.t("theme.section"), accent: Accent.sky) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("", selection: $theme.preference) {
                            ForEach(AppAppearance.allCases) { mode in
                                Text(language.t(mode.pickerLabelKey)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text(language.t("theme.subtitle"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                card(title: language.t("lang.section"), accent: Accent.mint) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("", selection: $language.preference) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(language.t(lang.pickerLabelKey)).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text(language.t("lang.subtitle"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                card(title: language.t("settings.pip_sleep"), accent: Accent.lavender) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.t("settings.pip_sleep_slider", language.minutesLabel(presence.idleSleepThreshold)))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Slider(value: $presence.idleSleepThreshold, in: 60...600, step: 30)
                            .tint(Accent.lavender)
                        Text(language.t("settings.pip_sleep_note"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                card(title: language.t("settings.away"), accent: Accent.lamp) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(presence.nudgeExplainer)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        callout(
                            icon: "info.circle.fill",
                            text: language.t("settings.meow_once_note"),
                            tint: Accent.sky
                        )

                        toggleRow(
                            title: language.t("settings.play_meow"),
                            subtitle: language.t("settings.play_meow_sub"),
                            isOn: $presence.nudgeSoundEnabled
                        )

                        toggleRow(
                            title: language.t("settings.show_notification"),
                            subtitle: permissionSubtitle,
                            isOn: $presence.nudgesEnabled
                        )

                        permissionBadge

                        VStack(alignment: .leading, spacing: 8) {
                            Text(language.t("settings.meow_after", language.minutesLabel(presence.nudgeAfterSeconds)))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Slider(value: $presence.nudgeAfterSeconds, in: 30...600, step: 15)
                                .tint(Accent.lamp)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(language.t("settings.snooze_length"))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Picker("", selection: $presence.snoozeMinutes) {
                                    Text(language.t("time.min_5")).tag(5)
                                    Text(language.t("time.min_10")).tag(10)
                                    Text(language.t("time.min_15")).tag(15)
                                    Text(language.t("time.min_30")).tag(30)
                                }
                                .labelsHidden()
                                .frame(width: 110)
                            }

                            Text(language.t("settings.snooze_explainer"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 10) {
                                Button(presence.nudge.isSnoozing ? language.t("settings.snoozing") : language.t("settings.remind_later")) {
                                    presence.snoozeReminders()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Accent.peach)
                                .disabled(presence.nudge.isSnoozing)

                                if presence.nudge.isSnoozing {
                                    Button(language.t("settings.cancel_snooze")) {
                                        presence.clearSnooze()
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                card(title: language.t("settings.live_signals"), accent: Accent.mint) {
                    VStack(spacing: 8) {
                        signalRow(
                            language.t("settings.idle"),
                            language.shortDuration(presence.idleSeconds)
                        )
                        signalRow(language.t("settings.frontmost"), presence.frontmostAppName)
                        signalRow(
                            language.t("settings.distracting"),
                            presence.isDistracting ? language.t("settings.yes") : language.t("settings.no")
                        )
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 420, height: 660)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(theme.colorScheme)
        .id("\(language.code)-\(theme.preference.rawValue)")
        .onAppear { presence.nudge.refreshAuthStatus() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Accent.lamp.opacity(colorScheme == .dark ? 0.28 : 0.22))
                    .frame(width: 44, height: 44)
                Image(systemName: "cat.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Accent.lamp)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("DeskCat")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(language.t("app.settings"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    private var permissionSubtitle: String {
        switch presence.nudge.authStatus {
        case .authorized, .provisional:
            return language.t("settings.perm_allowed")
        case .denied:
            return language.t("settings.perm_blocked")
        case .notDetermined:
            return language.t("settings.perm_not_asked")
        case .unknown:
            return language.t("settings.perm_checking")
        }
    }

    private var permissionBadge: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(presence.nudge.authStatus.isGranted ? Accent.mint : Accent.peach)
                .frame(width: 8, height: 8)
            Text(presence.nudge.authStatus.label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
            if presence.nudge.authStatus == .notDetermined {
                Button(language.t("settings.allow")) { presence.nudge.requestPermission() }
                    .buttonStyle(.borderedProminent)
                    .tint(Accent.sky)
                    .controlSize(.small)
            } else if presence.nudge.authStatus == .denied {
                Button(language.t("settings.system_settings")) { presence.nudge.openSystemNotificationSettings() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button(language.t("settings.refresh")) { presence.nudge.refreshAuthStatus() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func card<Content: View>(
        title: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Capsule()
                    .fill(accent)
                    .frame(width: 3, height: 12)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(colorScheme == .dark ? 0.28 : 0.22), lineWidth: 1)
        )
    }

    private func callout(icon: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(colorScheme == .dark ? 0.14 : 0.10))
        )
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(Accent.sky)
    }

    private func signalRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06))
                )
        }
    }
}

private enum Accent {
    static let lamp = Color(red: 0.92, green: 0.62, blue: 0.22)
    static let sky = Color(red: 0.28, green: 0.58, blue: 0.82)
    static let peach = Color(red: 0.90, green: 0.48, blue: 0.32)
    static let mint = Color(red: 0.28, green: 0.66, blue: 0.52)
    static let lavender = Color(red: 0.52, green: 0.48, blue: 0.78)
}
