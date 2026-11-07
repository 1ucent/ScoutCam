import Foundation
import UIKit

struct CameraClient {
    let device: CameraDevice

    var base: String { "http://\(device.host):\(device.port)" }
    private var auth: String {
        "Basic " + Data("\(device.user):\(device.pass)".utf8).base64EncodedString()
    }

    private func url(_ path: String) -> URL {
        URL(string: base + path)!
    }

    @discardableResult
    func command(_ c: String) async throws -> Data {
        var req = URLRequest(url: url("/?action=command&command=" + c.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!))
        req.timeoutInterval = 8
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    func snapshot() async throws -> UIImage {
        var req = URLRequest(url: url("/?action=snapshot"))
        req.timeoutInterval = 8
        req.setValue(auth, forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let img = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return img
    }

    /// Join the camera to a home Wi-Fi network. Packed payload is
    /// base64("ssid;password;mode") with mode 3 = WPA/WPA2.
    func provision(wifi ssid: String, password: String, mode: Int = 3) async throws {
        let payload = "\(ssid);\(password);\(mode)"
        let packed = Data(payload.utf8).base64EncodedString()
        _ = try await command("setup_wireless_save&setup=\(packed)")
        try? await command("restart_system")
    }
}
