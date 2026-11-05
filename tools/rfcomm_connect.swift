#!/usr/bin/env swift
// rfcomm_connect.swift — Proof-of-concept RFCOMM connection to Xiaomi/Redmi earbuds on macOS.
//
// Usage: swift rfcomm_connect.swift [MAC_ADDRESS] [CHANNEL]
//   Defaults: B8:53:84:6B:BD:88, channel 28
//
// Prerequisites:
//   - The earbuds must be **paired** (bonded) with this Mac via System Settings → Bluetooth
//   - Requires IOBluetooth framework (macOS only)
//
// Protocol: JieLi RCSP over Bluetooth Classic RFCOMM
// Source: Reverse-engineered from com.mi.earphone APK, verified by creeperkafasi/redmi-buds-linux

import Foundation
import IOBluetooth

// MARK: - RCSP Constants

let MAGIC: [UInt8] = [0xFE, 0xDC, 0xBA]
let TRAILER: UInt8 = 0xEF

let APP_MIUI: UInt8 = 1      // com.xiaomi.bluetooth — auth runs here
let APP_EARPHONE: UInt8 = 4  // com.mi.earphone — device config runs here

let OP_GET_TARGET_INFO: UInt8 = 0x02
let OP_AUTH_CHECK: UInt8 = 0x50
let OP_AUTH_CONFIRM: UInt8 = 0x51
let OP_SET_DEVICE_CONFIG: UInt8 = 0xF2
let OP_GET_DEVICE_CONFIG: UInt8 = 0xF3

// Fixed placeholder address — the app always uses this, NOT the device MAC.
let ADDR6_PLACEHOLDER: [UInt8] = [0x11, 0x22, 0x33, 0x33, 0x22, 0x11]

// MARK: - Crypto Tables (from libxm_bluetooth.so .rodata)

private let TAB_EXPAND: [UInt8] = [
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

private let TAB_A: [UInt8] = [
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

private let TAB_B: [UInt8] = [
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

private let XOR_MASK: UInt16 = 0x9999

// MARK: - Auth Transform

private func rol8(_ b: UInt8, _ n: Int) -> UInt8 {
    return (b << n) | (b >> (8 - n))
}

private func sel(_ i: Int) -> Bool {
    return (XOR_MASK >> i) & 1 == 1
}

private func expandKey(_ key: [UInt8]) -> [UInt8] {
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
        var window = state + [checksum]
        let tableBase = r * 16
        let outBase = 16 + r * 16
        for j in 0..<16 {
            buf[outBase + j] = UInt8(
                (UInt16(TAB_EXPAND[tableBase + 15 - j]) + UInt16(window[(r + 1 + j) % 17])) & 0xFF
            )
        }
    }
    return buf
}

private func round16(_ b: [UInt8]) -> [UInt8] {
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

private func mix(_ state: [UInt8], _ sched: [UInt8], flag: Bool) -> [UInt8] {
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
            Int(sel(i) ? TAB_A[out[i] & 0xFF] : TAB_B[out[i] & 0xFF])
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
func authTransform(addr6: [UInt8], challenge: [UInt8]) -> [UInt8] {
    precondition(addr6.count == 6 && challenge.count == 16)
    let outState: [UInt8] = addr6 + addr6 + Array(addr6[0..<4])
    var tmp = challenge
    tmp[15] ^= 0x06
    let sched = expandKey(tmp)
    return mix(outState, sched, flag: true)
}

// MARK: - Self-Test

func selfTest() -> Bool {
    let vectors: [(String, String)] = [
        ("385c2aecb03bfb32af3c54ec18db5c02", "99a16782b8e05df000099bc2cb3417bf"),
        ("1afe43fbfaaa3afb29d1e6053c7c9475", "f011ccd271c9d429d14bd4887d825611"),
        ("acbb8a57b2d58c8aa24d2fb232cbddb7", "e696a4c36f460b55ca6f5b8fb0a4c7f8"),
    ]
    var ok = true
    for (chalHex, wantHex) in vectors {
        let challenge = hexToBytes(chalHex)
        let got = authTransform(addr6: ADDR6_PLACEHOLDER, challenge: challenge)
        let gotHex = bytesToHex(got)
        let status = gotHex == wantHex ? "✅" : "❌ MISMATCH"
        print("  \(chalHex) → \(gotHex)  \(status)")
        if gotHex != wantHex { ok = false }
    }
    return ok
}

// MARK: - RCSP Framing

func encodeFrame(flags: UInt8, opcode: UInt8, payload: [UInt8]) -> [UInt8] {
    var frame: [UInt8] = MAGIC
    frame.append(flags)
    frame.append(opcode)
    let len = UInt16(payload.count)
    frame.append(UInt8(len >> 8))
    frame.append(UInt8(len & 0xFF))
    frame.append(contentsOf: payload)
    frame.append(TRAILER)
    return frame
}

struct RCSPFrame {
    let flags: UInt8
    let opcode: UInt8
    let payload: [UInt8]

    var isCommand: Bool { flags & 0x80 != 0 }
    var targetApp: UInt8 { flags & 0x07 }
    var status: UInt8 { payload.first ?? 0xFF }
    var sn: UInt8 {
        if isCommand { return payload.first ?? 0xFF }
        return payload.count > 1 ? payload[1] : 0xFF
    }
    var data: [UInt8] {
        let skip = isCommand ? 1 : 2
        return payload.count > skip ? Array(payload[skip...]) : []
    }
}

func extractFrame(from buffer: inout [UInt8]) -> RCSPFrame? {
    guard let start = buffer.indices.first(where: { i in
        i + 2 < buffer.count &&
        buffer[i] == MAGIC[0] && buffer[i+1] == MAGIC[1] && buffer[i+2] == MAGIC[2]
    }) else { return nil }

    if start > 0 { buffer.removeFirst(start) }
    guard buffer.count >= 7 else { return nil }

    let plen = Int(buffer[5]) << 8 | Int(buffer[6])
    let end = 7 + plen
    guard buffer.count > end else { return nil }
    guard buffer[end] == TRAILER else {
        buffer.removeFirst(1)
        return nil
    }

    let frame = RCSPFrame(
        flags: buffer[3],
        opcode: buffer[4],
        payload: Array(buffer[7..<end])
    )
    buffer.removeFirst(end + 1)
    return frame
}

// MARK: - Utility

func hexToBytes(_ hex: String) -> [UInt8] {
    var bytes = [UInt8]()
    var i = hex.startIndex
    while i < hex.endIndex {
        let next = hex.index(i, offsetBy: 2)
        bytes.append(UInt8(hex[i..<next], radix: 16)!)
        i = next
    }
    return bytes
}

func bytesToHex(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
}

func bytesToHexSpaced(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
}

func randomBytes(_ count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return bytes
}

// MARK: - RFCOMM Client Delegate

class BudsClient: NSObject, IOBluetoothRFCOMMChannelDelegate {
    let device: IOBluetoothDevice
    let channelID: BluetoothRFCOMMChannelID
    var channel: IOBluetoothRFCOMMChannel?
    var rxBuffer: [UInt8] = []
    var sequenceNumber: UInt8 = 0
    var connected = false
    var authenticated = false
    let semaphore = DispatchSemaphore(value: 0)
    var pendingResponse: RCSPFrame?
    let responseSemaphore = DispatchSemaphore(value: 0)

    init(device: IOBluetoothDevice, channelID: BluetoothRFCOMMChannelID) {
        self.device = device
        self.channelID = channelID
    }

    func nextSN() -> UInt8 {
        sequenceNumber &+= 1
        return sequenceNumber
    }

    // MARK: Connect

    func connect() -> Bool {
        print("📡 Opening RFCOMM channel \(channelID) to \(device.addressString ?? "?")...")
        var rfcommChannel: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelSync(
            &rfcommChannel,
            withChannelID: channelID,
            delegate: self
        )
        if result != kIOReturnSuccess {
            print("❌ Failed to open RFCOMM channel: \(result)")
            return false
        }
        channel = rfcommChannel
        connected = true
        print("✅ RFCOMM channel \(channelID) opened")
        return true
    }

    // MARK: Send Frame

    func sendFrame(flags: UInt8, opcode: UInt8, payload: [UInt8]) {
        let frame = encodeFrame(flags: flags, opcode: opcode, payload: payload)
        print("  → [\(flags & 0x80 != 0 ? "cmd" : "rsp") op=0x\(String(format: "%02x", opcode)) app=\(flags & 0x07)] \(bytesToHexSpaced(payload))")
        var data = frame
        channel?.writeSync(&data, length: UInt16(data.count))
    }

    func sendCommand(opcode: UInt8, params: [UInt8], app: UInt8) -> UInt8 {
        let sn = nextSN()
        var payload: [UInt8] = [sn]
        payload.append(contentsOf: params)
        sendFrame(flags: 0x80 | 0x40 | app, opcode: opcode, payload: payload)
        return sn
    }

    func waitResponse(timeout: TimeInterval = 8.0) -> RCSPFrame? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let frame = pendingResponse {
                pendingResponse = nil
                return frame
            }
            _ = responseSemaphore.wait(timeout: .now() + 0.1)
        }
        return nil
    }

    /// Waits for the response matching a specific SN, skipping unrelated
    /// buds-initiated commands (e.g. trailing 0x51 / 0xF4 notifications).
    func waitResponse(sn: UInt8, timeout: TimeInterval = 8.0) -> RCSPFrame? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            guard let frame = waitResponse(timeout: deadline.timeIntervalSinceNow) else { return nil }
            if !frame.isCommand && frame.sn == sn { return frame }
        }
        return nil
    }

    func request(opcode: UInt8, params: [UInt8], app: UInt8 = APP_EARPHONE) -> RCSPFrame? {
        let sn = sendCommand(opcode: opcode, params: params, app: app)
        return waitResponse(sn: sn)
    }

    /// Reads device-config ids (0xF3) and prints the `len | id(u16) | value` TLVs.
    func probeConfig(ids: [UInt16]) {
        var params: [UInt8] = []
        for id in ids { params += [UInt8(id >> 8), UInt8(id & 0xFF)] }
        guard let rsp = request(opcode: OP_GET_DEVICE_CONFIG, params: params) else {
            print("❌ GET_DEVICE_CONFIG timed out"); return
        }
        print("  status=\(rsp.status)")
        let d = rsp.data
        var i = 0
        while i + 3 <= d.count {
            let len = Int(d[i])
            guard len >= 2, i + 1 + len <= d.count else { break }
            let id = UInt16(d[i + 1]) << 8 | UInt16(d[i + 2])
            print("  cfg \(id): \(bytesToHexSpaced(Array(d[(i + 3)..<(i + 1 + len)])))")
            i += 1 + len
        }
    }

    // MARK: Authentication

    func authenticate() -> Bool {
        print("\n🔐 Starting authentication...")
        let challenge = randomBytes(16)
        print("  Challenge: \(bytesToHex(challenge))")

        let expected = authTransform(addr6: ADDR6_PLACEHOLDER, challenge: challenge)
        print("  Expected:  \(bytesToHex(expected))")

        // Send AUTH_CHECK
        var params: [UInt8] = [0x01]
        params.append(contentsOf: challenge)
        let sn = sendCommand(opcode: OP_AUTH_CHECK, params: params, app: APP_MIUI)

        // Wait for response
        guard let rsp = waitResponse() else {
            print("❌ AUTH_CHECK timed out")
            return false
        }
        if rsp.status != 0 {
            print("❌ AUTH_CHECK rejected (status=\(rsp.status))")
            return false
        }
        let data = rsp.data
        guard data.count >= 17 else {
            print("❌ AUTH_CHECK response too short (\(data.count) bytes)")
            return false
        }
        let deviceResponse = Array(data[1..<17])
        print("  Device:    \(bytesToHex(deviceResponse))")

        if deviceResponse != expected {
            print("❌ Auth mismatch!")
            return false
        }
        print("  ✅ Challenge verified")

        // Send AUTH_SEND_CALC_RESULT
        _ = sendCommand(opcode: OP_AUTH_CONFIRM, params: [0x01, 0x00], app: APP_MIUI)
        guard let confirmRsp = waitResponse() else {
            print("❌ AUTH_CONFIRM timed out")
            return false
        }
        if confirmRsp.status != 0 {
            print("❌ AUTH_CONFIRM rejected")
            return false
        }

        authenticated = true
        print("✅ Authentication complete!\n")
        return true
    }

    // MARK: Answer device-initiated challenge

    func answerDeviceChallenge(_ frame: RCSPFrame) {
        let data = frame.data
        guard data.count >= 17 && data[0] == 0x01 else { return }
        let challenge = Array(data[1..<17])
        let response = authTransform(addr6: ADDR6_PLACEHOLDER, challenge: challenge)
        var payload: [UInt8] = [0x00, frame.sn, 0x01]
        payload.append(contentsOf: response)
        sendFrame(flags: APP_MIUI, opcode: OP_AUTH_CHECK, payload: payload)
        print("  ↩️ Answered device challenge")
    }

    // MARK: Query Battery

    func queryBattery() -> [(level: Int, charging: Bool)]? {
        print("🔋 Querying battery...")
        _ = sendCommand(opcode: OP_GET_TARGET_INFO, params: [0xFF, 0xFF, 0xFF, 0xFF], app: APP_EARPHONE)
        guard let rsp = waitResponse() else {
            print("❌ GET_TARGET_INFO timed out")
            return nil
        }
        if rsp.status != 0 {
            print("❌ GET_TARGET_INFO failed (status=\(rsp.status))")
            return nil
        }

        // Parse TLVs
        let data = rsp.data
        var batteries: [(Int, Bool)] = []
        var deviceName = ""
        var i = 0
        while i + 2 <= data.count {
            let len = Int(data[i])
            guard len >= 1, i + 1 + len <= data.count else { break }
            let typ = data[i + 1]
            let val = Array(data[(i + 2)..<(i + 1 + len)])
            switch typ {
            case 0: deviceName = String(bytes: val, encoding: .utf8) ?? "?"
            case 7:
                batteries = val.map { byte in
                    if byte == 0xFF { return (-1, false) }
                    return (Int(byte & 0x7F), byte & 0x80 != 0)
                }
            default: break
            }
            i += 1 + len
        }

        if !deviceName.isEmpty { print("  Device: \(deviceName)") }
        for (idx, b) in batteries.enumerated() {
            let component = idx == 0 ? "Left" : idx == 1 ? "Right" : "Case"
            if b.0 < 0 {
                print("  \(component): disconnected")
            } else {
                print("  \(component): \(b.0)% \(b.1 ? "⚡charging" : "")")
            }
        }
        return batteries
    }

    // MARK: Query ANC

    func queryANC() {
        print("🔇 Querying ANC state...")
        var params: [UInt8] = []
        let configID: UInt16 = 0x000B  // ANC state
        params.append(contentsOf: withUnsafeBytes(of: configID.bigEndian) { Array($0) })
        _ = sendCommand(opcode: OP_GET_DEVICE_CONFIG, params: params, app: APP_EARPHONE)
        guard let rsp = waitResponse() else {
            print("❌ GET_DEVICE_CONFIG timed out")
            return
        }
        let data = rsp.data
        if data.count >= 5 {
            let mode = data[3]
            let level = data.count > 4 ? data[4] : 0
            let modeName = mode == 0 ? "Off" : mode == 1 ? "ANC" : mode == 2 ? "Transparency" : "?\(mode)"
            print("  ANC: \(modeName), level: \(level)")
        }
    }

    // MARK: IOBluetoothRFCOMMChannelDelegate

    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!,
                           data dataPointer: UnsafeMutableRawPointer!,
                           length dataLength: Int) {
        let bytes = [UInt8](UnsafeBufferPointer(
            start: dataPointer.assumingMemoryBound(to: UInt8.self),
            count: dataLength
        ))
        rxBuffer.append(contentsOf: bytes)

        while let frame = extractFrame(from: &rxBuffer) {
            print("  ← [\(frame.isCommand ? "cmd" : "rsp") op=0x\(String(format: "%02x", frame.opcode)) status=\(frame.status)] \(bytesToHexSpaced(frame.payload))")

            // Handle device-initiated auth challenge
            if frame.isCommand && frame.opcode == OP_AUTH_CHECK {
                answerDeviceChallenge(frame)
                continue
            }

            pendingResponse = frame
            responseSemaphore.signal()
        }
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        print("⚠️  RFCOMM channel closed")
        connected = false
        responseSemaphore.signal()
    }
}

// MARK: - Main

print("═══════════════════════════════════════════════════════════")
print("  Xiaomi/Redmi Buds RFCOMM PoC — JieLi RCSP Protocol")
print("═══════════════════════════════════════════════════════════")

// Self-test auth transform
print("\n🧪 Auth transform self-test:")
guard selfTest() else {
    print("❌ Self-test failed! Auth implementation is broken.")
    exit(1)
}
print("✅ All test vectors passed\n")

// Parse args
let args = CommandLine.arguments
let macAddress = args.count > 1 ? args[1] : "B8:53:84:6B:BD:88"
let channelID = args.count > 2 ? UInt8(args[2])! : 28

print("Target: \(macAddress) channel \(channelID)")
print("⚠️  Make sure the earbuds are paired with this Mac!\n")

// Find device
guard let device = IOBluetoothDevice(addressString: macAddress) else {
    print("❌ Device not found: \(macAddress)")
    print("   → Pair the earbuds in System Settings → Bluetooth first")
    exit(1)
}

let client = BudsClient(device: device, channelID: BluetoothRFCOMMChannelID(channelID))

// Connect RFCOMM
guard client.connect() else {
    print("\n💡 Troubleshooting:")
    print("   1. Is the device paired with this Mac?")
    print("   2. Is the device connected to another host (phone)?")
    print("   3. Try disconnecting from phone first")
    exit(1)
}

// Run on a background thread since RFCOMM callbacks need RunLoop
DispatchQueue.global().async {
    // Authenticate
    guard client.authenticate() else {
        print("Authentication failed")
        exit(1)
    }

    // Query battery
    _ = client.queryBattery()
    print()

    // Probe config ids (read-only) — 2 gestures, 3 auto-answer, 7 EQ, 10 noise
    // cycle, 11 ANC, 37 adaptive ANC, 41 adaptive sense, 47 low latency,
    // 54 scene rendering, 103 commute immerse
    if CommandLine.arguments.contains("--probe") {
        print("🔎 Probing device config…")
        client.probeConfig(ids: [2, 3, 7, 10, 11, 37, 41, 47, 54, 103])
        // 4 dual connection, 12 in-ear, 29/36/79 spatial, 59 personal NR, 72 adaptive volume
        client.probeConfig(ids: [4, 12, 29, 36, 59, 72, 79])
        print()
    }

    // Optional: --setattr <type> <hexvalue> sends SET_TARGET_INFO (0x08) `len | type | value`
    for (idx, arg) in CommandLine.arguments.enumerated() where arg == "--setattr" {
        let a = CommandLine.arguments
        guard idx + 2 < a.count, let type = UInt8(a[idx + 1]) else { continue }
        let value = hexToBytes(a[idx + 2])
        print("🧩 SET_TARGET_INFO attr=\(type) value=\(bytesToHex(value))")
        if let rsp = client.request(opcode: 0x08, params: [UInt8(1 + value.count), type] + value) {
            print("  status=\(rsp.status)")
        }
        Thread.sleep(forTimeInterval: 0.5)
    }

    // Optional: --runinfo dumps GET_DEVICE_RUN_INFO (0x09) attributes
    if CommandLine.arguments.contains("--runinfo") {
        print("🏃 GET_DEVICE_RUN_INFO…")
        if let rsp = client.request(opcode: 0x09, params: [0xFF, 0xFF, 0xFF, 0xFF]) {
            print("  status=\(rsp.status) data=\(bytesToHexSpaced(rsp.data))")
        }
        print()
    }

    // Optional ANC switch test: --anc <0|1|2> via SET_TARGET_INFO attr 4
    if let idx = CommandLine.arguments.firstIndex(of: "--anc"),
       idx + 1 < CommandLine.arguments.count,
       let mode = UInt8(CommandLine.arguments[idx + 1]) {
        print("🔇 Setting ANC mode \(mode) via SET_TARGET_INFO…")
        if let rsp = client.request(opcode: 0x08, params: [0x02, 0x04, mode]) {
            print("  status=\(rsp.status)")
        }
        Thread.sleep(forTimeInterval: 0.5)
        client.probeConfig(ids: [11])
        print()
    }

    // Optional raw config writes (repeatable): --setcfg <id> <hexvalue>, e.g. --setcfg 11 0100
    let cliArgs = CommandLine.arguments
    for (idx, arg) in cliArgs.enumerated() where arg == "--setcfg" {
        guard idx + 2 < cliArgs.count, let id = UInt16(cliArgs[idx + 1]) else { continue }
        let value = hexToBytes(cliArgs[idx + 2])
        print("✏️  SET_DEVICE_CONFIG id=\(id) value=\(bytesToHex(value))")
        let tlv: [UInt8] = [UInt8(2 + value.count), UInt8(id >> 8), UInt8(id & 0xFF)] + value
        if let rsp = client.request(opcode: OP_SET_DEVICE_CONFIG, params: tlv) {
            print("  status=\(rsp.status)")
        }
        Thread.sleep(forTimeInterval: 0.5)
        client.probeConfig(ids: [id])
        print()
    }

    print("═══════════════════════════════════════════════════════════")
    print("  Done! Connection and auth successful.")
    print("═══════════════════════════════════════════════════════════")

    // Keep alive briefly for any async responses
    Thread.sleep(forTimeInterval: 1.0)
    exit(0)
}

// Run the main RunLoop for IOBluetooth callbacks
RunLoop.main.run(until: Date(timeIntervalSinceNow: 30))
