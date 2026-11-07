import AVFoundation
import Foundation

/// Plays decoded camera audio (8 kHz mono PCM) and exposes the engine for talkback.
final class AudioEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let fmt8k = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false)!
    private var started = false

    var engineNode: AVAudioEngine { engine }

    func start() {
        guard !started else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: fmt8k)
        do {
            try engine.start()
            player.play()
        } catch {
            return
        }
        started = true
    }

    func feed(pcm16: Data) {
        guard started else { return }
        let n = pcm16.count / 2
        guard n > 0, let buf = AVAudioPCMBuffer(pcmFormat: fmt8k, frameCapacity: AVAudioFrameCount(n)) else { return }
        buf.frameLength = AVAudioFrameCount(n)
        pcm16.withUnsafeBytes { raw in
            let src = raw.bindMemory(to: Int16.self)
            let dst = buf.floatChannelData![0]
            for i in 0..<n { dst[i] = Float(src[i]) / 32768.0 }
        }
        player.scheduleBuffer(buf)
    }

    func stop() {
        guard started else { return }
        player.stop()
        engine.stop()
        engine.disconnectNodeOutput(player)
        started = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
