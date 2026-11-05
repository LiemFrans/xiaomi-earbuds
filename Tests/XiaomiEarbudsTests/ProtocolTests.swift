// ProtocolTests.swift
// XiaomiEarbuds
//
// Unit tests for the Xiaomi protocol: command building, response parsing,
// CRC validation, frame validation, and round-trip correctness.

import Foundation
import Testing

@Suite("Xiaomi Protocol")
struct ProtocolTests {

    typealias Fixtures = XiaomiProtocolFixtures
    typealias Op = Fixtures.Opcode

    // MARK: - CRC Tests

    @Suite("CRC-16-CCITT")
    struct CRCTests {

        @Test("Known vector: empty input")
        func crcEmpty() {
            let crc = XiaomiProtocolFixtures.crc16ccitt([])
            #expect(crc == 0xFFFF, "CRC of empty data should be initial value 0xFFFF")
        }

        @Test("Known vector: single byte 0x00")
        func crcSingleZero() {
            let crc = XiaomiProtocolFixtures.crc16ccitt([0x00])
            #expect(crc == 0xE1F0)
        }

        @Test("Known vector: ASCII '123456789'")
        func crcASCII123456789() {
            let data = Array("123456789".utf8)
            let crc = XiaomiProtocolFixtures.crc16ccitt(data)
            #expect(crc == 0x29B1)
        }

        @Test("CRC is deterministic")
        func crcDeterministic() {
            let data: [UInt8] = [0x01, 0x00, 0x00, 0x00]
            let crc1 = XiaomiProtocolFixtures.crc16ccitt(data)
            let crc2 = XiaomiProtocolFixtures.crc16ccitt(data)
            #expect(crc1 == crc2)
        }

        @Test("CRC embedded in frame matches computed CRC")
        func crcInFrameMatches() {
            let frame = Fixtures.batteryResponse
            let embeddedCRC = UInt16(frame[frame.count - 2]) | (UInt16(frame[frame.count - 1]) << 8)
            let body = Array(frame[2 ..< frame.count - 2])
            let computed = XiaomiProtocolFixtures.crc16ccitt(body)
            #expect(embeddedCRC == computed)
        }
    }

    // MARK: - Command Builder Tests

    @Suite("CommandBuilder")
    struct CommandBuilderTests {

        @Test("GET_BATTERY produces valid frame with no payload")
        func getBattery() {
            let frame = Fixtures.getBatteryRequest
            #expect(frame[0] == 0xFE)
            #expect(frame[1] == 0xDC)
            #expect(frame[2] == Op.getBattery)
            #expect(frame[4] == 0x00)
            #expect(frame[5] == 0x00)
            #expect(frame.count == 8)
        }

        @Test("SET_ANC_MODE includes mode byte in payload")
        func setANCMode() {
            let frame = Fixtures.setANCModeNCRequest
            #expect(frame[2] == Op.setANCMode)
            #expect(frame[4] == 0x01)
            #expect(frame[5] == 0x00)
            #expect(frame[6] == Fixtures.ANCMode.noiseCancellation.rawValue)
        }

        @Test("SET_ANC_DEPTH includes depth value")
        func setANCDepth() {
            let frame = Fixtures.setANCDepth75Request
            #expect(frame[2] == Op.setANCDepth)
            #expect(frame[6] == 0x4B)
        }

        @Test("SET_CODEC includes codec ID")
        func setCodec() {
            let frame = Fixtures.setCodecLDACRequest
            #expect(frame[2] == Op.setCodec)
            #expect(frame[6] == Fixtures.CodecID.ldac.rawValue)
        }

        @Test("SET_GESTURE_CONFIG includes slot and action")
        func setGesture() {
            let frame = Fixtures.setGestureLeftDoubleTapRequest
            #expect(frame[2] == Op.setGestureConfig)
            #expect(frame[4] == 0x02)
            #expect(frame[6] == 0x01)
            #expect(frame[7] == 0x01)
        }

        @Test("SET_SPATIAL_AUDIO includes flags byte")
        func setSpatialAudio() {
            let frame = Fixtures.setSpatialAudioOnRequest
            #expect(frame[2] == Op.setSpatialAudio)
            #expect(frame[6] == 0x03)
        }

        @Test("FIND_DEVICE start/stop have correct action byte")
        func findDevice() {
            let start = Fixtures.findDeviceStartRequest
            #expect(start[6] == 0x01)
            let stop = Fixtures.findDeviceStopRequest
            #expect(stop[6] == 0x00)
        }

        @Test("SET_HEAD_TRACKING enable")
        func setHeadTracking() {
            let frame = Fixtures.setHeadTrackingOnRequest
            #expect(frame[2] == Op.setHeadTracking)
            #expect(frame[6] == 0x01)
        }

        @Test("SET_SCENE_RENDERING movie preset")
        func setSceneRendering() {
            let frame = Fixtures.setSceneRenderingMovieRequest
            #expect(frame[2] == Op.setSceneRendering)
            #expect(frame[6] == 0x01)
        }

        @Test("All request frames have valid CRC")
        func allRequestsCRCValid() {
            let requests: [Data] = [
                Fixtures.getBatteryRequest,
                Fixtures.setANCModeNCRequest,
                Fixtures.setANCModeTransparencyRequest,
                Fixtures.setANCModeOffRequest,
                Fixtures.setANCDepth75Request,
                Fixtures.setCodecLDACRequest,
                Fixtures.setSoundModeBalancedRequest,
                Fixtures.setGestureLeftDoubleTapRequest,
                Fixtures.setSpatialAudioOnRequest,
                Fixtures.findDeviceStartRequest,
                Fixtures.findDeviceStopRequest,
                Fixtures.getDeviceInfoRequest,
                Fixtures.getGestureConfigRequest,
                Fixtures.setHeadTrackingOnRequest,
                Fixtures.setSceneRenderingMovieRequest,
            ]
            for (index, frame) in requests.enumerated() {
                let body = Array(frame[2 ..< frame.count - 2])
                let computed = XiaomiProtocolFixtures.crc16ccitt(body)
                let embedded = UInt16(frame[frame.count - 2]) | (UInt16(frame[frame.count - 1]) << 8)
                #expect(computed == embedded, "CRC mismatch in request fixture \(index)")
            }
        }
    }

    // MARK: - Response Parser Tests

    @Suite("ResponseParser")
    struct ResponseParserTests {

        private func extractPayload(from frame: Data) -> [UInt8] {
            let len = Int(UInt16(frame[4]) | (UInt16(frame[5]) << 8))
            return Array(frame[6 ..< 6 + len])
        }

        @Test("Parse battery response: L=100, R=100, Case=1, not charging")
        func parseBattery() {
            let frame = Fixtures.batteryResponse
            #expect(frame[2] == Op.batteryResponse)
            let p = extractPayload(from: frame)
            #expect(p[0] == 100)
            #expect(p[1] == 100)
            #expect(p[2] == 1)
            #expect(p[3] == 0x00)
        }

        @Test("Parse battery response with charging flags")
        func parseBatteryCharging() {
            let p = extractPayload(from: Fixtures.batteryResponseCharging)
            #expect(p[0] == 85)
            #expect(p[1] == 80)
            #expect(p[2] == 50)
            #expect(p[3] & 0x01 != 0)
            #expect(p[3] & 0x02 != 0)
            #expect(p[3] & 0x04 == 0)
        }

        @Test("Parse ANC mode response: Noise Cancellation")
        func parseANCModeNC() {
            let p = extractPayload(from: Fixtures.ancModeResponseNC)
            #expect(p[0] == Fixtures.ANCMode.noiseCancellation.rawValue)
        }

        @Test("Parse ANC mode response: Transparency")
        func parseANCModeTransparency() {
            let p = extractPayload(from: Fixtures.ancModeResponseTransparency)
            #expect(p[0] == Fixtures.ANCMode.transparency.rawValue)
        }

        @Test("Parse ANC mode response: Off")
        func parseANCModeOff() {
            let p = extractPayload(from: Fixtures.ancModeResponseOff)
            #expect(p[0] == Fixtures.ANCMode.off.rawValue)
        }

        @Test("Parse SET_ANC_MODE ACK success")
        func parseANCModeAck() {
            let p = extractPayload(from: Fixtures.setANCModeAckSuccess)
            #expect(p[0] == 0x00)
        }

        @Test("Parse ANC depth response: 75")
        func parseANCDepth() {
            let p = extractPayload(from: Fixtures.ancDepthResponse75)
            #expect(p[0] == 0x4B)
        }

        @Test("Parse device info response: firmware and model")
        func parseDeviceInfo() {
            let p = extractPayload(from: Fixtures.deviceInfoResponse)
            let fwLen = Int(p[0])
            let fw = String(bytes: p[1 ..< 1 + fwLen], encoding: .utf8)
            #expect(fw == "3.2.2.6")

            let modelOffset = 1 + fwLen
            let modelLen = Int(p[modelOffset])
            let model = String(bytes: p[modelOffset + 1 ..< modelOffset + 1 + modelLen], encoding: .utf8)
            #expect(model == "M2417E1")
        }

        @Test("Parse codec response: LDAC 48kHz")
        func parseCodecLDAC() {
            let p = extractPayload(from: Fixtures.codecResponseLDAC)
            #expect(p[0] == Fixtures.CodecID.ldac.rawValue)
            let sampleRate = UInt16(p[1]) | (UInt16(p[2]) << 8)
            #expect(sampleRate == 48000)
        }

        @Test("Parse codec response: AAC 44.1kHz")
        func parseCodecAAC() {
            let p = extractPayload(from: Fixtures.codecResponseAAC)
            #expect(p[0] == Fixtures.CodecID.aac.rawValue)
            let sampleRate = UInt16(p[1]) | (UInt16(p[2]) << 8)
            #expect(sampleRate == 44100)
        }

        @Test("Parse sound mode response: Balanced")
        func parseSoundModeBalanced() {
            let p = extractPayload(from: Fixtures.soundModeResponseBalanced)
            #expect(p[0] == Fixtures.SoundMode.balanced.rawValue)
        }

        @Test("Parse gesture config: 10 default mappings")
        func parseGestureConfig() {
            let p = extractPayload(from: Fixtures.gestureConfigResponseDefault)
            let count = Int(p[0])
            #expect(count == 10)
            let expected = Fixtures.expectedGestureConfig.mappings
            for i in 0 ..< count {
                #expect(p[1 + i * 2] == expected[i].slot, "Slot mismatch at index \(i)")
                #expect(p[2 + i * 2] == expected[i].action, "Action mismatch at index \(i)")
            }
        }

        @Test("Parse spatial audio response: on")
        func parseSpatialAudioOn() {
            let p = extractPayload(from: Fixtures.spatialAudioResponseOn)
            let flags = p[0]
            #expect(flags & 0x01 != 0)
            #expect(flags & 0x02 != 0)
            #expect(flags & 0x04 == 0)
        }

        @Test("Parse spatial audio response: off")
        func parseSpatialAudioOff() {
            let p = extractPayload(from: Fixtures.spatialAudioResponseOff)
            #expect(p[0] == 0x00)
        }

        @Test("Parse in-ear status: both in")
        func parseInEarBothIn() {
            let p = extractPayload(from: Fixtures.inEarStatusBothIn)
            #expect(p[0] == 0x01)
            #expect(p[1] == 0x01)
        }

        @Test("Parse in-ear status: left only")
        func parseInEarLeftOnly() {
            let p = extractPayload(from: Fixtures.inEarStatusLeftOnly)
            #expect(p[0] == 0x01)
            #expect(p[1] == 0x00)
        }

        @Test("Parse device name response")
        func parseDeviceName() {
            let p = extractPayload(from: Fixtures.deviceNameResponse)
            let nameLen = Int(p[0])
            let name = String(bytes: p[1 ..< 1 + nameLen], encoding: .utf8)
            #expect(name == "REDMI Buds 8 Pro")
        }

        @Test("Parse ear tip fit test: good seal")
        func parseEarTipFit() {
            let p = extractPayload(from: Fixtures.earTipFitTestGood)
            #expect(p[0] == 0x00)
            #expect(p[1] == 0x02)
            #expect(p[2] == 0x02)
        }

        @Test("All response frames have valid CRC")
        func allResponsesCRCValid() {
            let responses: [Data] = [
                Fixtures.batteryResponse,
                Fixtures.batteryResponseCharging,
                Fixtures.ancModeResponseNC,
                Fixtures.ancModeResponseTransparency,
                Fixtures.ancModeResponseOff,
                Fixtures.setANCModeAckSuccess,
                Fixtures.ancDepthResponse75,
                Fixtures.deviceInfoResponse,
                Fixtures.codecResponseLDAC,
                Fixtures.codecResponseAAC,
                Fixtures.soundModeResponseBalanced,
                Fixtures.soundModeResponseBass,
                Fixtures.gestureConfigResponseDefault,
                Fixtures.spatialAudioResponseOn,
                Fixtures.spatialAudioResponseOff,
                Fixtures.inEarStatusBothIn,
                Fixtures.inEarStatusBothOut,
                Fixtures.inEarStatusLeftOnly,
                Fixtures.dualConnectionEnabled,
                Fixtures.smartANCEnabled,
                Fixtures.headTrackingEnabled,
                Fixtures.sceneRenderingMovie,
                Fixtures.deviceNameResponse,
                Fixtures.earTipFitTestGood,
            ]
            for (index, frame) in responses.enumerated() {
                let body = Array(frame[2 ..< frame.count - 2])
                let computed = XiaomiProtocolFixtures.crc16ccitt(body)
                let embedded = UInt16(frame[frame.count - 2]) | (UInt16(frame[frame.count - 1]) << 8)
                #expect(computed == embedded, "CRC mismatch in response fixture \(index)")
            }
        }
    }

    // MARK: - Frame Validation Tests

    @Suite("FrameValidation")
    struct FrameValidationTests {

        @Test("Valid frame passes validation")
        func validFrame() {
            let frame = Fixtures.batteryResponse
            #expect(frame[0] == 0xFE)
            #expect(frame[1] == 0xDC)
            let body = Array(frame[2 ..< frame.count - 2])
            let computed = XiaomiProtocolFixtures.crc16ccitt(body)
            let embedded = UInt16(frame[frame.count - 2]) | (UInt16(frame[frame.count - 1]) << 8)
            #expect(computed == embedded)
        }

        @Test("Wrong magic bytes are rejected")
        func wrongMagic() {
            let frame = Fixtures.malformedWrongMagic
            #expect(frame[0] != 0xFE || frame[1] != 0xDC)
        }

        @Test("Truncated frame is detected")
        func truncatedFrame() {
            let frame = Fixtures.malformedTruncated
            #expect(frame.count < 8)
        }

        @Test("Bad CRC is detected")
        func badCRC() {
            let frame = Fixtures.malformedBadCRC
            let body = Array(frame[2 ..< frame.count - 2])
            let computed = XiaomiProtocolFixtures.crc16ccitt(body)
            let embedded = UInt16(frame[frame.count - 2]) | (UInt16(frame[frame.count - 1]) << 8)
            #expect(computed != embedded, "Corrupted CRC should not match")
        }

        @Test("Length overflow is detected")
        func lengthOverflow() {
            let frame = Fixtures.malformedLengthOverflow
            let declaredLen = Int(UInt16(frame[4]) | (UInt16(frame[5]) << 8))
            let actualAvailable = frame.count - 6 - 2
            #expect(declaredLen > actualAvailable, "Declared length exceeds available data")
        }

        @Test("Empty frame (just magic) is rejected")
        func emptyFrame() {
            let frame = Fixtures.malformedEmpty
            #expect(frame.count < 8)
        }
    }

    // MARK: - Round-Trip Tests

    @Suite("RoundTrip")
    struct RoundTripTests {

        private func extractPayload(from frame: Data) -> [UInt8] {
            let len = Int(UInt16(frame[4]) | (UInt16(frame[5]) << 8))
            return Array(frame[6 ..< 6 + len])
        }

        @Test("Build GET_BATTERY → parse battery response → verify values")
        func batteryRoundTrip() {
            let request = Fixtures.getBatteryRequest
            #expect(request[2] == Op.getBattery)

            let response = Fixtures.batteryResponse
            #expect(response[2] == Op.batteryResponse)
            #expect(response[2] == request[2] | 0x80, "Response opcode = request | 0x80")

            let p = extractPayload(from: response)
            let expected = Fixtures.expectedBattery
            #expect(p[0] == expected.left)
            #expect(p[1] == expected.right)
            #expect(p[2] == expected.caseBattery)
        }

        @Test("Build SET_ANC_MODE → parse ACK → verify success")
        func setANCModeRoundTrip() {
            let request = Fixtures.setANCModeNCRequest
            #expect(request[2] == Op.setANCMode)
            #expect(request[6] == Fixtures.ANCMode.noiseCancellation.rawValue)

            let ack = Fixtures.setANCModeAckSuccess
            #expect(ack[2] == Op.setANCModeAck)
            let p = extractPayload(from: ack)
            #expect(p[0] == 0x00, "ACK status should be success (0x00)")
        }

        @Test("Build SET_CODEC → parse codec response → verify LDAC 48kHz")
        func codecRoundTrip() {
            let request = Fixtures.setCodecLDACRequest
            #expect(request[6] == Fixtures.CodecID.ldac.rawValue)

            let response = Fixtures.codecResponseLDAC
            let p = extractPayload(from: response)
            let expected = Fixtures.expectedCodecLDAC
            #expect(p[0] == expected.codecID)
            let sampleRate = UInt16(p[1]) | (UInt16(p[2]) << 8)
            #expect(sampleRate == expected.sampleRate)
        }

        @Test("Build SET_SPATIAL_AUDIO → parse response → verify flags")
        func spatialAudioRoundTrip() {
            let request = Fixtures.setSpatialAudioOnRequest
            #expect(request[6] == 0x03)

            let response = Fixtures.spatialAudioResponseOn
            let p = extractPayload(from: response)
            let expected = Fixtures.expectedSpatialOn
            #expect((p[0] & 0x01 != 0) == expected.spatialEnabled)
            #expect((p[0] & 0x02 != 0) == expected.headTrackingEnabled)
            #expect((p[0] & 0x04 != 0) == expected.dolbyMode)
        }

        @Test("Build GET_DEVICE_INFO → parse response → verify firmware and model")
        func deviceInfoRoundTrip() {
            let request = Fixtures.getDeviceInfoRequest
            #expect(request[2] == Op.getDeviceInfo)

            let response = Fixtures.deviceInfoResponse
            let p = extractPayload(from: response)
            let fwLen = Int(p[0])
            let fw = String(bytes: p[1 ..< 1 + fwLen], encoding: .utf8)
            let expected = Fixtures.expectedDeviceInfo
            #expect(fw == expected.firmwareVersion)

            let modelOffset = 1 + fwLen
            let modelLen = Int(p[modelOffset])
            let model = String(bytes: p[modelOffset + 1 ..< modelOffset + 1 + modelLen], encoding: .utf8)
            #expect(model == expected.modelNumber)
        }

        @Test("Build GET_GESTURE_CONFIG → parse response → verify all 10 mappings")
        func gestureConfigRoundTrip() {
            let request = Fixtures.getGestureConfigRequest
            #expect(request[2] == Op.getGestureConfig)

            let response = Fixtures.gestureConfigResponseDefault
            let p = extractPayload(from: response)
            let count = Int(p[0])
            #expect(count == 10)
            let expected = Fixtures.expectedGestureConfig.mappings
            #expect(expected.count == count)
        }

        @Test("Sequence numbers are preserved in built frames")
        func seqNumPreserved() {
            for seq: UInt8 in [0x00, 0x01, 0x7F, 0xFF] {
                let frame = XiaomiProtocolFixtures.buildFrame(opcode: 0x01, seqNum: seq, payload: [])
                #expect(frame[3] == seq, "SeqNum \(seq) should be preserved at offset 3")
            }
        }

        @Test("Async event opcode is distinct from request/response range")
        func asyncEventOpcodes() {
            let event = Fixtures.batteryChangedEvent
            let eventOpcode = event[2]
            #expect(eventOpcode == Op.batteryChanged)
            #expect(eventOpcode >= 0xE0, "Async events use opcodes 0xE0+")
        }
    }
}
