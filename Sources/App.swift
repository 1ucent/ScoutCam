import SwiftUI

@main
struct ScoutCamApp: App {
    @State private var store = CameraStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(nil) // theme follows the device (light/dark)
        }
    }
}

struct RootView: View {
    let store: CameraStore
    @State private var showSetup: Bool

    init(store: CameraStore) {
        self.store = store
        _showSetup = State(initialValue: !store.setupDone)
    }

    var body: some View {
        HomeView()
            .environment(store)
            .sheet(isPresented: $showSetup) {
                SetupView { showSetup = false }
                    .environment(store)
            }
    }
}
