import Foundation

// MARK: - RCSP Frame

/// A parsed RCSP protocol frame.
struct RCSPFrame: Sendable {
    let flags: UInt8
    let opcode: UInt8
    let payload: [UInt8]

    var isCommand: Bool { flags & 0x80 != 0 }
    var targetApp: UInt8 { flags & 0x07 }

    var status: UInt8 { payload.first ?? 0xFF }

    /// Sequence number — position depends on command vs response.
    var sn: UInt8 {
        if isCommand { return payload.first ?? 0xFF }
        return payload.count > 1 ? payload[1] : 0xFF
    }

    /// Payload data after the status/sn header bytes.
    var data: [UInt8] {
        let skip = isCommand ? 1 : 2
        return payload.count > skip ? Array(payload[skip...]) : []
    }
}

// MARK: - Response Parser

/// Parses RCSP frames from a byte buffer and interprets their payloads.
struct ResponseParser: Sendable {

    // MARK: - Frame Extraction

    /// Extracts the next complete RCSP frame from the buffer, consuming bytes.
    /// Returns `nil` if no complete frame is available yet.
    static func extractFrame(from buffer: inout [UInt8]) -> RCSPFrame? {
        let magic = ProtocolConstants.magic
        guard let start = buffer.indices.first(where: { i in
            i + 2 < buffer.count &&
            buffer[i] == magic[0] && buffer[i+1] == magic[1] && buffer[i+2] == magic[2]
        }) else { return nil }

        if start > 0 { buffer.removeFirst(start) }
        guard buffer.count >= 7 else { return nil }

        let plen = Int(buffer[5]) << 8 | Int(buffer[6])
        let end = 7 + plen
        guard buffer.count > end else { return nil }
        guard buffer[end] == ProtocolConstants.trailer else {
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

    // MARK: - TLV Decoding

    /// Target/run-info attributes: `len(u8) | type(u8) | value(len-1)`.
    static func parseTLVsU8(_ data: [UInt8]) -> [(type: UInt8, value: [UInt8])] {
        var out: [(UInt8, [UInt8])] = []
        var i = 0
        while i + 2 <= data.count {
            let len = Int(data[i])
            guard len >= 1, i + 1 + len <= data.count else { break }
            out.append((data[i + 1], Array(data[(i + 2)..<(i + 1 + len)])))
            i += 1 + len
        }
        return out
    }

    /// Device-config TLVs: `len(u8) | id(u16 BE) | value(len-2)`.
    static func parseTLVsU16(_ data: [UInt8]) -> [UInt16: [UInt8]] {
        var out: [UInt16: [UInt8]] = [:]
        var i = 0
        while i + 3 <= data.count {
            let len = Int(data[i])
            guard len >= 2, i + 1 + len <= data.count else { break }
            let id = UInt16(data[i + 1]) << 8 | UInt16(data[i + 2])
            out[id] = Array(data[(i + 3)..<(i + 1 + len)])
            i += 1 + len
        }
        return out
    }

    // MARK: - Device Info (GET_TARGET_INFO)

    struct DeviceInfo: Sendable {
        var name: String = ""
        var firmwareVersion: String = ""
        var battery: BatteryInfo?
    }

    static func parseDeviceInfo(data: [UInt8]) -> DeviceInfo {
        var info = DeviceInfo()
        for (type, value) in parseTLVsU8(data) {
            switch type {
            case 0:
                info.name = String(bytes: value, encoding: .utf8) ?? ""
            case ProtocolConstants.targetInfoFirmware where value.count >= 2:
                // BCD nibbles: `32 26` → 3.2.2.6
                info.firmwareVersion = value.prefix(2)
                    .flatMap { [$0 >> 4, $0 & 0x0F] }
                    .map(String.init)
                    .joined(separator: ".")
            case 7:
                info.battery = parseBattery(value)
            default:
                break
            }
        }
        return info
    }

    /// Multi-battery bytes `[left, right, case]`: `level = v & 0x7F`,
    /// charging = bit 7, `0xFF` = unknown.
    static func parseBattery(_ bytes: [UInt8]) -> BatteryInfo {
        func level(at index: Int) -> BatteryLevel {
            guard index < bytes.count, bytes[index] != 0xFF else { return .unknown }
            return BatteryLevel(level: Int(bytes[index] & 0x7F), isCharging: bytes[index] & 0x80 != 0)
        }
        return BatteryInfo(left: level(at: 0), right: level(at: 1), batteryCase: level(at: 2))
    }

    // MARK: - ANC

    /// Decodes an ANC `[mode, level]` value (config 11, notify 0x0B, run-info 9).
    static func parseANC(_ value: [UInt8]) -> (mode: ANCMode, level: UInt8)? {
        guard let first = value.first, let mode = ANCMode(wireByte: first) else { return nil }
        return (mode, value.count > 1 ? value[1] : 0)
    }

    // MARK: - Gestures (config 2)

    /// Decodes repeated `[type, left, right]` triples.
    static func parseGestures(_ value: [UInt8]) -> [GestureType: GestureBinding] {
        var out: [GestureType: GestureBinding] = [:]
        var i = 0
        while i + 2 < value.count {
            if let type = GestureType(rawValue: value[i]),
               let left = GestureAction(wireByte: value[i + 1], for: type),
               let right = GestureAction(wireByte: value[i + 2], for: type) {
                out[type] = GestureBinding(left: left, right: right)
            }
            i += 3
        }
        return out
    }
}
