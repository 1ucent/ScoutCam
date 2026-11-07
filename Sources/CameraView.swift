import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    let camera: CameraDevice

    @State private var session: CameraSession?

    var body: some View {
        VStack(spacing: 12) {
            topBar
            feed
            zoomBar
            Joystick { pan, tilt in
                session?.nudge(pan: pan, tilt: tilt)
            } onEnd: {
                session?.stopMove()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if session == nil {
                let s = CameraSession(camera: camera)
                session = s
                s.start()
            }
        }
        .onDisappear {
            session?.stop()
            session = nil
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            .glassButton()

            Spacer()
            Text(camera.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()

            // hold to talk (device mic -> camera speaker)
            Button {} label: {
                Image(systemName: "mic.fill")
                    .font(.headline)
            }
            .glassButton()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in session?.beginTalk() }
                    .onEnded { _ in session?.endTalk() }
            )
        }
    }

    private var feed: some View {
        GeometryReader { g in
            ZStack {
                if let img = session?.frame {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(session?.zoom ?? 1.0)
                        .frame(width: g.size.width, height: g.size.width)
                        .clipped()
                        .glassCard()
                } else {
                    ProgressView("Connecting…")
                        .frame(width: g.size.width, height: g.size.width)
                }
            }
        }
        .frame(height: 340)
    }

    private var zoomBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "minus.magnifyingglass")
            Slider(
                value: Binding(
                    get: { session?.zoom ?? 1.0 },
                    set: { session?.zoom = $0 }
                ),
                in: 1.0...6.0
            )
            Image(systemName: "plus.magnifyingglass")
        }
        .font(.footnote)
    }
}
