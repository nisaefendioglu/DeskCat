import SwiftUI

struct DeskSceneView: View {
    let mood: MascotMood
    let drift: Double

    private var lampGlow: Double { max(0.12, 1 - drift * 0.9) }
    private var windowBrightness: Double { max(0.25, 1 - drift * 0.65) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Night room wash
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.18),
                        Color(red: 0.14, green: 0.16, blue: 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Back wall
                Rectangle()
                    .fill(Color(red: 0.16, green: 0.18, blue: 0.24))
                    .frame(height: geo.size.height * 0.62)
                    .frame(maxHeight: .infinity, alignment: .top)

                // Window
                window
                    .frame(width: geo.size.width * 0.42, height: geo.size.height * 0.32)
                    .position(x: geo.size.width * 0.72, y: geo.size.height * 0.28)
                    .opacity(windowBrightness)

                // Warm lamp pool on desk
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.78, blue: 0.45).opacity(0.35 * lampGlow),
                                .clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 70)
                    .position(x: geo.size.width * 0.28, y: geo.size.height * 0.72)

                // Desk plank
                deskPlank
                    .frame(height: geo.size.height * 0.28)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                // Objects on desk
                DeskLampView(glow: lampGlow)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.58)

                NotebookView(active: mood == .focusing || mood == .slowing)
                    .position(x: geo.size.width * 0.62, y: geo.size.height * 0.68)

                MugView(steam: mood == .focusing)
                    .position(x: geo.size.width * 0.82, y: geo.size.height * 0.66)

                PipMascotView(mood: mood)
                    .position(x: geo.size.width * 0.42, y: geo.size.height * 0.55)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var window: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.10, blue: 0.20),
                            Color(red: 0.12, green: 0.14, blue: 0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            // City dots
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 7 + CGFloat(i % 3) * 3, height: 14 + CGFloat((i * 7) % 22))
                        .overlay(alignment: .topLeading) {
                            VStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { _ in
                                    HStack(spacing: 2) {
                                        Circle().fill(Color.yellow.opacity(0.55 * windowBrightness)).frame(width: 2, height: 2)
                                        Circle().fill(Color.yellow.opacity(0.35 * windowBrightness)).frame(width: 2, height: 2)
                                    }
                                }
                            }
                            .padding(3)
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Window frame cross
            Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1)
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1.5)
        )
    }

    private var deskPlank: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.28, blue: 0.18),
                    Color(red: 0.28, green: 0.18, blue: 0.11)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 2)
        }
    }
}

private struct DeskLampView: View {
    let glow: Double

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(red: 1.0, green: 0.82, blue: 0.55).opacity(0.25 + glow * 0.7))
                .frame(width: 34, height: 16)
                .shadow(color: Color.orange.opacity(glow * 0.85), radius: 16 * glow, y: 2)
            Path { path in
                path.move(to: CGPoint(x: 17, y: 0))
                path.addQuadCurve(to: CGPoint(x: 8, y: 36), control: CGPoint(x: 28, y: 18))
            }
            .stroke(Color(red: 0.55, green: 0.55, blue: 0.58), lineWidth: 2.5)
            .frame(width: 34, height: 36)
            Capsule()
                .fill(Color(red: 0.45, green: 0.45, blue: 0.48))
                .frame(width: 22, height: 5)
        }
    }
}

private struct NotebookView: View {
    let active: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                .frame(width: 58, height: 38)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0.75, green: 0.35, blue: 0.35))
                .frame(width: 4, height: 38)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3, id: \.self) { line in
                    Capsule()
                        .fill(Color.black.opacity(active ? 0.28 : 0.10))
                        .frame(width: CGFloat(34 - line * 8), height: 2)
                }
            }
            .padding(.leading, 10)
            .padding(.top, 10)
        }
        .rotationEffect(.degrees(active ? -6 : 3))
    }
}

private struct MugView: View {
    let steam: Bool
    @State private var rising = false

    var body: some View {
        ZStack(alignment: .top) {
            if steam {
                HStack(alignment: .bottom, spacing: 3) {
                    steamWisp(height: 10, delay: 0)
                    steamWisp(height: 14, delay: 0.2)
                    steamWisp(height: 9, delay: 0.35)
                }
                .offset(y: -12)
                .onAppear { rising = true }
                .onChange(of: steam) { _, on in
                    rising = on
                }
            }

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.85, green: 0.88, blue: 0.92))
                    .frame(width: 16, height: 18)
                Capsule()
                    .stroke(Color(red: 0.85, green: 0.88, blue: 0.92), lineWidth: 2)
                    .frame(width: 8, height: 10)
                    .offset(x: -2)
            }
        }
    }

    private func steamWisp(height: CGFloat, delay: Double) -> some View {
        Capsule()
            .fill(Color.white.opacity(rising ? 0.12 : 0.4))
            .frame(width: 2.2, height: height)
            .offset(y: rising ? -10 : 0)
            .animation(
                .easeInOut(duration: 1.15)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: rising
            )
    }
}
