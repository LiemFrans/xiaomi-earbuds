import Foundation
@preconcurrency import CoreBluetooth

// CoreBluetooth types are thread-safe in practice but not marked Sendable.
extension CBService: @unchecked @retroactive Sendable {}
extension CBCharacteristic: @unchecked @retroactive Sendable {}
extension CBPeripheral: @unchecked @retroactive Sendable {}

// MARK: - Wire-Format Mapping

extension ANCMode {
    var wireByte: UInt8 {
        switch self {
        case .off: return 0x00
        case .noiseCancellation: return 0x01
        case .transparency: return 0x02
        }
    }

    init?(wireByte: UInt8) {
        switch wireByte {
        case 0x00: self = .off
        case 0x01: self = .noiseCancellation
        case 0x02: self = .transparency
        default: return nil
        }
    }
}

extension AudioCodec {
    var wireByte: UInt8 {
        switch self {
        case .sbc: return 0x00
        case .aac: return 0x01
        case .ldac: return 0x02
        }
    }

    init?(wireByte: UInt8) {
        switch wireByte {
        case 0x00: self = .sbc
        case 0x01: self = .aac
        case 0x02: self = .ldac
        default: return nil
        }
    }
}

// EQ preset ids (config 7) for REDMI Buds 8 Pro, verified on device.
extension SoundMode {
    var wireByte: UInt8 {
        switch self {
        case .balanced: return 0x00
        case .enhancedVoice: return 0x01
        case .enhancedBass: return 0x05
        case .enhancedTreble: return 0x06
        case .custom: return 0x0A
        }
    }

    init?(wireByte: UInt8) {
        switch wireByte {
        case 0x00: self = .balanced
        case 0x01: self = .enhancedVoice
        case 0x05: self = .enhancedBass
        case 0x06: self = .enhancedTreble
        case 0x0A: self = .custom
        default: return nil
        }
    }
}

// Gesture action ids (config 2). The firmware reuses 0x08 as "none" on taps
// and "voice assistant" on press & hold, so decoding needs the gesture type.
extension GestureAction {
    func wireByte(for type: GestureType) -> UInt8 {
        switch self {
        case .none: return type == .swipe ? 0x00 : 0x08
        case .voiceAssistant: return 0x08
        case .playPause: return 0x01
        case .previousSong: return 0x02
        case .nextSong: return 0x03
        case .volumeUp: return 0x04
        case .volumeDown: return 0x05
        case .noiseControl: return 0x06
        case .adjustVolume: return 0x0B
        }
    }

    init?(wireByte: UInt8, for type: GestureType) {
        switch (wireByte, type) {
        case (0x08, .pressHold): self = .voiceAssistant
        case (0x08, _), (0x00, .swipe): self = .none
        case (0x00, _): self = .voiceAssistant
        case (0x01, _): self = .playPause
        case (0x02, _): self = .previousSong
        case (0x03, _): self = .nextSong
        case (0x04, _): self = .volumeUp
        case (0x05, _): self = .volumeDown
        case (0x06, _): self = .noiseControl
        case (0x0B, _): self = .adjustVolume
        default: return nil
        }
    }
}

// MARK: - RCSP Protocol Constants (JieLi)

/// Constants for the JieLi RCSP protocol used by REDMI Buds 8 Pro
/// over Classic BT RFCOMM (MIWEAR service).
enum ProtocolConstants {

    // MARK: - RCSP Frame Markers

    /// Frame header magic bytes: 0xFE 0xDC 0xBA
    static let magic: [UInt8] = [0xFE, 0xDC, 0xBA]

    /// Frame trailer byte
    static let trailer: UInt8 = 0xEF

    /// Minimum frame size: magic(3) + flags(1) + opcode(1) + length(2) + trailer(1)
    static let minimumFrameSize = 8

    // MARK: - RCSP App IDs

    /// App 1: com.xiaomi.bluetooth — auth runs here
    static let appMIUI: UInt8 = 1

    /// App 4: com.mi.earphone — device config runs here
    static let appEarphone: UInt8 = 4

    // MARK: - RCSP Flag Bytes

    /// Command to app 4 (earphone config): 0x80 | 0x40 | 0x04
    static let flagsCmdApp4: UInt8 = 0xC4

    /// Command to app 1 (MIUI auth): 0x80 | 0x40 | 0x01
    static let flagsCmdApp1: UInt8 = 0xC1

    // MARK: - RCSP Opcodes

    /// GET_TARGET_INFO — battery, device name, etc. (app 4)
    static let opGetTargetInfo: UInt8 = 0x02

    /// AUTH_CHECK — send/receive authentication challenge (app 1)
    static let opAuthCheck: UInt8 = 0x50

    /// AUTH_CONFIRM — confirm authentication result (app 1)
    static let opAuthConfirm: UInt8 = 0x51

    /// SET_DEVICE_CONFIG — write a config value (app 4)
    static let opSetDeviceConfig: UInt8 = 0xF2

    /// GET_DEVICE_CONFIG — read a config value (app 4)
    static let opGetDeviceConfig: UInt8 = 0xF3

    /// SET_TARGET_INFO — the only write that actually switches the ANC DSP path (app 4)
    static let opSetTargetInfo: UInt8 = 0x08

    /// GET_DEVICE_RUN_INFO — runtime attributes, incl. the live ANC mode (app 4)
    static let opGetRunInfo: UInt8 = 0x09

    /// REPORT_DEVICE_STATUS — buds-initiated battery / ANC push (buds → host)
    static let opReportStatus: UInt8 = 0x0E

    /// NOTIFY_DEVICE_CONFIG — buds-initiated config change push (buds → host)
    static let opNotifyConfig: UInt8 = 0xF4

    // MARK: - Target / Run-Info Attributes (u8 type)

    /// SET_TARGET_INFO attribute carrying the ANC mode (`02 04 <mode>`)
    static let attrANCMode: UInt8 = 0x04

    /// GET_DEVICE_RUN_INFO attribute holding `[mode, level]`
    static let runInfoANC: UInt8 = 0x09

    /// GET_TARGET_INFO attribute holding the firmware version (4 BCD bytes)
    static let targetInfoFirmware: UInt8 = 0x01

    // MARK: - Device Config IDs (u16 BE), verified on REDMI Buds 8 Pro

    static let configIDGestures: UInt16 = 0x0002
    static let configIDAutoAnswer: UInt16 = 0x0003
    static let configIDDualConnection: UInt16 = 0x0004
    static let configIDEQPreset: UInt16 = 0x0007
    static let configIDFindDevice: UInt16 = 0x0009
    static let configIDNoiseCycle: UInt16 = 0x000A
    /// Stored ANC `[mode, level]`; writing it only changes the level, not the DSP path.
    static let configIDANC: UInt16 = 0x000B
    static let configIDAdaptiveANC: UInt16 = 0x0025
    static let configIDAdaptiveSound: UInt16 = 0x0029
    static let configIDLowLatency: UInt16 = 0x002F

    /// Firmware ANC level range for the Buds 8 Pro: 0 = deepest, 20 = lightest.
    static let ancLevelMax: UInt8 = 20

    // MARK: - Auth Placeholder Address

    /// Fixed placeholder address used by MIUI auth (NOT the device MAC)
    static let authPlaceholderAddr: [UInt8] = [0x11, 0x22, 0x33, 0x33, 0x22, 0x11]

    // MARK: - Classic Bluetooth / RFCOMM

    /// MIWEAR proprietary control service UUID discovered via SDP.
    static let miwearServiceUUID = "0000FD2D-0000-1000-8000-00805F9B34FB"

    /// RFCOMM channel for the MIWEAR control service.
    static let miwearRFCOMMChannel: UInt8 = 28

    // MARK: - Device Discovery & Timing

    /// Device name prefix used to filter scan results.
    static let deviceNameFilter = "REDMI"

    /// Known BT address of the REDMI Buds 8 Pro (for auto-reconnect).
    static let knownDeviceAddress = "B8:53:84:6B:BD:88"

    /// Scan timeout in seconds.
    static let scanTimeout: TimeInterval = 15.0

    /// Connection timeout in seconds.
    static let connectionTimeout: TimeInterval = 10.0

    /// Command response timeout in seconds.
    static let commandTimeout: TimeInterval = 8.0

    /// Reconnection delay in seconds after unexpected disconnect.
    static let reconnectDelay: TimeInterval = 3.0
}

// MARK: - RCSP Auth Crypto (from libxm_bluetooth.so .rodata)

/// JieLi RCSP authentication crypto — ported verbatim from verified PoC.
/// Three test vectors are verified in `authTransformSelfTest()`.
enum RCSPCrypto {

    // MARK: - Lookup Tables

    static let tabExpand: [UInt8] = [
        0x64,0xAC,0x28,0x5A,0xC9,0xB3,0x37,0xC5,0x0A,0x10,0xB7,0xA3,0xBA,0xB1,0x97,0x46,
        0x3D,0x05,0xDC,0x66,0x6E,0xF6,0x9A,0xF8,0x0D,0x58,0x95,0x67,0xC6,0xAA,0xAB,0xEC,
        0xA0,0x68,0x9B,0x96,0xD4,0xEB,0xBF,0x43,0x49,0x36,0xE9,0x6A,0x89,0xD8,0xC3,0x8A,
        0x94,0x63,0x99,0xBC,0x7B,0xBE,0xC1,0x22,0xBB,0x5C,0x71,0xD5,0x1F,0x92,0x57,0x5D,
        0x8F,0x44,0x41,0x1D,0x51,0xE6,0x40,0x17,0xFB,0xFD,0x19,0x32,0x34,0xB8,0x61,0x2A,
        0xCA,0x23,0x6F,0xDA,0x39,0xF7,0xA2,0x01,0x7F,0xD6,0x31,0xE7,0xDE,0x80,0x04,0xDD,
        0x2C,0x59,0x82,0xAF,0xA8,0xE0,0x0F,0xCD,0xA1,0x12,0x3E,0x30,0xD1,0x1C,0xD0,0x3A,
        0x33,0x72,0x2E,0x4F,0x90,0x02,0x13,0x06,0x75,0xCE,0x87,0xC2,0xEF,0xB2,0xAD,0x7D,
        0x38,0x15,0xE1,0x52,0x9F,0x7A,0x6C,0x2F,0x27,0xC4,0xE2,0x81,0xA9,0xCF,0x8D,0xC0,
        0xD7,0xDF,0xFF,0x60,0x76,0x14,0x8C,0x5E,0x55,0x09,0xE4,0x08,0xC7,0x42,0x20,0xFC,
        0xD2,0x50,0x91,0xD9,0x4C,0x62,0x9E,0xE8,0xB9,0xA6,0xF9,0x1A,0x00,0x21,0x0B,0xFA,
        0x35,0x9C,0x4E,0x4B,0x69,0x48,0xCB,0x0E,0xC8,0xA4,0x5B,0xEA,0x84,0x07,0xB4,0x18,
        0xF4,0xAE,0x6B,0xDB,0xA7,0xCC,0x3F,0x8B,0x4A,0x0C,0x3C,0x25,0xE5,0x54,0x4D,0x45,
        0x83,0xED,0x11,0xF0,0xB0,0x53,0x93,0xF2,0x74,0x26,0xB5,0x9D,0x6D,0x7C,0xF3,0x2D,
        0xF1,0x56,0x24,0x7E,0x47,0x1B,0x86,0xBD,0x70,0x8E,0x1E,0x3B,0x73,0x16,0x03,0xB6,
        0xAC,0x28,0x5A,0xC9,0xB3,0x37,0xC5,0x0A,0x10,0xB7,0xA3,0xBA,0xB1,0x97,0x46,0x88,
    ]

    static let tabA: [UInt8] = [
        0x01,0x2D,0xE2,0x93,0xBE,0x45,0x15,0xAE,0x78,0x03,0x87,0xA4,0xB8,0x38,0xCF,0x3F,
        0x08,0x67,0x09,0x94,0xEB,0x26,0xA8,0x6B,0xBD,0x18,0x34,0x1B,0xBB,0xBF,0x72,0xF7,
        0x40,0x35,0x48,0x9C,0x51,0x2F,0x3B,0x55,0xE3,0xC0,0x9F,0xD8,0xD3,0xF3,0x8D,0xB1,
        0xFF,0xA7,0x3E,0xDC,0x86,0x77,0xD7,0xA6,0x11,0xFB,0xF4,0xBA,0x92,0x91,0x64,0x83,
        0xF1,0x33,0xEF,0xDA,0x2C,0xB5,0xB2,0x2B,0x88,0xD1,0x99,0xCB,0x8C,0x84,0x1D,0x14,
        0x81,0x97,0x71,0xCA,0x5F,0xA3,0x8B,0x57,0x3C,0x82,0xC4,0x52,0x5C,0x1C,0xE8,0xA0,
        0x04,0xB4,0x85,0x4A,0xF6,0x13,0x54,0xB6,0xDF,0x0C,0x1A,0x8E,0xDE,0xE0,0x39,0xFC,
        0x20,0x9B,0x24,0x4E,0xA9,0x98,0x9E,0xAB,0xF2,0x60,0xD0,0x6C,0xEA,0xFA,0xC7,0xD9,
        0x00,0xD4,0x1F,0x6E,0x43,0xBC,0xEC,0x53,0x89,0xFE,0x7A,0x5D,0x49,0xC9,0x32,0xC2,
        0xF9,0x9A,0xF8,0x6D,0x16,0xDB,0x59,0x96,0x44,0xE9,0xCD,0xE6,0x46,0x42,0x8F,0x0A,
        0xC1,0xCC,0xB9,0x65,0xB0,0xD2,0xC6,0xAC,0x1E,0x41,0x62,0x29,0x2E,0x0E,0x74,0x50,
        0x02,0x5A,0xC3,0x25,0x7B,0x8A,0x2A,0x5B,0xF0,0x06,0x0D,0x47,0x6F,0x70,0x9D,0x7E,
        0x10,0xCE,0x12,0x27,0xD5,0x4C,0x4F,0xD6,0x79,0x30,0x68,0x36,0x75,0x7D,0xE4,0xED,
        0x80,0x6A,0x90,0x37,0xA2,0x5E,0x76,0xAA,0xC5,0x7F,0x3D,0xAF,0xA5,0xE5,0x19,0x61,
        0xFD,0x4D,0x7C,0xB7,0x0B,0xEE,0xAD,0x4B,0x22,0xF5,0xE7,0x73,0x23,0x21,0xC8,0x05,
        0xE1,0x66,0xDD,0xB3,0x58,0x69,0x63,0x56,0x0F,0xA1,0x31,0x95,0x17,0x07,0x3A,0x28,
    ]

    static let tabB: [UInt8] = [
        0x80,0x00,0xB0,0x09,0x60,0xEF,0xB9,0xFD,0x10,0x12,0x9F,0xE4,0x69,0xBA,0xAD,0xF8,
        0xC0,0x38,0xC2,0x65,0x4F,0x06,0x94,0xFC,0x19,0xDE,0x6A,0x1B,0x5D,0x4E,0xA8,0x82,
        0x70,0xED,0xE8,0xEC,0x72,0xB3,0x15,0xC3,0xFF,0xAB,0xB6,0x47,0x44,0x01,0xAC,0x25,
        0xC9,0xFA,0x8E,0x41,0x1A,0x21,0xCB,0xD3,0x0D,0x6E,0xFE,0x26,0x58,0xDA,0x32,0x0F,
        0x20,0xA9,0x9D,0x84,0x98,0x05,0x9C,0xBB,0x22,0x8C,0x63,0xE7,0xC5,0xE1,0x73,0xC6,
        0xAF,0x24,0x5B,0x87,0x66,0x27,0xF7,0x57,0xF4,0x96,0xB1,0xB7,0x5C,0x8B,0xD5,0x54,
        0x79,0xDF,0xAA,0xF6,0x3E,0xA3,0xF1,0x11,0xCA,0xF5,0xD1,0x17,0x7B,0x93,0x83,0xBC,
        0xBD,0x52,0x1E,0xEB,0xAE,0xCC,0xD6,0x35,0x08,0xC8,0x8A,0xB4,0xE2,0xCD,0xBF,0xD9,
        0xD0,0x50,0x59,0x3F,0x4D,0x62,0x34,0x0A,0x48,0x88,0xB5,0x56,0x4C,0x2E,0x6B,0x9E,
        0xD2,0x3D,0x3C,0x03,0x13,0xFB,0x97,0x51,0x75,0x4A,0x91,0x71,0x23,0xBE,0x76,0x2A,
        0x5F,0xF9,0xD4,0x55,0x0B,0xDC,0x37,0x31,0x16,0x74,0xD7,0x77,0xA7,0xE6,0x07,0xDB,
        0xA4,0x2F,0x46,0xF3,0x61,0x45,0x67,0xE3,0x0C,0xA2,0x3B,0x1C,0x85,0x18,0x04,0x1D,
        0x29,0xA0,0x8F,0xB2,0x5A,0xD8,0xA6,0x7E,0xEE,0x8D,0x53,0x4B,0xA1,0x9A,0xC1,0x0E,
        0x7A,0x49,0xA5,0x2C,0x81,0xC4,0xC7,0x36,0x2B,0x7F,0x43,0x95,0x33,0xF2,0x6C,0x68,
        0x6D,0xF0,0x02,0x28,0xCE,0xDD,0x9B,0xEA,0x5E,0x99,0x7C,0x14,0x86,0xCF,0xE5,0x42,
        0xB8,0x40,0x78,0x2D,0x3A,0xE9,0x64,0x1F,0x92,0x90,0x7D,0x39,0x6F,0xE0,0x89,0x30,
    ]

    static let xorMask: UInt16 = 0x9999

    // MARK: - Auth Transform

    private static func rol8(_ b: UInt8, _ n: Int) -> UInt8 {
        (b << n) | (b >> (8 - n))
    }

    private static func sel(_ i: Int) -> Bool {
        (xorMask >> i) & 1 == 1
    }

    private static func expandKey(_ key: [UInt8]) -> [UInt8] {
        precondition(key.count == 16)
        var buf = [UInt8](repeating: 0, count: 272)
        for i in 0..<16 { buf[i] = key[i] }

        var v = [UInt8](repeating: 0, count: 16)
        for i in 0..<16 {
            v[i] = i < 8 ? (key[i] ^ key[i + 8]) : key[i]
        }
        var checksum: UInt8 = 0
        for i in 0..<8 { checksum ^= v[i] }

        var state = Array(key)
        for r in 0..<16 {
            state = state.map { rol8($0, 3) }
            checksum = rol8(checksum, 3)
            let window = state + [checksum]
            let tableBase = r * 16
            let outBase = 16 + r * 16
            for j in 0..<16 {
                buf[outBase + j] = UInt8(
                    (UInt16(tabExpand[tableBase + 15 - j]) + UInt16(window[(r + 1 + j) % 17])) & 0xFF
                )
            }
        }
        return buf
    }

    private static func round16(_ b: [UInt8]) -> [UInt8] {
        let b = b.map { Int($0) }
        let (b0,b1,b2,b3,b4,b5,b6,b7) = (b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7])
        let (b8,b9,b10,b11,b12,b13,b14,b15) = (b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15])

        var w7 = b1 + 2*b0;  var w16 = b1 + b0
        var w20 = b3 + 2*b2;  var w3 = b3 + b2
        var w22 = b5 + 2*b4;  var w5 = b5 + b4
        var w24 = b7 + 2*b6;  var w17 = b7 + b6
        var w26 = b9 + 2*b8;  var w4 = b9 + b8
        var w28 = b11 + 2*b10; var w6 = b11 + b10
        var w23 = b13 + 2*b12; var w19 = b13 + b12
        var w25 = b15 + 2*b14; var w21 = b15 + b14

        var w27 = w6 + 2*w26;  w6 = w6 + w26
        w26 = w21 + 2*w23; w21 = w21 + w23
        w23 = w16 + 2*w20; w16 = w20 + w16
        w20 = w5 + 2*w24;  w5 = w24 + w5
        w24 = w4 + 2*w28;  w4 = w28 + w4
        w28 = w19 + 2*w25; w19 = w25 + w19
        w25 = w17 + 2*w7;  w17 = w17 + w7
        w7 = w3 + 2*w22;   w3 = w22 + w3
        w22 = w19 + 2*w24; w19 = w19 + w24
        w24 = w3 + 2*w25;  w3 = w25 + w3
        w25 = w16 + 2*w20; w16 = w20 + w16
        w20 = w4 + 2*w28;  w4 = w28 + w4
        w28 = w17 + 2*w7;  w17 = w17 + w7
        let w30 = w20 + w17; w17 = w17 + 2*w20
        w7 = w5 + 2*w27;   w5 = w27 + w5
        w27 = w21 + 2*w23; w21 = w21 + w23

        var o = [Int](repeating: 0, count: 16)
        o[0] = w17
        w17 = w19 + w24
        w23 = w26 + w6
        w19 = w19 + 2*w24
        w20 = w21 + w7
        w7 = w21 + 2*w7
        o[5] = w17
        w17 = w23 + 2*w25
        o[4] = w19
        w19 = w4 + w28
        w4 = w4 + 2*w28
        o[2] = w7
        o[6] = w17
        w17 = w27 + w5
        w7 = w23 + w25
        w5 = w5 + 2*w27
        o[8] = w4
        w4 = w22 + w16
        w16 = w16 + 2*w22
        o[11] = w17
        w17 = w6 + 2*w26
        o[1] = w30
        o[13] = w4
        w4 = w17 + w3
        o[12] = w16
        w16 = w3 + 2*w17
        o[3] = w20
        o[7] = w7
        o[9] = w19
        o[10] = w5
        o[15] = w4
        o[14] = w16
        return o.map { UInt8($0 & 0xFF) }
    }

    private static func mix(_ state: [UInt8], _ sched: [UInt8], flag: Bool) -> [UInt8] {
        precondition(state.count == 16 && sched.count == 272)
        var out = state.map { Int($0) }
        let orig = out

        for rnd in 0..<8 {
            let base = rnd * 32
            if flag && rnd == 2 {
                for i in 0..<16 {
                    out[i] = sel(i) ? (out[i] ^ orig[i]) : (out[i] + orig[i])
                }
            }
            for i in 0..<16 {
                let v = Int(sched[base + i])
                out[i] = sel(i) ? (out[i] ^ v) : (out[i] + v)
            }
            out = (0..<16).map { i in
                Int(sel(i) ? tabA[out[i] & 0xFF] : tabB[out[i] & 0xFF])
            }
            for i in 0..<16 {
                let v = Int(sched[base + 16 + i])
                out[i] = sel(i) ? (out[i] + v) : (out[i] ^ v)
            }
            out = round16(out.map { UInt8($0 & 0xFF) }).map { Int($0) }
        }

        for i in 0..<16 {
            let v = Int(sched[0x100 + i])
            out[i] = sel(i) ? (out[i] ^ v) : (out[i] + v)
        }
        return out.map { UInt8($0 & 0xFF) }
    }

    /// Compute the 16-byte auth response for a 16-byte challenge.
    static func authTransform(addr6: [UInt8], challenge: [UInt8]) -> [UInt8] {
        precondition(addr6.count == 6 && challenge.count == 16)
        let outState: [UInt8] = addr6 + addr6 + Array(addr6[0..<4])
        var tmp = challenge
        tmp[15] ^= 0x06
        let sched = expandKey(tmp)
        return mix(outState, sched, flag: true)
    }

    /// Runs the three known test vectors; returns true if all pass.
    @discardableResult
    static func authTransformSelfTest() -> Bool {
        let vectors: [(String, String)] = [
            ("385c2aecb03bfb32af3c54ec18db5c02", "99a16782b8e05df000099bc2cb3417bf"),
            ("1afe43fbfaaa3afb29d1e6053c7c9475", "f011ccd271c9d429d14bd4887d825611"),
            ("acbb8a57b2d58c8aa24d2fb232cbddb7", "e696a4c36f460b55ca6f5b8fb0a4c7f8"),
        ]
        let addr = ProtocolConstants.authPlaceholderAddr
        for (chalHex, wantHex) in vectors {
            let challenge = Data(hexString: chalHex).map { Array($0) } ?? []
            let got = authTransform(addr6: addr, challenge: challenge)
            if got.map({ String(format: "%02x", $0) }).joined() != wantHex {
                return false
            }
        }
        return true
    }
}
