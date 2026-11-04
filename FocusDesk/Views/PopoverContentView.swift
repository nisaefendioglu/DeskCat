import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject private var presence: PresenceController
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 0) {
            DeskSceneView(mood: presence.mood, drift: presence.drift)
                .frame(height: showDetails ? 150 : 190)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(presence.mood.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(presence.statusLine)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(presence.focusedFormatted)
                            .font(.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(language.t("popover.focus_today"))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(6, geo.size.width * (1 - presence.drift)))
                    }
                }
                .frame(height: 5)

                if showDetails {
                    Divider().opacity(0.35)
                    FocusDetailView(dayStore: presence.dayStore)
                }

                HStack(spacing: 12) {
                    Button {
                        presence.toggleMonitoring()
                    } label: {
                        Label(
                            presence.isMonitoring ? language.t("popover.pause") : language.t("popover.resume"),
                            systemImage: presence.isMonitoring ? "pause.fill" : "play.fill"
                        )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            showDetails.toggle()
                        }
                    } label: {
                        Label(
                            showDetails ? language.t("popover.hide") : language.t("popover.details"),
                            systemImage: showDetails ? "chevron.up" : "list.bullet.rectangle"
                        )
                    }

                    Spacer(minLength: 0)

                    if presence.mood == .sleeping || presence.nudge.isSnoozing {
                        Button(language.t("popover.snooze")) {
                            presence.snoozeReminders()
                        }
                        .help(language.t("popover.snooze_help", presence.snoozeMinutes))
                    }

                    Button {
                        NotificationCenter.default.post(name: .deskcatOpenSettings, object: nil)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help(language.t("app.settings"))
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(theme.colorScheme)
        .id("\(language.code)-\(theme.preference.rawValue)")
    }

    private var barColor: Color {
        switch presence.mood {
        case .focusing: Color(red: 0.45, green: 0.72, blue: 0.88)
        case .slowing: Color(red: 0.70, green: 0.72, blue: 0.55)
        case .drowsy: Color(red: 0.90, green: 0.65, blue: 0.45)
        case .sleeping: Color(red: 0.55, green: 0.55, blue: 0.65)
        }
    }
}
