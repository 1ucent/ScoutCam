import SwiftUI

struct CameraSquare: View {
    @Environment(CameraStore.self) private var store
    let cam: CameraDevice
    @State private var renaming = false
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(cam.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Button {
                    newName = cam.name
                    renaming = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.footnote)
                }
                .glassButton()
            }
            Spacer()
            Text(cam.model)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(cam.host)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .glassCard()
        .alert("Rename camera", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Save") { store.rename(cam, to: newName) }
            Button("Cancel", role: .cancel) {}
        }
        .contextMenu {
            Button(role: .destructive) {
                store.remove(cam)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct AddCameraSheet: View {
    @Environment(CameraStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var host = ""
    @State private var name = ""
    @State private var user = "camera"
    @State private var pass = "000000"
    @State private var scanning = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Camera") {
                    TextField("IP address (e.g. 10.0.0.50)", text: $host)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Name (optional)", text: $name)
                }
                Section("Credentials") {
                    TextField("Username", text: $user)
                    SecureField("Password", text: $pass)
                }
                Section {
                    Button {
                        let h = host.trimmingCharacters(in: .whitespaces)
                        guard !h.isEmpty else { return }
                        let cam = CameraDevice(name: name.isEmpty ? "Camera" : name,
                                               model: "Scout", host: h, user: user, pass: pass)
                        store.add(cam)
                        dismiss()
                    } label: {
                        Text("Add camera")
                    }
                    Button {
                        scanning = true
                        Task {
                            let found = await Discovery.scan()
                            for c in found where !store.cameras.contains(where: { $0.host == c.host }) {
                                store.add(c)
                            }
                            scanning = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if scanning { ProgressView() }
                            Text("Scan network")
                        }
                    }
                }
            }
            .navigationTitle("Add camera")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
