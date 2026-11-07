import Foundation

enum Discovery {
    /// Best-effort LAN scan: probes the local /24 (plus the camera's known hostname)
    /// for the camera's HTTP command endpoint.
    static func scan() async -> [CameraDevice] {
        var hosts: [String] = ["moto-cam.com"]
        if let ip = localIPv4() {
            let comps = ip.split(separator: ".").map(String.init)
            if comps.count == 4 {
                let base = comps.prefix(3).joined(separator: ".")
                hosts += (1...254).map { "\(base).\($0)" }
            }
        }
        var found: [CameraDevice] = []
        await withTaskGroup(of: CameraDevice?.self) { group in
            for host in hosts {
                group.addTask { await probe(host) }
            }
            for await cam in group {
                if let cam = cam, !found.contains(where: { $0.host == cam.host }) {
                    found.append(cam)
                }
            }
        }
        return found.sorted { $0.host < $1.host }
    }

    private static func probe(_ host: String) async -> CameraDevice? {
        guard let url = URL(string: "http://\(host):80/?action=command&command=get_status") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 0.6
        req.setValue("Basic " + Data("camera:000000".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode < 500 else { return nil }
            guard !data.isEmpty else { return nil }
            let name = "Camera \(host.split(separator: ".").last ?? "cam")"
            return CameraDevice(name: name, model: "Scout", host: host)
        } catch {
            return nil
        }
    }

    private static func localIPv4() -> String? {
        var result: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }
            let flags = Int32(current.pointee.ifa_flags)
            if (flags & IFF_UP) == 0 { continue }
            let sa = current.pointee.ifa_addr
            guard let sa = sa, Int32(sa.pointee.sa_family) == AF_INET else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: host)
                if !ip.hasPrefix("127.") { result = ip; break }
            }
        }
        return result
    }
}
