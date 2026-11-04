import SwiftUI

struct FocusDetailView: View {
    @ObservedObject var dayStore: FocusDayStore
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryRow

            if dayStore.topFocusApps.isEmpty && dayStore.topDistractedApps.isEmpty {
                Text(language.t("detail.empty"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if !dayStore.topFocusApps.isEmpty {
                    section(
                        title: language.t("detail.focused_on"),
                        rows: Array(dayStore.topFocusApps.prefix(6)),
                        tint: Color(red: 0.40, green: 0.68, blue: 0.86)
                    )
                }
                if !dayStore.topDistractedApps.isEmpty {
                    section(
                        title: language.t("detail.distracted_by"),
                        rows: Array(dayStore.topDistractedApps.prefix(4)),
                        tint: Color(red: 0.90, green: 0.58, blue: 0.42)
                    )
                }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 16) {
            metric(title: language.t("detail.focus"), value: format(dayStore.totalFocusSeconds))
            metric(title: language.t("detail.distracted"), value: format(dayStore.totalDistractedSeconds))
            Spacer(minLength: 0)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }

    private func section(title: String, rows: [AppTimeRow], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(rows) { row in
                HStack(spacing: 8) {
                    Circle()
                        .fill(tint.opacity(0.85))
                        .frame(width: 6, height: 6)
                    Text(row.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(row.formatted)
                        .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func format(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m >= 60 { return String(format: "%dh %02dm", m / 60, m % 60) }
        return String(format: "%d:%02d", m, s)
    }
}
