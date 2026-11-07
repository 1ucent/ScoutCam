import SwiftUI

struct Joystick: View {
    var onChange: (CGFloat, CGFloat) -> Void
    var onEnd: () -> Void

    @State private var offset = CGSize.zero

    var body: some View {
        GeometryReader { g in
            let radius = min(g.size.width, g.size.height) / 2
            let center = CGPoint(x: g.size.width / 2, y: g.size.height / 2)
            ZStack {
                Circle()
                    .stroke(.secondary, lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .fill(.primary.opacity(0.35))
                    .frame(width: radius, height: radius)
                    .offset(x: offset.width, y: offset.height)
            }
            .position(center)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        offset = CGSize(width: v.translation.width, height: v.translation.height)
                        let dx = (v.translation.width / radius).clamped(-1.0...1.0)
                        let dy = (v.translation.height / radius).clamped(-1.0...1.0)
                        onChange(dx, dy)
                    }
                    .onEnded { _ in
                        offset = .zero
                        onEnd()
                    }
            )
        }
        .frame(height: 170)
    }
}
