import Foundation
import Network
import Observation
import UIKit

@Observable
final class CameraSession {
    let camera: CameraDevice
    var frame: UIImage?
    var zoom: Double = 1.0

    private let client: CameraClient
    private let stream: CameraStream
    private let audio = AudioEngine()
    private var talkConn: NWConnection?
    private var lastCmd: [String: Date] = [:]

    init(camera: CameraDevice) {
        self.camera = camera
        self.client = CameraClient(device: camera)
        self.stream = CameraStream(device: camera)
        stream.onFrame = { [weak self] img in self?.frame = img }
        stream.onAudio = { [weak self] pcm in self?.audio.feed(pcm16: pcm) }
    }

    func start() {
        audio.start()
        Task { try? await client.command("audio_out0") }
        stream.start()
    }

    func stop() {
        stream.stop()
        audio.stop()
        Task { try? await client.command("audio_out1") }
    }

    @discardableResult
    private func cmd(_ c: String, throttle: TimeInterval = 0.15) -> Bool {
        let now = Date()
        if let t = lastCmd[c], now.timeIntervalSince(t) < throttle { return false }
        lastCmd[c] = now
        Task { try? await client.command(c) }
        return true
    }

    func nudge(pan: CGFloat, tilt: CGFloat) {
        if abs(pan) > 0.2 { cmd(pan > 0 ? "move_right0.1" : "move_left0.1") }
        if abs(tilt) > 0.2 { cmd(tilt > 0 ? "move_backward0.1" : "move_forward0.1") }
    }

    func stopMove() {
        cmd("lr_stop")
        cmd("fb_stop")
    }

    // MARK: Push-to-talk (device mic -> camera speaker)

    func beginTalk() {
        Task { try? await client.command("audio_out1") }
        let conn = NWConnection(host: NWEndpoint.Host(camera.host), port: 51108, using: .tcp)
        conn.stateUpdateHandler = { _ in }
        conn.start(queue: .global())
        talkConn = conn
        audio.engineNode.inputNode.removeTap(onBus: 0)
        let inFmt = audio.engineNode.inputNode.outputFormat(forBus: 0)
        let step = max(1, Int(inFmt.sampleRate / 8000))
        audio.engineNode.inputNode.installTap(onBus: 0, bufferSize: 2048, format: inFmt) { buf, _ in
            guard let ch = buf.floatChannelData?[0] else { return }
            let frames = Int(buf.frameLength)
            var pcm = Data(capacity: frames / step * 2)
            var i = 0
            while i < frames {
                let v = Int16(max(-1, min(1, ch[i])) * 32767)
                withUnsafeBytes(of: v.littleEndian) { pcm.append(contentsOf: $0) }
                i += step
            }
            if !pcm.isEmpty {
                conn.send(content: pcm, completion: .contentProcessed { _ in })
            }
        }
    }

    func endTalk() {
        audio.engineNode.inputNode.removeTap(onBus: 0)
        talkConn?.cancel()
        talkConn = nil
        Task { try? await client.command("audio_out0") }
    }
}
