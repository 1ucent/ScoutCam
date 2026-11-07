import SwiftUI

struct SetupView: View {
    @Environment(CameraStore.self) private var store
    var onDone: () -> Void

    @State private var step = 0
    @State private var found: [CameraDevice] = []
    @State private var wifi = ""
    @State private var password = ""
    @State private var busy = false
    @State private var status = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch step {
                case 0: stepZero
                case 1: stepOne
                default: stepTwo
                }
                if !status.isEmpty {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .navigationTitle("Set up camera")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        store.markSetupDone()
                        onDone()
                    }
                }
            }
        }
    }

    private var stepZero: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi")
                .font(.system(size: 44))
            Text("Join the camera's own Wi-Fi network (e.g. IPCAM-xxxx) in your iPhone's Settings, then come back here.")
                .multilineTextAlignment(.center)
            Button("I'm connected — find camera") {
                busy = true
                Task {
                    found = await Discovery.scan()
                    busy = false
                    step = found.isEmpty ? 0 : 1
                    if found.isEmpty { status = "No camera found — are you on the camera's Wi-Fi?" }
                }
            }
            .glassButton()
            .disabled(busy)
        }
    }

    private var stepOne: some View {
        VStack(spacing: 16) {
            Text("Camera found: \(found.map(\.host).joined(separator: ", "))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField("Home Wi-Fi name (SSID)", text: $wifi)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
            SecureField("Home Wi-Fi password", text: $password)
                .textFieldStyle(.roundedBorder)
            Button {
                connect()
            } label: {
                Text(busy ? "Connecting…" : "Connect camera to home Wi-Fi")
            }
            .glassButton()
            .disabled(busy || wifi.isEmpty)
        }
    }

    private var stepTwo: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("The camera is joining your home network. Rejoin your Wi-Fi, then tap the magnifier on the home screen to add it.")
                .multilineTextAlignment(.center)
            Button("Done") {
                store.markSetupDone()
                onDone()
            }
            .glassButton()
        }
    }

    private func connect() {
        guard let cam = found.first else { return }
        busy = true
        Task {
            do {
                try await CameraClient(device: cam).provision(wifi: wifi, password: password)
                step = 2
            } catch {
                status = "Failed: \(error.localizedDescription)"
            }
            busy = false
        }
    }
}
