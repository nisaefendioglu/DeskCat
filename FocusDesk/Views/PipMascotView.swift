import SwiftUI

/// Pip — front-facing 3D kitten. Pen keeps writing whenever focus is back.
struct PipMascotView: View {
    let mood: MascotMood

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: frameWidth, height: frameHeight)
                .id(assetName)

            if showsPen {
                // TimelineView restarts cleanly every time focus returns.
                TimelineView(.animation(minimumInterval: 0.05, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let bob = sin(t * (.pi / 0.45)) > 0
                    pen
                        .offset(x: bob ? -6 : -10, y: bob ? -18 : -24)
                        .rotationEffect(.degrees(bob ? -22 : -38))
                }
                .transition(.opacity)
            }
        }
        .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
        .animation(.easeInOut(duration: 0.2), value: showsPen)
    }

    private var showsPen: Bool {
        // Only while clearly focused — not while drifting/drowsy.
        mood == .focusing
    }

    private var assetName: String {
        switch mood {
        case .focusing, .slowing: "PipAwake"
        case .drowsy: "PipDrowsy"
        case .sleeping: "PipSleep"
        }
    }

    private var frameWidth: CGFloat { mood == .sleeping ? 118 : 92 }
    private var frameHeight: CGFloat { mood == .sleeping ? 100 : 100 }

    private var pen: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.55, blue: 0.78),
                            Color(red: 0.28, green: 0.38, blue: 0.62)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5, height: 28)
            Capsule()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.45))
                .frame(width: 5, height: 6)
            Triangle()
                .fill(Color(red: 0.35, green: 0.28, blue: 0.22))
                .frame(width: 5, height: 5)
                .offset(y: 4)
        }
        .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
