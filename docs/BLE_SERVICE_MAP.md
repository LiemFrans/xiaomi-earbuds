# 📋 BLE Service Map — REDMI Buds 8 Pro

**Status:** Expected / To Be Confirmed  
**Date:** 2026-11-05  
**Device:** REDMI Buds 8 Pro (FW 3.2.2.6)

> Run `tools/ble_scanner.py --address B8:53:84:6B:BD:88` to discover the actual service hierarchy. The UUIDs below are based on analysis of similar Xiaomi TWS devices (Redmi Buds 4 Pro, 5 Pro, 6 Pro, FlipBuds Pro).

---

## Service Hierarchy

```
REDMI Buds 8 Pro (B8:53:84:6B:BD:88)
│
├── Generic Access (0x1800)
│   ├── Device Name (0x2A00) ─────────── Read
│   ├── Appearance (0x2A01) ──────────── Read
│   └── Peripheral Preferred Conn Params (0x2A04) ── Read
│
├── Generic Attribute (0x1801)
│   └── Service Changed (0x2A05) ────── Indicate
│       └── CCCD (0x2902)
│
├── Device Information (0x180A)
│   ├── Model Number String (0x2A24) ── Read
│   ├── Serial Number String (0x2A25) ─ Read
│   ├── Firmware Revision (0x2A26) ──── Read
│   ├── Hardware Revision (0x2A27) ──── Read
│   ├── Software Revision (0x2A28) ──── Read
│   ├── Manufacturer Name (0x2A29) ──── Read
│   └── PnP ID (0x2A50) ────────────── Read
│
├── Battery Service (0x180F)
│   └── Battery Level (0x2A19) ──────── Read, Notify
│       └── CCCD (0x2902)
│
├── Xiaomi Custom Service (0xFE95)     ◄─── Primary command channel
│   ├── Command Write (0x0001*) ─────── Write, Write Without Response
│   │   └── CCCD (0x2902)
│   ├── Response Notify (0x0002*) ───── Notify
│   │   └── CCCD (0x2902)
│   ├── Auth Characteristic (0x0003*) ─ Read, Write
│   └── Device State (0x0004*) ──────── Read, Notify
│       └── CCCD (0x2902)
│
└── Xiaomi Auth Service (0xFEBE or 0xFEE1) ◄─── Device auth/pairing
    ├── Auth Token (char 1) ─────────── Read, Write
    └── Auth Challenge (char 2) ─────── Write, Notify
        └── CCCD (0x2902)

* Characteristic UUIDs under custom services are short-form placeholders.
  Actual UUIDs follow the pattern: 0000XXXX-0000-1000-8000-00805F9B34FB
  or a Xiaomi-specific 128-bit base.
```

---

## Standard Services

### Generic Access (0x1800)

| Characteristic | UUID | Properties | Data Format | Expected Value |
|---------------|------|------------|-------------|----------------|
| Device Name | `0x2A00` | Read | UTF-8 string | `"REDMI Buds 8 Pro"` |
| Appearance | `0x2A01` | Read | uint16 LE | `0x0941` (Earbud) |
| Preferred Connection Params | `0x2A04` | Read | 8 bytes | min/max interval, latency, timeout |

### Generic Attribute (0x1801)

| Characteristic | UUID | Properties | Data Format | Notes |
|---------------|------|------------|-------------|-------|
| Service Changed | `0x2A05` | Indicate | handle range (4 bytes) | Notifies host when GATT DB changes |

### Device Information (0x180A)

| Characteristic | UUID | Properties | Data Format | Expected Value |
|---------------|------|------------|-------------|----------------|
| Model Number | `0x2A24` | Read | UTF-8 | `"M2417E1"` |
| Serial Number | `0x2A25` | Read | UTF-8 | Device-specific |
| Firmware Revision | `0x2A26` | Read | UTF-8 | `"3.2.2.6"` |
| Hardware Revision | `0x2A27` | Read | UTF-8 | `"1.0.0"` |
| Software Revision | `0x2A28` | Read | UTF-8 | `"3.2.2.6"` |
| Manufacturer Name | `0x2A29` | Read | UTF-8 | `"Xiaomi Inc."` |
| PnP ID | `0x2A50` | Read | 7 bytes | See format below |

**PnP ID Format (7 bytes):**
```
Byte 0:   Vendor ID Source (0x01 = BT SIG, 0x02 = USB)
Byte 1-2: Vendor ID (LE) — Xiaomi: 0x038F (BT SIG) or 0x2717 (USB)
Byte 3-4: Product ID (LE) — Model-specific
Byte 5-6: Product Version (LE)
```

### Battery Service (0x180F)

| Characteristic | UUID | Properties | Data Format | Notes |
|---------------|------|------------|-------------|-------|
| Battery Level | `0x2A19` | Read, Notify | uint8 (0–100) | Combined/primary battery percentage |

**Descriptors:**

| Descriptor | UUID | Data | Notes |
|-----------|------|------|-------|
| CCCD | `0x2902` | `0x0100` = notify on | Enable battery level notifications |

> **Note:** This reports a single combined battery value. Per-earbud (L/R) and case battery are available through the Xiaomi custom protocol (opcode `0x01`).

---

## Xiaomi Custom Services

### Primary Command Service (0xFE95)

This is the main communication channel for all proprietary features (ANC, EQ, gestures, spatial audio, etc.).

| Characteristic | Short UUID | Properties | Purpose | Data Format |
|---------------|-----------|------------|---------|-------------|
| Command Write | `0x0001` | Write, WriteNoResp | Send commands to device | Xiaomi frame (see PROTOCOL_SPEC.md) |
| Response Notify | `0x0002` | Notify | Receive responses/events | Xiaomi frame |
| Auth | `0x0003` | Read, Write | Authentication handshake | Auth token bytes |
| Device State | `0x0004` | Read, Notify | Quick-read device state | Compact state blob |

**Command Write (0x0001):**
- All proprietary commands are written here as Xiaomi protocol frames.
- Frame format: `[FE DC] [Opcode] [SeqNum] [Length LE] [Payload] [CRC16 LE]`
- Use "Write Without Response" for performance; "Write" for commands requiring confirmation.
- Maximum write size depends on negotiated MTU (typically 20 bytes default, 247 with MTU negotiation).

**Response Notify (0x0002):**
- Subscribe to this characteristic to receive command responses and asynchronous events.
- Responses match requests by opcode (response = request | 0x80).
- Events (opcodes 0xE0–0xEF) are unsolicited state change notifications.
- Enable notifications by writing `0x01 0x00` to the CCCD descriptor.

**Auth (0x0003):**
- Used during initial connection to authenticate the host.
- May require reading a challenge token and writing back a computed response.
- Authentication may not be required for all commands (basic reads often work without auth).

**Device State (0x0004):**
- Compact read-only snapshot of current device state.
- Avoids needing to query each feature individually.
- Expected format (to be confirmed):
  ```
  Byte 0:    ANC mode
  Byte 1:    ANC depth
  Byte 2:    Sound mode
  Byte 3:    Spatial audio flags
  Byte 4:    In-ear status (L+R packed)
  Byte 5:    Battery left
  Byte 6:    Battery right
  Byte 7:    Battery case
  Byte 8:    Active codec
  Byte 9-10: Sample rate (LE)
  ```

### Auth/Pairing Service (0xFEBE or 0xFEE1)

Some Xiaomi devices expose a separate authentication service.

| Characteristic | Properties | Purpose |
|---------------|------------|---------|
| Auth Token | Read, Write | Exchange authentication tokens |
| Auth Challenge | Write, Notify | Challenge-response for device binding |

---

## Descriptor Reference

| Descriptor | UUID | Purpose | Values |
|-----------|------|---------|--------|
| Client Characteristic Config (CCCD) | `0x2902` | Enable notifications/indications | `0x0000`=off, `0x0100`=notify, `0x0200`=indicate |
| Characteristic User Description | `0x2901` | Human-readable characteristic name | UTF-8 string |
| Characteristic Extended Properties | `0x2900` | Additional property flags | Bitfield |

---

## Service Discovery Notes

### How to Confirm UUIDs

1. Run the BLE scanner:
   ```bash
   cd tools/
   python ble_scanner.py --address B8:53:84:6B:BD:88 --output ../docs/gatt_dump.txt
   ```

2. Compare discovered UUIDs with this map.

3. Update this document with confirmed UUIDs.

### Alternative UUID Patterns

Xiaomi has used several UUID bases across products:

| Base | Products |
|------|----------|
| `0000XXXX-0000-1000-8000-00805F9B34FB` | Standard SIG base (most common) |
| `0000FE95-0000-1000-8000-00805F9B34FB` | Xiaomi BLE registered service |
| `0000FEBE-0000-1000-8000-00805F9B34FB` | Xiaomi MiService |
| `0000FEE0-0000-1000-8000-00805F9B34FB` | Xiaomi Mi Band / Earbuds |
| `00001234-0000-1000-8000-00805F9B34FB` | Xiaomi proprietary (varies by product line) |

### Expected MTU

| State | MTU | Max Frame Size |
|-------|-----|---------------|
| Default (no negotiation) | 23 bytes | 20 bytes payload |
| After MTU exchange | 247 bytes | 244 bytes payload |
| Recommended | 512 bytes | 509 bytes payload |

> **Tip:** Always request MTU upgrade after connection for efficient frame transfer. Large payloads (gesture config, firmware info) may exceed the default 20-byte limit.
