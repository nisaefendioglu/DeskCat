import SwiftUI

/// Minimal floating desk — static scene, no appear/disappear chrome animations.
struct FloatingDeskWidget: View {
    @EnvironmentObject private var presence: PresenceController
    var onClose: () -> Void
    var onOpenPopoverHint: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DeskSceneView(mood: presence.mood, drift: presence.drift)
                .frame(width: 220, height: 148)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)

            if hovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .frame(width: 220, height: 148)
        .onHover { hovering = $0 }
        .onTapGesture(count: 2, perform: onOpenPopoverHint)
        .contextMenu {
            Button("Hide sticky desk", action: onClose)
            Button("Open menu", action: onOpenPopoverHint)
        }
        .help("Drag to move · double-click opens menu")
        // Mood updates should not animate the whole widget.
        .transaction { $0.animation = nil }
    }
}
