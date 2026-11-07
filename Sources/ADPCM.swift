import Foundation

/// IMA ADPCM decoder for the camera's mic audio (256-byte block -> 505 s16 samples @ 8 kHz).
enum ADPCM {
    static let steps: [Int32] = [
        7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
        50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
        337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
        2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
        15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
    ]
    static let incMag: [Int32] = [-1, -1, -1, -1, 2, 4, 6, 8]

    static func decode(_ data: Data) -> Data {
        var out = Data()
        var pos = 0
        while pos + 256 <= data.count {
            let b = [UInt8](data.subdata(in: pos..<pos + 256))
            var pred = Int32(Int16(bitPattern: UInt16(b[0]) | (UInt16(b[1]) << 8)))
            var idx = Int(b[2])
            if idx >= steps.count { idx = steps.count - 1 }
            var inpos = 4
            var hi = false
            var samples = [Int16](repeating: 0, count: 505)
            for i in 0..<504 {
                let byte = Int32(b[inpos])
                let delta = hi ? (byte >> 4) & 0xf : byte & 0xf
                hi.toggle()
                if !hi { inpos += 1 }
                let step = steps[idx]
                let dm = delta & 7
                var va: Int32 = (dm & 4) != 0 ? step : 0
                let s2 = step >> 1
                if (dm & 2) != 0 { va += s2 }
                let s3 = s2 >> 1
                if (dm & 1) != 0 { va += s3 }
                va += s3 >> 1
                if dm != delta {
                    pred -= va
                    if pred < -32768 { pred = -32768 }
                } else {
                    pred += va
                    if pred > 32767 { pred = 32767 }
                }
                samples[i] = Int16(pred)
                idx += Int(incMag[Int(dm)])
                if idx < 0 { idx = 0 }
                else if idx >= steps.count { idx = steps.count - 1 }
            }
            samples.withUnsafeBytes { out.append(contentsOf: $0) }
            pos += 256
        }
        return out
    }
}
