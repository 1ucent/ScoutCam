import Foundation
import Observation

struct CameraDevice: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var model: String = "Scout"
    var host: String
    var port: Int = 80
    var user: String = "camera"
    var pass: String = "000000"
}

@Observable
final class CameraStore {
    var cameras: [CameraDevice] = []
    var setupDone: Bool

    private static let camsKey = "scoutcam.cameras"
    private static let setupKey = "scoutcam.setupDone"

    init() {
        setupDone = UserDefaults.standard.bool(forKey: Self.setupKey)
        if let d = UserDefaults.standard.data(forKey: Self.camsKey),
           let c = try? JSONDecoder().decode([CameraDevice].self, from: d) {
            cameras = c
        }
    }

    func add(_ c: CameraDevice) {
        cameras.append(c)
        save()
    }

    func remove(_ c: CameraDevice) {
        cameras.removeAll { $0.id == c.id }
        save()
    }

    func rename(_ c: CameraDevice, to name: String) {
        guard let i = cameras.firstIndex(where: { $0.id == c.id }) else { return }
        cameras[i].name = name
        save()
    }

    func markSetupDone() {
        setupDone = true
        UserDefaults.standard.set(true, forKey: Self.setupKey)
    }

    private func save() {
        if let d = try? JSONEncoder().encode(cameras) {
            UserDefaults.standard.set(d, forKey: Self.camsKey)
        }
    }
}
