// ProtocolTestFixtures.swift
// XiaomiEarbuds
//
// Static test fixtures for Xiaomi protocol unit tests.
// Contains raw frame bytes and expected parsed results for each command.

import Foundation

// MARK: - Protocol Constants

enum XiaomiProtocolFixtures {

    /// Frame magic bytes
    static let magic: [UInt8] = [0xFE, 0xDC]

    // MARK: - Opcodes

    enum Opcode {
        // Requests (Host → Device)
        static let getBattery: UInt8 = 0x01
        static let getDeviceInfo: UInt8 = 0x02
        static let getANCMode: UInt8 = 0x03
        static let setANCMode: UInt8 = 0x04
        static let getANCDepth: UInt8 = 0x05
        static let setANCDepth: UInt8 = 0x06
        static let getCodec: UInt8 = 0x07
        static let setCodec: UInt8 = 0x08
        static let getSoundMode: UInt8 = 0x09
        static let setSoundMode: UInt8 = 0x0A
        static let getGestureConfig: UInt8 = 0x0B
        static let setGestureConfig: UInt8 = 0x0C
        static let getSpatialAudio: UInt8 = 0x0D
        static let setSpatialAudio: UInt8 = 0x0E
        static let getInEarStatus: UInt8 = 0x0F
        static let setInEarDetection: UInt8 = 0x10
        static let getDualConnection: UInt8 = 0x11
        static let setDualConnection: UInt8 = 0x12
        static let findDevice: UInt8 = 0x13
        static let setDeviceName: UInt8 = 0x14
        static let getDeviceName: UInt8 = 0x15
        static let getSmartANC: UInt8 = 0x16
        static let setSmartANC: UInt8 = 0x17
        static let startEarTipFitTest: UInt8 = 0x18
        static let getSceneRendering: UInt8 = 0x19
        static let setSceneRendering: UInt8 = 0x1A
        static let getHeadTracking: UInt8 = 0x1B
        static let setHeadTracking: UInt8 = 0x1C

        // Responses (Device → Host): request opcode | 0x80
        static let batteryResponse: UInt8 = 0x81
        static let deviceInfoResponse: UInt8 = 0x82
        static let ancModeResponse: UInt8 = 0x83
        static let setANCModeAck: UInt8 = 0x84
        static let ancDepthResponse: UInt8 = 0x85
        static let codecResponse: UInt8 = 0x87
        static let soundModeResponse: UInt8 = 0x89
        static let gestureConfigResponse: UInt8 = 0x8B
        static let spatialAudioResponse: UInt8 = 0x8D
        static let inEarStatusResponse: UInt8 = 0x8F
        static let dualConnectionResponse: UInt8 = 0x91
        static let deviceNameResponse: UInt8 = 0x95
        static let smartANCResponse: UInt8 = 0x96
        static let sceneRenderingResponse: UInt8 = 0x99
        static let headTrackingResponse: UInt8 = 0x9B

        // Async events
        static let batteryChanged: UInt8 = 0xE0
        static let ancModeChanged: UInt8 = 0xE1
        static let inEarChanged: UInt8 = 0xE2
    }

    // MARK: - ANC Mode Values

    enum ANCMode: UInt8 {
        case off = 0x00
        case noiseCancellation = 0x01
        case transparency = 0x02
        case adaptive = 0x03
    }

    // MARK: - Codec Values

    enum CodecID: UInt8 {
        case sbc = 0x01
        case aac = 0x02
        case ldac = 0x03
    }

    // MARK: - Sound Mode Values

    enum SoundMode: UInt8 {
        case balanced = 0x00
        case bassBoost = 0x01
        case trebleBoost = 0x02
        case vocal = 0x03
        case volumeBoost = 0x04
    }

    // MARK: - CRC-16-CCITT

    /// Compute CRC-16-CCITT over the given bytes.
    /// Polynomial: 0x1021, Init: 0xFFFF, No reflection, No final XOR.
    static func crc16ccitt(_ data: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in data {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ 0x1021
                } else {
                    crc = crc << 1
                }
                crc &= 0xFFFF
            }
        }
        return crc
    }

    /// Build a complete Xiaomi protocol frame.
    static func buildFrame(opcode: UInt8, seqNum: UInt8, payload: [UInt8]) -> Data {
        let length = UInt16(payload.count)
        var body: [UInt8] = [opcode, seqNum]
        body.append(UInt8(length & 0xFF))
        body.append(UInt8((length >> 8) & 0xFF))
        body.append(contentsOf: payload)

        let crc = crc16ccitt(body)
        var frame: [UInt8] = magic
        frame.append(contentsOf: body)
        frame.append(UInt8(crc & 0xFF))
        frame.append(UInt8((crc >> 8) & 0xFF))
        return Data(frame)
    }

    // MARK: - Request Fixtures (Host → Device)

    /// GET_BATTERY request: no payload
    static let getBatteryRequest = buildFrame(opcode: Opcode.getBattery, seqNum: 0x00, payload: [])

    /// SET_ANC_MODE request: set to Noise Cancellation
    static let setANCModeNCRequest = buildFrame(opcode: Opcode.setANCMode, seqNum: 0x01, payload: [ANCMode.noiseCancellation.rawValue])

    /// SET_ANC_MODE request: set to Transparency
    static let setANCModeTransparencyRequest = buildFrame(opcode: Opcode.setANCMode, seqNum: 0x02, payload: [ANCMode.transparency.rawValue])

    /// SET_ANC_MODE request: set to Off
    static let setANCModeOffRequest = buildFrame(opcode: Opcode.setANCMode, seqNum: 0x03, payload: [ANCMode.off.rawValue])

    /// SET_ANC_DEPTH request: set depth to 75
    static let setANCDepth75Request = buildFrame(opcode: Opcode.setANCDepth, seqNum: 0x04, payload: [0x4B])

    /// SET_CODEC request: set to LDAC
    static let setCodecLDACRequest = buildFrame(opcode: Opcode.setCodec, seqNum: 0x05, payload: [CodecID.ldac.rawValue])

    /// SET_SOUND_MODE request: set to Balanced
    static let setSoundModeBalancedRequest = buildFrame(opcode: Opcode.setSoundMode, seqNum: 0x06, payload: [SoundMode.balanced.rawValue])

    /// SET_GESTURE_CONFIG request: left double tap → play/pause
    static let setGestureLeftDoubleTapRequest = buildFrame(opcode: Opcode.setGestureConfig, seqNum: 0x07, payload: [0x01, 0x01])

    /// SET_SPATIAL_AUDIO request: spatial on + head tracking on (flags = 0x03)
    static let setSpatialAudioOnRequest = buildFrame(opcode: Opcode.setSpatialAudio, seqNum: 0x08, payload: [0x03])

    /// FIND_DEVICE request: start beeping
    static let findDeviceStartRequest = buildFrame(opcode: Opcode.findDevice, seqNum: 0x09, payload: [0x01])

    /// FIND_DEVICE request: stop beeping
    static let findDeviceStopRequest = buildFrame(opcode: Opcode.findDevice, seqNum: 0x0A, payload: [0x00])

    /// GET_DEVICE_INFO request: no payload
    static let getDeviceInfoRequest = buildFrame(opcode: Opcode.getDeviceInfo, seqNum: 0x0B, payload: [])

    /// GET_GESTURE_CONFIG request: no payload
    static let getGestureConfigRequest = buildFrame(opcode: Opcode.getGestureConfig, seqNum: 0x0C, payload: [])

    /// SET_HEAD_TRACKING request: enable
    static let setHeadTrackingOnRequest = buildFrame(opcode: Opcode.setHeadTracking, seqNum: 0x0D, payload: [0x01])

    /// SET_SCENE_RENDERING request: Movie preset
    static let setSceneRenderingMovieRequest = buildFrame(opcode: Opcode.setSceneRendering, seqNum: 0x0E, payload: [0x01])

    // MARK: - Response Fixtures (Device → Host)

    /// Battery response: L=100%, R=100%, Case=1%, not charging
    static let batteryResponse = buildFrame(
        opcode: Opcode.batteryResponse, seqNum: 0x00,
        payload: [0x64, 0x64, 0x01, 0x00]
    )

    /// Battery response: L=85%, R=80%, Case=50%, left+right charging
    static let batteryResponseCharging = buildFrame(
        opcode: Opcode.batteryResponse, seqNum: 0x01,
        payload: [0x55, 0x50, 0x32, 0x03]
    )

    /// ANC mode response: current mode = Noise Cancellation
    static let ancModeResponseNC = buildFrame(
        opcode: Opcode.ancModeResponse, seqNum: 0x01,
        payload: [ANCMode.noiseCancellation.rawValue]
    )

    /// ANC mode response: current mode = Transparency
    static let ancModeResponseTransparency = buildFrame(
        opcode: Opcode.ancModeResponse, seqNum: 0x02,
        payload: [ANCMode.transparency.rawValue]
    )

    /// ANC mode response: current mode = Off
    static let ancModeResponseOff = buildFrame(
        opcode: Opcode.ancModeResponse, seqNum: 0x03,
        payload: [ANCMode.off.rawValue]
    )

    /// SET_ANC_MODE ACK: success
    static let setANCModeAckSuccess = buildFrame(
        opcode: Opcode.setANCModeAck, seqNum: 0x01,
        payload: [0x00]
    )

    /// ANC depth response: depth = 75
    static let ancDepthResponse75 = buildFrame(
        opcode: Opcode.ancDepthResponse, seqNum: 0x04,
        payload: [0x4B]
    )

    /// Device info response: firmware "3.2.2.6", model "M2417E1"
    static let deviceInfoResponse: Data = {
        let fw = Array("3.2.2.6".utf8)
        let model = Array("M2417E1".utf8)
        var payload: [UInt8] = [UInt8(fw.count)]
        payload.append(contentsOf: fw)
        payload.append(UInt8(model.count))
        payload.append(contentsOf: model)
        return buildFrame(opcode: Opcode.deviceInfoResponse, seqNum: 0x0B, payload: payload)
    }()

    /// Codec response: LDAC, 48.0 kHz (0xBB80 = 48000)
    static let codecResponseLDAC = buildFrame(
        opcode: Opcode.codecResponse, seqNum: 0x05,
        payload: [CodecID.ldac.rawValue, 0x80, 0xBB]
    )

    /// Codec response: AAC, 44.1 kHz (0xAC44 = 44100)
    static let codecResponseAAC = buildFrame(
        opcode: Opcode.codecResponse, seqNum: 0x06,
        payload: [CodecID.aac.rawValue, 0x44, 0xAC]
    )

    /// Sound mode response: Balanced
    static let soundModeResponseBalanced = buildFrame(
        opcode: Opcode.soundModeResponse, seqNum: 0x06,
        payload: [SoundMode.balanced.rawValue]
    )

    /// Sound mode response: Bass Boost
    static let soundModeResponseBass = buildFrame(
        opcode: Opcode.soundModeResponse, seqNum: 0x07,
        payload: [SoundMode.bassBoost.rawValue]
    )

    /// Gesture config response: all 10 default mappings
    static let gestureConfigResponseDefault = buildFrame(
        opcode: Opcode.gestureConfigResponse, seqNum: 0x0C,
        payload: [
            0x0A,       // count = 10
            0x00, 0x00, // Left single tap → None
            0x01, 0x01, // Left double tap → Play/Pause
            0x02, 0x02, // Left triple tap → Next Track
            0x03, 0x06, // Left long press → Cycle ANC
            0x04, 0x05, // Left swipe → Volume Down
            0x05, 0x00, // Right single tap → None
            0x06, 0x01, // Right double tap → Play/Pause
            0x07, 0x03, // Right triple tap → Previous Track
            0x08, 0x06, // Right long press → Cycle ANC
            0x09, 0x04, // Right swipe → Volume Up
        ]
    )

    /// Spatial audio response: immersive=on, headTracking=on (flags = 0x03)
    static let spatialAudioResponseOn = buildFrame(
        opcode: Opcode.spatialAudioResponse, seqNum: 0x08,
        payload: [0x03]
    )

    /// Spatial audio response: all off (flags = 0x00)
    static let spatialAudioResponseOff = buildFrame(
        opcode: Opcode.spatialAudioResponse, seqNum: 0x09,
        payload: [0x00]
    )

    /// In-ear status: both in
    static let inEarStatusBothIn = buildFrame(
        opcode: Opcode.inEarStatusResponse, seqNum: 0x0A,
        payload: [0x01, 0x01]
    )

    /// In-ear status: both out
    static let inEarStatusBothOut = buildFrame(
        opcode: Opcode.inEarStatusResponse, seqNum: 0x0B,
        payload: [0x00, 0x00]
    )

    /// In-ear status: left in, right out
    static let inEarStatusLeftOnly = buildFrame(
        opcode: Opcode.inEarStatusResponse, seqNum: 0x0C,
        payload: [0x01, 0x00]
    )

    /// Dual connection response: enabled
    static let dualConnectionEnabled = buildFrame(
        opcode: Opcode.dualConnectionResponse, seqNum: 0x0D,
        payload: [0x01]
    )

    /// Smart ANC response: enabled
    static let smartANCEnabled = buildFrame(
        opcode: Opcode.smartANCResponse, seqNum: 0x0E,
        payload: [0x01]
    )

    /// Head tracking response: enabled
    static let headTrackingEnabled = buildFrame(
        opcode: Opcode.headTrackingResponse, seqNum: 0x0F,
        payload: [0x01]
    )

    /// Scene rendering response: Movie preset
    static let sceneRenderingMovie = buildFrame(
        opcode: Opcode.sceneRenderingResponse, seqNum: 0x10,
        payload: [0x01]
    )

    /// Device name response: "REDMI Buds 8 Pro"
    static let deviceNameResponse: Data = {
        let name = Array("REDMI Buds 8 Pro".utf8)
        var payload: [UInt8] = [UInt8(name.count)]
        payload.append(contentsOf: name)
        return buildFrame(opcode: Opcode.deviceNameResponse, seqNum: 0x11, payload: payload)
    }()

    /// Ear tip fit test response: complete, both good seal
    static let earTipFitTestGood = buildFrame(
        opcode: 0x98, seqNum: 0x12,
        payload: [0x00, 0x02, 0x02]
    )

    // MARK: - Event Fixtures (Unsolicited)

    /// Battery changed event: L=95%, R=90%, Case=0xFF (unavailable), not charging
    static let batteryChangedEvent = buildFrame(
        opcode: Opcode.batteryChanged, seqNum: 0x00,
        payload: [0x5F, 0x5A, 0xFF, 0x00]
    )

    /// ANC mode changed event: switched to Transparency
    static let ancModeChangedEvent = buildFrame(
        opcode: Opcode.ancModeChanged, seqNum: 0x01,
        payload: [ANCMode.transparency.rawValue]
    )

    /// In-ear changed event: right bud removed
    static let inEarChangedEvent = buildFrame(
        opcode: Opcode.inEarChanged, seqNum: 0x02,
        payload: [0x01, 0x00]
    )

    // MARK: - Malformed Frame Fixtures (for error handling tests)

    /// Wrong magic bytes
    static let malformedWrongMagic = Data([0xAB, 0xCD, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00])

    /// Truncated frame (too short — no CRC)
    static let malformedTruncated = Data([0xFE, 0xDC, 0x01, 0x00, 0x04, 0x00])

    /// Invalid CRC
    static let malformedBadCRC: Data = {
        var frame = Array(buildFrame(opcode: 0x81, seqNum: 0x00, payload: [0x64, 0x64, 0x01, 0x00]))
        // Corrupt the last byte (CRC high byte)
        frame[frame.count - 1] ^= 0xFF
        return Data(frame)
    }()

    /// Payload length exceeds actual data
    static let malformedLengthOverflow = Data([
        0xFE, 0xDC,  // Magic
        0x01,        // Opcode
        0x00,        // SeqNum
        0xFF, 0x00,  // Length = 255 (but only 2 bytes follow)
        0x64, 0x64,  // Incomplete payload
        0x00, 0x00,  // CRC (invalid anyway)
    ])

    /// Empty frame (just magic)
    static let malformedEmpty = Data([0xFE, 0xDC])

    // MARK: - Expected Parsed Results

    struct BatteryResult {
        let left: UInt8
        let right: UInt8
        let caseBattery: UInt8
        let isLeftCharging: Bool
        let isRightCharging: Bool
        let isCaseCharging: Bool
    }

    struct DeviceInfoResult {
        let firmwareVersion: String
        let modelNumber: String
    }

    struct CodecResult {
        let codecID: UInt8
        let sampleRate: UInt16
    }

    struct GestureMapping {
        let slot: UInt8
        let action: UInt8
    }

    struct GestureConfigResult {
        let mappings: [GestureMapping]
    }

    struct InEarResult {
        let leftInEar: Bool
        let rightInEar: Bool
    }

    struct SpatialAudioResult {
        let spatialEnabled: Bool
        let headTrackingEnabled: Bool
        let dolbyMode: Bool
        let fixedPosition: Bool
    }

    struct EarTipFitResult {
        let status: UInt8
        let leftSeal: UInt8
        let rightSeal: UInt8
    }

    // MARK: - Expected Values

    /// Expected parse result for `batteryResponse`
    static let expectedBattery = BatteryResult(
        left: 100, right: 100, caseBattery: 1,
        isLeftCharging: false, isRightCharging: false, isCaseCharging: false
    )

    /// Expected parse result for `batteryResponseCharging`
    static let expectedBatteryCharging = BatteryResult(
        left: 85, right: 80, caseBattery: 50,
        isLeftCharging: true, isRightCharging: true, isCaseCharging: false
    )

    /// Expected parse result for `deviceInfoResponse`
    static let expectedDeviceInfo = DeviceInfoResult(
        firmwareVersion: "3.2.2.6",
        modelNumber: "M2417E1"
    )

    /// Expected parse result for `codecResponseLDAC`
    static let expectedCodecLDAC = CodecResult(codecID: CodecID.ldac.rawValue, sampleRate: 48000)

    /// Expected parse result for `codecResponseAAC`
    static let expectedCodecAAC = CodecResult(codecID: CodecID.aac.rawValue, sampleRate: 44100)

    /// Expected gesture config: 10 default mappings
    static let expectedGestureConfig = GestureConfigResult(mappings: [
        GestureMapping(slot: 0x00, action: 0x00),
        GestureMapping(slot: 0x01, action: 0x01),
        GestureMapping(slot: 0x02, action: 0x02),
        GestureMapping(slot: 0x03, action: 0x06),
        GestureMapping(slot: 0x04, action: 0x05),
        GestureMapping(slot: 0x05, action: 0x00),
        GestureMapping(slot: 0x06, action: 0x01),
        GestureMapping(slot: 0x07, action: 0x03),
        GestureMapping(slot: 0x08, action: 0x06),
        GestureMapping(slot: 0x09, action: 0x04),
    ])

    /// Expected spatial audio result for `spatialAudioResponseOn`
    static let expectedSpatialOn = SpatialAudioResult(
        spatialEnabled: true, headTrackingEnabled: true,
        dolbyMode: false, fixedPosition: false
    )

    /// Expected in-ear result for `inEarStatusBothIn`
    static let expectedInEarBothIn = InEarResult(leftInEar: true, rightInEar: true)

    /// Expected ear tip fit for `earTipFitTestGood`
    static let expectedEarTipFitGood = EarTipFitResult(status: 0x00, leftSeal: 0x02, rightSeal: 0x02)
}
