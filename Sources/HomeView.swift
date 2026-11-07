import SwiftUI

struct HomeView: View {
    @Environment(CameraStore.self) private var store
    @State private var showAdd = false
    @State private var scanning = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    Button { showAdd = true } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .semibold))
                            Text("Add camera")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                    .glassButton()

                    ForEach(store.cameras) { cam in
                        NavigationLink(value: cam) {
                            CameraSquare(cam: cam)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("ScoutCam")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { scanAll() } label: {
                        if scanning { ProgressView() }
                        else { Image(systemName: "magnifyingglass") }
                    }
                    .glassButton()
                    .disabled(scanning)
                }
            }
            .navigationDestination(for: CameraDevice.self) { cam in
                CameraView(camera: cam)
            }
            .sheet(isPresented: $showAdd) {
                AddCameraSheet()
                    .environment(store)
                    .presentationDetents([.medium])
            }
        }
    }

    private func scanAll() {
        scanning = true
        Task {
            let found = await Discovery.scan()
            for cam in found where !store.cameras.contains(where: { $0.host == cam.host }) {
                store.add(cam)
            }
            scanning = false
        }
    }
}
