# 🔬 REDMI Buds 8 Pro — RFCOMM Protocol Reverse Engineering Findings

**Date:** 2026-11-05
**Device:** REDMI Buds 8 Pro (B8:53:84:6B:BD:88, FW 3.2.2.6)
**VID/PID:** 0x2717 / 0x50E3 or 0x50E5

---

## Executive Summary

The Xiaomi/Redmi earbuds use **JieLi RCSP** (Remote Control Serial Protocol) over
Bluetooth Classic RFCOMM. The protocol is fully documented by the open-source
community through static analysis of `com.mi.earphone` (Xiaomi Earbuds app) and
verified HCI captures.

**Why our RFCOMM connection times out:** The earbuds only serve the RCSP control
channel to a **bonded** host. The device must be paired with the Mac (standard
Bluetooth pairing) before RFCOMM will accept. Once connected, a framed RCSP
authentication handshake (opcodes 0x50/0x51) must complete before any commands
are accepted.

---

## Sources

| Source | Description |
|--------|-------------|
| [creeperkafasi/redmi-buds-linux](https://github.com/creeperkafasi/redmi-buds-linux) | Rust+Python client, verified PROTOCOL.md with HCI captures |
| [DanteFroMGiti/xiaomi-earbuds-control-linux](https://github.com/DanteFroMGiti/xiaomi-earbuds-control-linux) | GNOME app with JS auth implementation, explicit Buds 8 Pro config |
| [CesurPolat/MiBudsClient](https://github.com/CesurPolat/MiBudsClient) | Python/Flet desktop client |
| [Gadgetbridge](https://codeberg.org/Freeyourgadget/Gadgetbridge) | Android FOSS, Redmi buds support |
| [web1n/android_packages_apps_XiaomiTWS](https://github.com/web1n/android_packages_apps_XiaomiTWS) | Decompiled Xiaomi TWS app reference |

---

## 1. Transport Layer

### RFCOMM Channel Discovery

The earbuds advertise multiple SDP services. The control channel uses the
**MIUI/MIWEAR UUID**:

```
UUID: 0000fd2d-0000-1000-8000-00805f9b34fb
Name: "MIWEAR"
```

The RFCOMM channel number varies by device:
- Redmi Buds 6 Play: channel **6**
- Redmi Buds 6 Lite: channel **29**
- REDMI Buds 8 Pro: channel **28** (observed via SDP)

**Important:** Not every RFCOMM channel that accepts a connection speaks RCSP.
Some channels connect and stay silent (e.g., channel 12 on the 6 Lite).

### Connection Prerequisites

1. **Standard Bluetooth pairing** (bonding) must be established first
2. The earbuds only serve the control channel to an **associated** host
3. If paired to a phone, the phone must disconnect first (or the buds support
   dual-connection and have a free slot)

### Why macOS Times Out

On macOS, using `IOBluetoothDevice.openRFCOMMChannelSync()`:
- If the device is not bonded to the Mac → connection attempt pages but gets no
  response (timeout)
- The earbuds don't refuse the connection; they simply ignore it
- **Solution:** Pair the buds with the Mac first via System Settings → Bluetooth

---

## 2. RCSP Frame Format

All communication after RFCOMM connection uses binary RCSP frames:

```
┌──────────┬──────────┬──────────┬──────────────┬──────────────┬──────────┐
│  Header  │  Flags   │  Opcode  │  Length (BE)  │   Payload    │ Trailer  │
│ FE DC BA │  1 byte  │  1 byte  │   2 bytes     │   N bytes    │   EF     │
└──────────┴──────────┴──────────┴──────────────┴──────────────┴──────────┘
```

**No CRC, no byte-stuffing.** Just scan for `FE DC BA`, read length, expect `EF`.

### Flags Byte

| Bit | Meaning |
|-----|---------|
| 7 | 1 = command (phone→buds), 0 = response |
| 6 | 1 = sender expects a response |
| 5–3 | Reserved |
| 2–0 | Target app ID |

### Common Flag Values

| Value | Meaning |
|-------|---------|
| `0xC4` | Phone request (cmd + expect_rsp + app 4) |
| `0xC1` | Phone request to app 1 (MIUI BT stack) |
| `0x04` | Response to app 4 |
| `0xC0` | Earbuds-initiated request |
| `0x07` | Earbuds response |

### Target App IDs

| ID | Owner |
|----|-------|
| 0 | XiaoAI / case / earphone |
| 1 | `com.xiaomi.bluetooth` (MIUI BT stack) — **auth runs here** |
| 2 | `com.xiaomi.wearable` |
| 3 | `com.milink.service` |
| 4 | `com.mi.earphone` — **device config runs here** |
| 5 | `com.xiaomi.finddevice` |

### Payload Layout

**Command (phone→buds):** `sn | [xm_opcode if opcode==0x01] | params…`

**Response (buds→phone):** `status | sn | data…`

**Status codes:** 0=ok, 1=fail, 2=unknown_cmd, 3=busy, 4=no_resource,
5=crc, 7=param_error, 9=not_supported

---

## 3. Authentication Handshake

Authentication uses two RCSP opcodes under **app ID 1** (MIUI BT stack):

### Sequence (verified on real hardware)

```
1. phone → buds : AUTH_CHECK (0x50) cmd, app=1
                   params = 01 ‖ challenge[16]

2. buds  → phone: AUTH_CHECK (0x50) rsp, status=0
                   data = 01 ‖ transform(challenge)[16]

3. phone → buds : AUTH_SEND_CALC_RESULT (0x51) cmd, app=1
                   params = 01 00   (version=1, pairResult=0)

4. buds  → phone: AUTH_SEND_CALC_RESULT (0x51) rsp, status=0
```

**After step 4, the buds accept F2/F3 config commands.**

### Bidirectional Authentication

The buds may **also** send their own `0x50` challenge command. When received,
respond with:

```
response frame: flags=APP_MIUI(1), opcode=0x50
payload = 00 | buds_sn | 01 ‖ transform(buds_challenge)[16]
```

### The `transform()` Function

Recovered from `libxm_bluetooth.so` (aarch64) in the `com.mi.earphone` APK.

```python
def transform(addr6, challenge16) -> bytes[16]:
    out   = addr6 ‖ addr6 ‖ addr6[:4]        # 16 bytes from 6-byte addr
    tmp   = challenge16 ;  tmp[15] ^= 0x06
    sched = expand_key(tmp)                    # 272 bytes
    return mix(out, sched, flag=1)
```

**Critical constants (hardcoded in the app, same for ALL devices):**

| Argument | Value | Notes |
|----------|-------|-------|
| `addr6` | `11 22 33 33 22 11` | Fixed placeholder — NOT the device MAC |
| `key16` | `06 77 5f 87 91 8d d4 23 00 5d f1 d8 cf 0c 14 2b` | Factory key (unused — E21 ignores it) |

**The real Bluetooth MAC is NOT used.** The app always passes the fixed
placeholder address `[0x11, 0x22, 0x33, 0x33, 0x22, 0x11]`.

### Cryptographic Primitives

The transform consists of:

1. **`expand_key(key16)`** → 272 bytes: 16 rounds of rotating state with
   table-lookup key schedule (table at `.rodata 0x970`)
2. **`mix(state16, sched272, flag)`** → 16 bytes: 8 rounds of:
   - XOR/add with schedule (selected by bitmask `0x9999`)
   - Substitution through two 256-byte tables (`_TAB_A` at `.rodata 0xa70`,
     `_TAB_B` at `.rodata 0xb70`)
   - Linear mixing (butterfly network, `b[i] + 2*b[j]` mod 256)

### Verified Test Vectors

From real HCI captures (challenge → expected response):

```
385c2aecb03bfb32af3c54ec18db5c02 → 99a16782b8e05df000099bc2cb3417bf
1afe43fbfaaa3afb29d1e6053c7c9475 → f011ccd271c9d429d14bd4887d825611
acbb8a57b2d58c8aa24d2fb232cbddb7 → e696a4c36f460b55ca6f5b8fb0a4c7f8
```

---

## 4. Command Reference

### Opcodes

| Hex | Name | Direction | App ID |
|-----|------|-----------|--------|
| `0x02` | GET_TARGET_INFO | phone→buds | 4 |
| `0x03` | REBOOT_DEVICE | phone→buds | 4 |
| `0x08` | SET_TARGET_INFO | phone→buds | 4 |
| `0x09` | GET_DEVICE_RUN_INFO | phone→buds | 4 |
| `0x0E` | REPORT_STATUS | buds→phone | — |
| `0x50` | AUTH_CHECK | both | 1 |
| `0x51` | AUTH_SEND_CALC_RESULT | phone→buds | 1 |
| `0xF2` | SET_DEVICE_CONFIG | phone→buds | 4 |
| `0xF3` | GET_DEVICE_CONFIG | phone→buds | 4 |
| `0xF4` | NOTIFY_DEVICE_CONFIG | buds→phone | — |

### GET_TARGET_INFO (0x02)

Request params: `FF FF FF FF` (request all attributes)

Response is TLV-encoded (length, type, value):

| Type | Attribute | Format |
|------|-----------|--------|
| 0 | Device name | UTF-8 string |
| 1 | Firmware version | 4 bytes: `major.minor.patch.build` packed as nibbles |
| 2 | Quantity (battery single) | 1 byte (0–100) |
| 3 | VID/PID | 4 bytes: VID(u16 BE) + PID(u16 BE) |
| 7 | Multi-battery | N bytes: per-component `level ‖ charging_flag` |

**Battery byte format:** `bit7 = charging`, `bits 6-0 = level (0–100)`, `0xFF = disconnected`

Example: `e4 64 1e` → left=100% charging, right=100% not charging, case=30%

### Config TLV Format

Device configs use `SET_DEVICE_CONFIG (0xF2)` and `GET_DEVICE_CONFIG (0xF3)`.

**TLV:** `length(u8) | config_id(u16 BE) | value(length-2 bytes)`

### Config IDs (Redmi Buds 8 Pro)

| ID (hex) | ID (dec) | Setting | Values |
|----------|----------|---------|--------|
| `0x0002` | 2 | Gesture click set | 12 bytes: triples of `[setType, left, right]` |
| `0x0003` | 3 | Auto-answer | `00`=off, `01`=on |
| `0x0004` | 4 | Dual connection | `00`=off, `01`=on |
| `0x0007` | 7 | **EQ preset** | `00`=balanced, `01`=voice, `05`=bass, `06`=treble, `0A`=custom |
| `0x0009` | 9 | Find device (ring) | `[state, deviceType]`: state 1=ring/0=stop, type 1=L/2=R/3=both |
| `0x000A` | 10 | Long-press noise cycle | Per-side bitmask: bit0=off, bit1=ANC, bit2=transparency |
| `0x000B` | 11 | **ANC state + level** | `[mode, level]`: mode 0=off/1=ANC/2=transparency, level 0–20 |
| `0x0025` | 37 | Adaptive ANC | `00`=off, `01`=on |
| `0x0027` | 39 | Serial number | ASCII string |
| `0x0028` | 40 | Time | 4 bytes Unix timestamp |
| `0x0029` | 41 | Adaptive sound (sense) | `00`=off, `01`=on |
| `0x002F` | 47 | Low latency (game mode) | `00`=off, `01`=on |
| `0x0037` | 55 | Custom EQ curve | Multi-byte curve data |
| `0x0048` | 72 | Adaptive volume | `00`=off, `01`=on |
| `0x004F` | 79 | Spatial audio | `00`=off, `01`=on |
| `0x005D` | 93 | Restricted | `00` |

### Gesture Actions

| Value | Action |
|-------|--------|
| `0x01` | Play/pause |
| `0x02` | Previous track |
| `0x03` | Next track |
| `0x04` | Volume up |
| `0x05` | Volume down |
| `0x06` | Noise control cycle |
| `0x08` | No action / voice assistant (context-dependent) |
| `0x09` | Photo |
| `0x0A` | Record |
| `0x0B` | Volume (swipe) |

### Gesture Set Types

| Value | Gesture |
|-------|---------|
| `0x01` | Double tap |
| `0x02` | Triple tap |
| `0x03` | Long press |
| `0x04` | Single tap |
| `0x05` | Swipe |

### ANC / Transparency for Buds 8 Pro

| Mode | Value | Notes |
|------|-------|-------|
| Off | `0x00` | No noise control |
| Noise cancellation | `0x01` | Level 0–20 (adaptive ANC supported) |
| Transparency | `0x02` | Sub-modes: 0x00=regular, 0x01=voice, 0x02=ambient |

### EQ Presets (Buds 8 Pro)

| Value | Name |
|-------|------|
| `0x00` | Balanced |
| `0x01` | Vocal enhancement |
| `0x05` | Bass boost |
| `0x06` | Treble boost |
| `0x0A` | Personalized / Custom |

---

## 5. Typical Session (from HCI capture)

```
[RFCOMM Connect on fd2d channel]

→ AUTH_CHECK cmd (app=1): 01 ‖ <16-byte random challenge>
← AUTH_CHECK rsp (status=0): 01 ‖ <16-byte transform(challenge)>
→ AUTH_SEND_CALC_RESULT cmd (app=1): 01 00
← AUTH_SEND_CALC_RESULT rsp (status=0)

→ GET_TARGET_INFO cmd (app=4): FF FF FF FF
← GET_TARGET_INFO rsp: name/version/battery/vid-pid TLVs

→ GET_DEVICE_RUN_INFO cmd (app=4): FF FF FF FF
← GET_DEVICE_RUN_INFO rsp: addresses, status

→ SET_DEVICE_CONFIG cmd (app=4): time=<unix timestamp>
← SET_DEVICE_CONFIG rsp: ok

→ GET_DEVICE_CONFIG cmd (app=4): config IDs…
← GET_DEVICE_CONFIG rsp: config TLV values

[Session established — commands accepted]
```

---

## 6. Implementation Notes

### Frame Encoding (pseudocode)

```swift
func encodeFrame(flags: UInt8, opcode: UInt8, payload: [UInt8]) -> [UInt8] {
    var frame: [UInt8] = [0xFE, 0xDC, 0xBA]  // magic
    frame.append(flags)
    frame.append(opcode)
    let len = UInt16(payload.count)
    frame.append(UInt8(len >> 8))              // length big-endian
    frame.append(UInt8(len & 0xFF))
    frame.append(contentsOf: payload)
    frame.append(0xEF)                         // trailer
    return frame
}
```

### Frame Decoding

Scan for `FE DC BA`, read 2-byte big-endian length at offset +5, extract
payload of that length, verify `EF` trailer.

### Auth Command Construction

```swift
// Send AUTH_CHECK
let flags: UInt8 = 0x80 | 0x40 | 0x01  // cmd + expect_rsp + app_MIUI
let sn: UInt8 = nextSequenceNumber()
var payload: [UInt8] = [sn, 0x01]       // sn + version=1
payload.append(contentsOf: challenge)    // 16 random bytes
let frame = encodeFrame(flags: flags, opcode: 0x50, payload: payload)
```

### Auth Response Validation

```swift
// Parse response: status(1) + sn(1) + version(1) + response(16)
let status = responsePayload[0]         // must be 0
let responseSn = responsePayload[1]     // must match sent sn
let version = responsePayload[2]        // 0x01
let deviceResponse = responsePayload[3..<19]
let expected = authTransform(addr6: ADDR6_PLACEHOLDER, challenge: challenge)
assert(deviceResponse == expected)
```

---

## 7. Key Takeaways for macOS Implementation

1. **Pair first:** The buds must be bonded with the Mac via standard BT pairing
2. **Use UUID `0000fd2d-...`** to find the RFCOMM channel (or try channel 28)
3. **RFCOMM connects normally** — no pre-connection magic needed
4. **Immediately send AUTH_CHECK (0x50)** with a random 16-byte challenge
5. **Verify the response** using the `transform()` function with fixed `addr6`
6. **Send AUTH_SEND_CALC_RESULT (0x51)** with `[0x01, 0x00]`
7. **Handle bidirectional auth** — the buds may also challenge you
8. **Then send GET_TARGET_INFO (0x02)** to retrieve battery/device info
9. **Use SET/GET_DEVICE_CONFIG (0xF2/0xF3)** for all settings

### What We Were Missing

We were trying to open the RFCOMM channel from macOS without the device being
bonded. The earbuds only respond to RFCOMM connection requests from paired hosts.
The "authentication handshake" happens AFTER the RFCOMM channel is open, not
before it.
