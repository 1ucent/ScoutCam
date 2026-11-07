import Foundation
import UIKit

/// Video: JPEG frames from /?action=stream (pure multipart JPEG parts).
final class VideoStream: NSObject, URLSessionDataDelegate {
    var onFrame: ((UIImage) -> Void)?
    private let device: CameraDevice
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private let boundary = Data("--boundarydonotcross".utf8)
    private let hdrEnd = Data("\r\n\r\n".utf8)
    private let soi = Data([0xFF, 0xD8])
    private let eoi = Data([0xFF, 0xD9])

    init(device: CameraDevice) { self.device = device; super.init() }

    func start() {
        stop()
        var req = URLRequest(url: URL(string: "http://\(device.host):\(device.port)/?action=stream")!)
        req.timeoutInterval = 30
        req.setValue("Basic " + Data("\(device.user):\(device.pass)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        task = session?.dataTask(with: req)
        task?.resume()
    }

    func stop() {
        task?.cancel(); task = nil
        session?.invalidateAndCancel(); session = nil
        buffer.removeAll()
    }

    func urlSession(_ s: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        parse()
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        buffer.removeAll()
    }

    private func parse() {
        while let br = buffer.range(of: boundary) {
            guard let he = buffer.range(of: hdrEnd, in: br.upperBound..<buffer.endIndex) else { return }
            var cl: Int?
            let header = String(data: buffer[br.upperBound..<he.lowerBound], encoding: .utf8) ?? ""
            for line in header.split(separator: "\r\n") {
                if line.lowercased().hasPrefix("content-length:") {
                    cl = Int(line.split(separator: ":", maxSplits: 1).dropFirst().first?.trimmingCharacters(in: .whitespaces) ?? "")
                }
            }
            let start = he.upperBound
            if let cl = cl {
                if buffer.distance(from: start, to: buffer.endIndex) < cl { return }
                let end = buffer.index(start, offsetBy: cl)
                handlePart(buffer[start..<end])
                buffer.removeSubrange(buffer.startIndex...end)
            } else {
                guard let nb = buffer.range(of: boundary, in: start..<buffer.endIndex) else { return }
                handlePart(buffer[start..<nb.lowerBound])
                buffer.removeSubrange(buffer.startIndex..<nb.lowerBound)
            }
        }
    }

    private func handlePart(_ p: Data) {
        guard let s = p.range(of: soi) else { return }
        guard let e = p.range(of: eoi, options: .backwards, in: s.lowerBound..<p.endIndex) else { return }
        if let img = UIImage(data: p.subdata(in: s.lowerBound..<e.upperBound)) {
            onFrame?(img)
        }
    }
}

/// Audio: camera mic from /?action=appletastream (15-byte header + IMA ADPCM @ 8 kHz).
final class AudioStream: NSObject, URLSessionDataDelegate {
    var onAudio: ((Data) -> Void)?
    private let device: CameraDevice
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private let boundary = Data("--boundarydonotcross".utf8)
    private let hdrEnd = Data("\r\n\r\n".utf8)

    init(device: CameraDevice) { self.device = device; super.init() }

    func start() {
        stop()
        var req = URLRequest(url: URL(string: "http://\(device.host):\(device.port)/?action=appletastream")!)
        req.timeoutInterval = 30
        req.setValue("Basic " + Data("\(device.user):\(device.pass)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        task = session?.dataTask(with: req)
        task?.resume()
    }

    func stop() {
        task?.cancel(); task = nil
        session?.invalidateAndCancel(); session = nil
        buffer.removeAll()
    }

    func urlSession(_ s: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        parse()
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        buffer.removeAll()
    }

    private func parse() {
        while let br = buffer.range(of: boundary) {
            guard let he = buffer.range(of: hdrEnd, in: br.upperBound..<buffer.endIndex) else { return }
            var cl: Int?
            let header = String(data: buffer[br.upperBound..<he.lowerBound], encoding: .utf8) ?? ""
            for line in header.split(separator: "\r\n") {
                if line.lowercased().hasPrefix("content-length:") {
                    cl = Int(line.split(separator: ":", maxSplits: 1).dropFirst().first?.trimmingCharacters(in: .whitespaces) ?? "")
                }
            }
            let start = he.upperBound
            if let cl = cl {
                if buffer.distance(from: start, to: buffer.endIndex) < cl { return }
                let end = buffer.index(start, offsetBy: cl)
                handlePart(buffer[start..<end])
                buffer.removeSubrange(buffer.startIndex...end)
            } else {
                guard let nb = buffer.range(of: boundary, in: start..<buffer.endIndex) else { return }
                handlePart(buffer[start..<nb.lowerBound])
                buffer.removeSubrange(buffer.startIndex..<nb.lowerBound)
            }
        }
    }

    private func handlePart(_ p: Data) {
        guard p.count >= 15 else { return }
        let b = [UInt8](p)
        let ht = b[0] & 8
        let at = b[0] & 6
        let alen = Int((UInt32(b[1]) << 24) | (UInt32(b[2]) << 16) | (UInt32(b[3]) << 8) | UInt32(b[4]))
        let off = ht == 0 ? 15 : 56
        guard p.count > off else { return }
        if alen > 0, off + alen <= p.count {
            let au = p.subdata(in: off..<off + alen)
            onAudio?(at == 0 ? ADPCM.decode(au) : au)
        }
    }
}
