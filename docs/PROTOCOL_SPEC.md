# 🔬 REDMI Buds 8 Pro — Bluetooth Protocol Specification

**Device:** Xiaomi REDMI Buds 8 Pro  
**Firmware:** 3.2.2.6  
**BT Address:** B8:53:84:6B:BD:88  
**Date:** 2026-11-05  
**Status:** Draft — based on community research and protocol analysis of similar Xiaomi TWS earbuds (Redmi Buds 4 Pro, 5 Pro, Buds 6 Pro, FlipBuds Pro)

> **⚠️ CORRECTED:** The frame format below was based on early estimates.
> See **[PROTOCOL_RE_FINDINGS.md](PROTOCOL_RE_FINDINGS.md)** for the verified
> protocol (JieLi RCSP) confirmed by HCI captures and multiple working
> open-source clients. Key differences: 3-byte magic `FE DC BA` (not `FE DC`),
> no CRC (uses `EF` trailer instead), flags byte instead of separate opcode+seqnum,
> big-endian length, and authentication uses opcodes 0x50/0x51 with a custom
> cryptographic transform from `libxm_bluetooth.so`.

---

## Table of Contents

1. [Transport Overview](#1-transport-overview)
2. [Standard BLE Services](#2-standard-ble-services)
3. [Xiaomi Custom Protocol — Frame Format](#3-xiaomi-custom-protocol--frame-format)
4. [CRC Algorithm](#4-crc-algorithm)
5. [Command Reference Table](#5-command-reference-table)
6. [Feature Command Details](#6-feature-command-details)
7. [Known Issues & Limitations](#7-known-issues--limitations)
8. [Research Methodology](#8-research-methodology)
9. [References](#9-references)

---

## 1. Transport Overview

The REDMI Buds 8 Pro communicates with the host over both Classic Bluetooth and BLE:

| Transport | Profile | Purpose |
|-----------|---------|---------|
| Classic BT | A2DP | Audio streaming (LDAC / AAC / SBC) |
| Classic BT | HFP | Hands-free calling, SCO audio |
| Classic BT | AVRCP | Media control (play/pause/skip) |
| Classic BT | SPP / RFCOMM | Proprietary command channel (some models) |
| BLE | GATT | Device info, battery, proprietary commands |

### Communication Channel

Xiaomi TWS earbuds typically use one of two channels for proprietary commands:

1. **BLE GATT custom service** — Commands are written to a custom characteristic and responses arrive via notifications on a separate characteristic.
2. **Classic BT SPP/RFCOMM** — Some models use a serial port profile channel for the proprietary protocol.

The REDMI Buds 8 Pro is expected to use **BLE GATT** as the primary command channel, with a Xiaomi-proprietary service UUID.

---

## 2. Standard BLE Services

### 2.1 Generic Access (0x1800)

| Characteristic | UUID | Properties | Description |
|---------------|------|------------|-------------|
| Device Name | 0x2A00 | Read | `"REDMI Buds 8 Pro"` |
| Appearance | 0x2A01 | Read | Category: Earbuds (0x0941) |

### 2.2 Device Information Service (0x180A)

| Characteristic | UUID | Properties | Format | Example Value |
|---------------|------|------------|--------|---------------|
| Model Number | 0x2A24 | Read | UTF-8 string | `"M2417E1"` |
| Serial Number | 0x2A25 | Read | UTF-8 string | `"XXX..."` |
| Firmware Revision | 0x2A26 | Read | UTF-8 string | `"3.2.2.6"` |
| Hardware Revision | 0x2A27 | Read | UTF-8 string | `"1.0.0"` |
| Software Revision | 0x2A28 | Read | UTF-8 string | `"3.2.2.6"` |
| Manufacturer Name | 0x2A29 | Read | UTF-8 string | `"Xiaomi Inc."` |
| PnP ID | 0x2A50 | Read | 7 bytes | Vendor: Xiaomi, Product ID |

### 2.3 Battery Service (0x180F)

| Characteristic | UUID | Properties | Format | Description |
|---------------|------|------------|--------|-------------|
| Battery Level | 0x2A19 | Read, Notify | uint8 (0–100) | Combined/primary battery % |

> **Note:** The standard Battery Service reports a single value. Per-earbud (L/R) and case battery levels are reported via the Xiaomi custom protocol.

---

## 3. Xiaomi Custom Protocol — Frame Format

Based on analysis of Xiaomi TWS earbuds (community projects: librebuds, OpenBuds, XiaomiBLE), the proprietary protocol uses a binary frame format over the BLE GATT write/notify channel.

### 3.1 Service & Characteristics

| Role | UUID (expected) | Properties |
|------|----------------|------------|
| Xiaomi Custom Service | `0000FE95-0000-1000-8000-00805F9B34FB` | — |
| Command Write | `00000001-0000-1000-8000-00805F9B34FB` (under custom svc) | Write, Write Without Response |
| Response Notify | `00000002-0000-1000-8000-00805F9B34FB` (under custom svc) | Notify |
| Auth Characteristic | `00000003-0000-1000-8000-00805F9B34FB` (under custom svc) | Read, Write |

> **Important:** The actual UUIDs must be confirmed via BLE enumeration (see `tools/ble_scanner.py`). Xiaomi frequently uses `0xFE95` (Xiaomi Inc. registered BLE company UUID) or `0xFEBE` as the service base.

### 3.2 Frame Structure

```
Offset  Size    Field           Description
──────────────────────────────────────────────────────────
0x00    2       Magic           Frame start marker: 0xFE 0xDC
0x02    1       Opcode          Command identifier
0x03    1       SeqNum          Sequence number (wraps 0x00–0xFF)
0x04    2       Length          Payload length (little-endian)
0x06    N       Payload         Command-specific data
0x06+N  2       CRC             CRC-16-CCITT (little-endian)
──────────────────────────────────────────────────────────
Total: 8 + N bytes
```

### 3.3 Frame Diagram

```
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│  Magic   │  Opcode  │  SeqNum  │  Length   │ Payload  │   CRC    │
│ (2 bytes)│ (1 byte) │ (1 byte) │ (2 bytes)│ (N bytes)│ (2 bytes)│
│ FE DC    │          │          │  LE u16  │          │  LE u16  │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

### 3.4 Field Details

**Magic (0xFE 0xDC)**
- Identifies the start of a Xiaomi protocol frame.
- Consistent across Redmi Buds 4 Pro, 5 Pro, 6 Pro, and FlipBuds Pro.
- Some newer models may also accept `0xFE 0xDD` as an extended frame marker.

**Opcode (1 byte)**
- Identifies the command or response type.
- Opcodes 0x01–0x7F are host→device requests.
- Opcodes 0x80–0xFF are device→host responses/events (response = request opcode | 0x80).

**SeqNum (1 byte)**
- Monotonically increasing per-direction counter.
- Used to match responses to requests.
- Wraps from 0xFF to 0x00.

**Length (2 bytes, little-endian)**
- Length of the Payload field only (does not include header or CRC).

**Payload (variable)**
- Command-specific data. See Section 5 for per-command payloads.

**CRC (2 bytes, little-endian)**
- CRC-16-CCITT computed over bytes from Opcode through end of Payload (excludes Magic, includes Opcode + SeqNum + Length + Payload).

---

## 4. CRC Algorithm

### CRC-16-CCITT (0x1021)

- **Polynomial:** 0x1021
- **Initial value:** 0xFFFF
- **Input reflection:** No
- **Output reflection:** No
- **Final XOR:** 0x0000

### Pseudocode

```python
def crc16_ccitt(data: bytes) -> int:
    """Compute CRC-16-CCITT over the given data."""
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ 0x1021
            else:
                crc = crc << 1
            crc &= 0xFFFF
    return crc
```

### CRC Scope

The CRC is computed over: `Opcode || SeqNum || Length || Payload`

```
CRC input = frame[2 .. (6 + payload_length - 1)]
```

---

## 5. Command Reference Table

### 5.1 Request Commands (Host → Device)

| Opcode | Command | Payload Format | Description |
|--------|---------|---------------|-------------|
| `0x01` | GET_BATTERY | (empty) | Request battery levels for L, R, and case |
| `0x02` | GET_DEVICE_INFO | (empty) | Request firmware version, model, serial |
| `0x03` | GET_ANC_MODE | (empty) | Query current ANC mode |
| `0x04` | SET_ANC_MODE | `[mode: u8]` | Set ANC mode |
| `0x05` | GET_ANC_DEPTH | (empty) | Query ANC depth (strength) |
| `0x06` | SET_ANC_DEPTH | `[depth: u8]` | Set ANC depth (0–100) |
| `0x07` | GET_CODEC | (empty) | Query active audio codec |
| `0x08` | SET_CODEC | `[codec_id: u8]` | Set preferred codec |
| `0x09` | GET_SOUND_MODE | (empty) | Query current sound/EQ mode |
| `0x0A` | SET_SOUND_MODE | `[mode: u8]` | Set sound/EQ mode |
| `0x0B` | GET_GESTURE_CONFIG | (empty) | Query all gesture mappings |
| `0x0C` | SET_GESTURE_CONFIG | `[slot: u8, action: u8]` | Set gesture action for a slot |
| `0x0D` | GET_SPATIAL_AUDIO | (empty) | Query spatial audio settings |
| `0x0E` | SET_SPATIAL_AUDIO | `[flags: u8]` | Set spatial audio options |
| `0x0F` | GET_IN_EAR_STATUS | (empty) | Query in-ear detection state |
| `0x10` | SET_IN_EAR_DETECTION | `[enabled: u8]` | Enable/disable in-ear detection |
| `0x11` | GET_DUAL_CONNECTION | (empty) | Query dual connection state |
| `0x12` | SET_DUAL_CONNECTION | `[enabled: u8]` | Enable/disable dual connection |
| `0x13` | FIND_DEVICE | `[action: u8]` | Start/stop find device beep |
| `0x14` | SET_DEVICE_NAME | `[name: UTF-8]` | Set custom device name |
| `0x15` | GET_DEVICE_NAME | (empty) | Query custom device name |
| `0x16` | GET_SMART_ANC | (empty) | Query Smart ANC / Immersive Commute |
| `0x17` | SET_SMART_ANC | `[enabled: u8]` | Enable/disable Smart ANC |
| `0x18` | START_EAR_TIP_FIT_TEST | (empty) | Begin ear tip fit test |
| `0x19` | GET_SCENE_RENDERING | (empty) | Query scene rendering preset |
| `0x1A` | SET_SCENE_RENDERING | `[preset: u8]` | Set scene rendering preset |
| `0x1B` | GET_HEAD_TRACKING | (empty) | Query head tracking state |
| `0x1C` | SET_HEAD_TRACKING | `[enabled: u8]` | Enable/disable head tracking |

### 5.2 Response / Event (Device → Host)

| Opcode | Response To | Payload Format | Description |
|--------|-----------|---------------|-------------|
| `0x81` | GET_BATTERY | `[left: u8, right: u8, case: u8, charging: u8]` | Battery levels (0–100) + charging flags |
| `0x82` | GET_DEVICE_INFO | `[fw_len: u8, fw: UTF-8, model_len: u8, model: UTF-8]` | Firmware + model strings |
| `0x83` | GET_ANC_MODE | `[mode: u8]` | Current ANC mode |
| `0x84` | SET_ANC_MODE | `[status: u8]` | ACK: 0x00 = success |
| `0x85` | GET_ANC_DEPTH | `[depth: u8]` | ANC depth (0–100) |
| `0x86` | SET_ANC_DEPTH | `[status: u8]` | ACK |
| `0x87` | GET_CODEC | `[codec_id: u8, sample_rate: u16 LE]` | Active codec + sample rate |
| `0x88` | SET_CODEC | `[status: u8]` | ACK |
| `0x89` | GET_SOUND_MODE | `[mode: u8]` | Current sound mode |
| `0x8A` | SET_SOUND_MODE | `[status: u8]` | ACK |
| `0x8B` | GET_GESTURE_CONFIG | `[count: u8, (slot: u8, action: u8) × count]` | All gesture mappings |
| `0x8C` | SET_GESTURE_CONFIG | `[status: u8]` | ACK |
| `0x8D` | GET_SPATIAL_AUDIO | `[flags: u8]` | Spatial audio flags |
| `0x8E` | SET_SPATIAL_AUDIO | `[status: u8]` | ACK |
| `0x8F` | GET_IN_EAR_STATUS | `[left: u8, right: u8]` | In-ear state per bud |
| `0x90` | SET_IN_EAR_DETECTION | `[status: u8]` | ACK |
| `0x91` | GET_DUAL_CONNECTION | `[enabled: u8]` | Dual connection state |
| `0x92` | SET_DUAL_CONNECTION | `[status: u8]` | ACK |
| `0x93` | FIND_DEVICE | `[status: u8]` | ACK |
| `0x94` | SET_DEVICE_NAME | `[status: u8]` | ACK |
| `0x95` | GET_DEVICE_NAME | `[name_len: u8, name: UTF-8]` | Current device name |
| `0x96` | GET_SMART_ANC | `[enabled: u8]` | Smart ANC state |
| `0x97` | SET_SMART_ANC | `[status: u8]` | ACK |
| `0x98` | START_EAR_TIP_FIT_TEST | `[status: u8, left_seal: u8, right_seal: u8]` | Test result |
| `0x99` | GET_SCENE_RENDERING | `[preset: u8]` | Current scene rendering preset |
| `0x9A` | SET_SCENE_RENDERING | `[status: u8]` | ACK |
| `0x9B` | GET_HEAD_TRACKING | `[enabled: u8]` | Head tracking state |
| `0x9C` | SET_HEAD_TRACKING | `[status: u8]` | ACK |

### 5.3 Asynchronous Events (Device → Host, unsolicited)

| Opcode | Event | Payload Format | Description |
|--------|-------|---------------|-------------|
| `0xE0` | BATTERY_CHANGED | `[left: u8, right: u8, case: u8, charging: u8]` | Battery level changed |
| `0xE1` | ANC_MODE_CHANGED | `[mode: u8]` | ANC mode changed (physical button) |
| `0xE2` | IN_EAR_CHANGED | `[left: u8, right: u8]` | In-ear state changed |
| `0xE3` | CONNECTION_CHANGED | `[state: u8]` | Connection state changed |
| `0xE4` | CODEC_CHANGED | `[codec_id: u8, sample_rate: u16 LE]` | Codec changed |

---

## 6. Feature Command Details

### 6.1 Battery (0x01 / 0x81)

**Request:** `FE DC 01 <seq> 00 00 <crc_lo> <crc_hi>`

**Response payload:** 4 bytes
```
Byte 0: Left earbud battery (0–100)
Byte 1: Right earbud battery (0–100)
Byte 2: Case battery (0–100, or 0xFF if case is open/unavailable)
Byte 3: Charging flags (bitmask)
         Bit 0: Left charging
         Bit 1: Right charging
         Bit 2: Case charging
```

**Example:**
```
Request:  FE DC 01 00 00 00 3B E1
Response: FE DC 81 00 04 00 64 64 01 00 XX XX
          Left=100%, Right=100%, Case=1%, Not charging
```

### 6.2 ANC Mode (0x03–0x04 / 0x83–0x84)

**ANC Mode Values:**

| Value | Mode |
|-------|------|
| `0x00` | Off |
| `0x01` | Noise Cancellation |
| `0x02` | Transparency |
| `0x03` | Adaptive (Smart ANC) |

**SET_ANC_MODE Request:**
```
FE DC 04 <seq> 01 00 <mode> <crc_lo> <crc_hi>
```

**Example — Set to Noise Cancellation:**
```
Request:  FE DC 04 01 01 00 01 XX XX
Response: FE DC 84 01 01 00 00 XX XX  (status=0x00: success)
```

### 6.3 ANC Depth (0x05–0x06 / 0x85–0x86)

Depth is a uint8 value from 0 (minimum) to 100 (maximum).

**SET_ANC_DEPTH Request:**
```
FE DC 06 <seq> 01 00 <depth> <crc_lo> <crc_hi>
```

### 6.4 Codec Selection (0x07–0x08 / 0x87–0x88)

**Codec ID Values:**

| Value | Codec |
|-------|-------|
| `0x01` | SBC |
| `0x02` | AAC |
| `0x03` | LDAC |

**GET_CODEC Response payload:** 3 bytes
```
Byte 0:   Codec ID
Byte 1-2: Sample rate in Hz (u16 LE)
           0x80BB = 48000 (48.0 kHz)
           0x44AC = 44100 (44.1 kHz)
           0x0077 = 96000 (96.0 kHz, LDAC only)
```

**Example — Current codec LDAC at 48 kHz:**
```
Response: FE DC 87 00 03 00 03 80 BB XX XX
          Codec=LDAC(0x03), SampleRate=48000(0xBB80)
```

### 6.5 Sound Mode / EQ (0x09–0x0A / 0x89–0x8A)

**Sound Mode Values:**

| Value | Mode |
|-------|------|
| `0x00` | Default / Balanced |
| `0x01` | Bass Boost |
| `0x02` | Treble Boost |
| `0x03` | Vocal |
| `0x04` | Volume Boost |

### 6.6 Gesture Configuration (0x0B–0x0C / 0x8B–0x8C)

**Gesture Slot IDs (10 slots):**

| Slot | Gesture |
|------|---------|
| `0x00` | Left single tap |
| `0x01` | Left double tap |
| `0x02` | Left triple tap |
| `0x03` | Left long press |
| `0x04` | Left swipe |
| `0x05` | Right single tap |
| `0x06` | Right double tap |
| `0x07` | Right triple tap |
| `0x08` | Right long press |
| `0x09` | Right swipe |

**Action IDs:**

| Value | Action |
|-------|--------|
| `0x00` | None (disabled) |
| `0x01` | Play / Pause |
| `0x02` | Next Track |
| `0x03` | Previous Track |
| `0x04` | Volume Up |
| `0x05` | Volume Down |
| `0x06` | Cycle ANC Modes |
| `0x07` | Voice Assistant |
| `0x08` | Toggle Spatial Audio |
| `0x09` | Game Mode |

**GET_GESTURE_CONFIG Response:**
```
Byte 0: Count (number of mappings, expected: 10)
Bytes 1..2N: (slot_id, action_id) pairs
```

### 6.7 Spatial Audio / Dimensional Audio (0x0D–0x0E / 0x8D–0x8E)

**Flags byte (bitmask):**
```
Bit 0: Spatial audio enabled
Bit 1: Head tracking enabled
Bit 2: Dolby mode (0 = Xiaomi spatial, 1 = Dolby Atmos)
Bit 3: Fixed position mode
```

**Example — Spatial on, head tracking on, Xiaomi mode:**
```
Flags = 0x03 (bits 0 + 1 set)
```

### 6.8 Find Device (0x13 / 0x93)

**Action values:**
```
0x01: Start beeping
0x00: Stop beeping
```

### 6.9 In-Ear Detection (0x0F / 0x8F)

**Response payload:** 2 bytes
```
Byte 0: Left in-ear (0x00 = out, 0x01 = in)
Byte 1: Right in-ear (0x00 = out, 0x01 = in)
```

### 6.10 Scene Rendering (0x19–0x1A / 0x99–0x9A)

**Scene Rendering Preset Values:**

| Value | Preset |
|-------|--------|
| `0x00` | Off |
| `0x01` | Movie |
| `0x02` | Music |
| `0x03` | Game |
| `0x04` | Podcast |

### 6.11 Ear Tip Fit Test (0x18 / 0x98)

**Response payload:** 3 bytes
```
Byte 0: Status (0x00 = complete, 0x01 = in-progress, 0xFF = failed)
Byte 1: Left seal quality (0x00 = poor, 0x01 = fair, 0x02 = good)
Byte 2: Right seal quality (0x00 = poor, 0x01 = fair, 0x02 = good)
```

---

## 7. Known Issues & Limitations

### 7.1 Protocol Uncertainty

- **UUIDs are estimated.** The exact custom service and characteristic UUIDs must be confirmed via BLE enumeration. Run `tools/ble_scanner.py` against the actual device to discover the real UUIDs.
- **Opcodes are hypothesized.** The opcode values are based on analysis of similar Xiaomi earbuds and community projects. Actual opcodes may differ and should be confirmed via packet capture.
- **Frame format may vary.** Some Xiaomi devices use a slightly different frame format (e.g., additional version byte, different magic bytes).

### 7.2 Authentication

- Xiaomi earbuds typically require **no BLE authentication** for basic GATT reads (battery, device info).
- Custom protocol commands **may require** pairing or an auth handshake via the auth characteristic.
- Some commands may only work when the device is in a specific state (e.g., ear tip fit test requires buds to be in-ear).

### 7.3 Firmware Variations

- Protocol details can change between firmware versions.
- New features in firmware 3.x may use previously unassigned opcodes.
- Always check firmware version before sending commands.

### 7.4 macOS BLE Limitations

- macOS CoreBluetooth does **not** expose the BLE device MAC address. Devices are identified by a platform-specific UUID.
- CoreBluetooth requires the device to be advertising in BLE mode for initial discovery.
- Some Xiaomi earbuds only advertise BLE when the case is open or they are in pairing mode.

### 7.5 Classic BT Fallback

- If BLE GATT custom services are not accessible, the protocol may run over Classic BT SPP/RFCOMM.
- macOS `IOBluetooth` framework provides RFCOMM channel access.
- SPP channel discovery requires SDP (Service Discovery Protocol) query.

---

## 8. Research Methodology

### 8.1 BLE GATT Enumeration

1. Use `tools/ble_scanner.py` to connect and enumerate all services.
2. Document every service UUID, characteristic UUID, and properties.
3. Read all readable characteristics and record values.
4. Subscribe to all notify characteristics and record unsolicited data.

### 8.2 Android APK Decompile

1. Download the official Xiaomi Earbuds APK (`com.xiaomi.xiaoailite` or `com.xiaomi.buds`).
2. Decompile with `jadx` or `apktool`.
3. Search for:
   - BLE service UUIDs (grep for `0000fe95`, `FEDC`, custom UUIDs)
   - Protocol frame builders/parsers
   - Opcode constants and command enums
   - CRC implementation
4. Key packages to inspect:
   - `com.xiaomi.ble.protocol`
   - `com.xiaomi.earphone.protocol`
   - `com.xiaomi.buds.protocol`

### 8.3 Bluetooth HCI Sniffing

1. **macOS PacketLogger** — Capture HCI traffic on the Mac itself (see `docs/PACKET_CAPTURE_GUIDE.md`).
2. **Android HCI log** — Enable Bluetooth HCI snoop log in Android developer settings, pair with earbuds, trigger commands from the Xiaomi app, and analyze the `btsnoop_hci.log`.
3. **Wireshark** — Open HCI logs, filter by device address, and decode GATT write/notify operations.

### 8.4 Community References

- Search GitHub for projects targeting Xiaomi/Redmi earbuds protocol.
- Cross-reference opcode tables and frame formats with community findings.
- Validate any discovered opcodes by sending them to the device and observing responses.

---

## 9. References

| Resource | Description |
|----------|-------------|
| [Bluetooth SIG GATT Services](https://www.bluetooth.com/specifications/assigned-numbers/) | Official UUID assignments |
| [Apple CoreBluetooth Docs](https://developer.apple.com/documentation/corebluetooth) | macOS BLE framework |
| [Xiaomi BLE Company UUID 0xFE95](https://www.bluetooth.com/specifications/assigned-numbers/) | Xiaomi Inc. registered UUID |
| [CRC-16-CCITT](https://reveng.sourceforge.io/crc-catalogue/16.htm) | CRC algorithm specification |
| [Wireshark BT HCI](https://wiki.wireshark.org/Bluetooth) | Bluetooth protocol dissection |
| [Android HCI Snoop Log](https://source.android.com/docs/core/connect/bluetooth/verifying_debugging) | How to capture BT HCI on Android |

---

> **⚠️ Disclaimer:** This specification is based on reverse-engineering research and community projects. It is not official Xiaomi documentation. Opcodes, UUIDs, and payload formats must be validated against the actual REDMI Buds 8 Pro device. Use at your own risk.
